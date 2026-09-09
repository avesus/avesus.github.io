// SPDX-License-Identifier: MIT
// C++14 loader for the observed E310 Linux 3.14 xdevcfg interface.
// Unlike UHD 3.10 e300_common.cpp, check every write and close, and require
// PCFG_DONE to clear on open and assert BEFORE release re-enables PMU access.
// This is not an AXI drain mechanism or a guarantee of runtime recovery.
#include <algorithm>
#include <cerrno>
#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <sys/stat.h>
#include <thread>
#include <unistd.h>
#include <vector>

namespace {
using Bytes = std::vector<uint8_t>;
std::runtime_error system_error(const char* action) {
    return std::runtime_error(std::string(action) + ": " + std::strerror(errno));
}
struct ImageInfo { std::string part; size_t payload; size_t payload_size; };
ImageInfo inspect(const Bytes& bytes) {
    size_t pos = 0;
    auto number = [&](unsigned width) {
        if (width > bytes.size() - pos) throw std::runtime_error("truncated bit header");
        uint32_t value = 0;
        while (width--) value = (value << 8) | bytes[pos++];
        return value;
    };
    const Bytes magic = {0x0f,0xf0,0x0f,0xf0,0x0f,0xf0,0x0f,0xf0,0};
    if (number(2) != magic.size() || bytes.size() - pos < magic.size() ||
        !std::equal(magic.begin(), magic.end(), bytes.begin() + pos))
        throw std::runtime_error("not a Xilinx .bit container");
    pos += magic.size();
    if (number(2) != 1) throw std::runtime_error("invalid bit header marker");
    std::string part;
    for (char tag = 'a'; tag <= 'd'; ++tag) {
        if (number(1) != static_cast<unsigned>(tag))
            throw std::runtime_error("invalid bit metadata sequence");
        const auto length = number(2);
        if (!length || length > bytes.size() - pos || bytes[pos + length - 1] != 0)
            throw std::runtime_error("invalid bit metadata length/terminator");
        if (tag == 'b') part.assign(bytes.begin() + pos, bytes.begin() + pos + length - 1);
        pos += length;
    }
    if (part != "7z020clg484" && part != "xc7z020clg484" &&
        part != "7z020clg484-3" && part != "xc7z020clg484-3")
        throw std::runtime_error("bitstream is not for the E310 XC7Z020 CLG484");
    if (number(1) != 'e') throw std::runtime_error("missing bit payload tag");
    const auto length = number(4);
    if (!length || length != bytes.size() - pos || length % 4)
        throw std::runtime_error("truncated, extra or unaligned bit payload");
    const Bytes sync = {0xaa,0x99,0x55,0x66};
    auto end = bytes.begin() + pos + std::min<size_t>(length, 1024);
    if (std::search(bytes.begin() + pos, end, sync.begin(), sync.end()) == end)
        throw std::runtime_error("configuration sync word missing near payload start");
    return {part, pos, length};
}
Bytes read_image(const char* path) {
    const int fd = ::open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK);
    if (fd < 0) throw system_error("open source bitstream");
    try {
        struct stat st = {};
        if (fstat(fd, &st) < 0) throw system_error("stat source bitstream");
        if (!S_ISREG(st.st_mode) || st.st_size < 32 || st.st_size > 16 * 1024 * 1024)
            throw std::runtime_error("source must be a regular .bit file, 32 bytes..16 MiB");
        Bytes bytes(static_cast<size_t>(st.st_size));
        size_t offset = 0;
        while (offset < bytes.size()) {
            const auto count = read(fd, bytes.data() + offset, bytes.size() - offset);
            if (count < 0 && errno == EINTR) continue;
            if (count < 0) throw system_error("read source bitstream");
            if (!count) throw std::runtime_error("source bitstream shortened while reading");
            offset += static_cast<size_t>(count);
        }
        uint8_t extra;
        ssize_t tail;
        do { tail = read(fd, &extra, 1); } while (tail < 0 && errno == EINTR);
        if (tail != 0) throw std::runtime_error("source bitstream changed/read failed");
        ::close(fd);
        return bytes;
    } catch (...) { ::close(fd); throw; }
}
int sysfs_flag(const char* leaf) {
    std::ifstream file(std::string("/sys/class/xdevcfg/xdevcfg/device/") + leaf);
    int value = -1;
    std::string extra;
    if (!(file >> value) || (value != 0 && value != 1) || (file >> extra))
        throw std::runtime_error(std::string("invalid/missing xdevcfg flag: ") + leaf);
    return value;
}
struct Device {
    virtual ~Device() = default;
    virtual void open() = 0;
    virtual ssize_t write(const uint8_t*, size_t) = 0;
    virtual int done() = 0;
    virtual void wait() = 0;
    virtual void close() = 0;
};
struct Xdevcfg final : Device {
    int fd = -1;
    ~Xdevcfg() override { if (fd >= 0) ::close(fd); }
    void open() override {
        // Do not silently modify a global driver mode or create a device node.
        if (sysfs_flag("is_partial_bitstream") != 0)
            throw std::runtime_error("full-image loader refuses partial-bitstream mode");
        struct stat st = {};
        if (lstat("/dev/xdevcfg", &st) < 0 || !S_ISCHR(st.st_mode))
            throw std::runtime_error("/dev/xdevcfg is not a character device");
        fd = ::open("/dev/xdevcfg", O_WRONLY | O_CLOEXEC | O_NOFOLLOW);
        if (fd < 0) throw system_error("open xdevcfg");
    }
    ssize_t write(const uint8_t* data, size_t length) override { return ::write(fd, data, length); }
    int done() override { return sysfs_flag("prog_done"); }
    void wait() override { std::this_thread::sleep_for(std::chrono::milliseconds(10)); }
    void close() override {
        const int closing = fd; fd = -1;
        // Linux close must not be retried on EINTR: the descriptor is released.
        if (closing >= 0 && ::close(closing) < 0) throw system_error("close xdevcfg");
    }
};
void program(const Bytes& bytes, Device& device, std::ostream& log) {
    // Full file already in memory; check the container before opening hardware.
    // Callers must additionally verify their expected candidate hash. This
    // format check is not an image allowlist or an RF/runtime qualification.
    const auto info = inspect(bytes);
    log << "E310_CHECKED_LOAD_BEGIN bytes=" << bytes.size() << " payload_bytes="
        << info.payload_size << " part=" << info.part << std::endl;
    device.open();
    try {
        if (device.done() != 0) throw std::runtime_error("PCFG_DONE did not clear on device open");
        size_t sent = 0;
        unsigned interrupted = 0;
        while (sent < bytes.size()) {
            const auto request = std::min<size_t>(16384, bytes.size() - sent);
            const auto result = device.write(bytes.data() + sent, request);
            if (result < 0 && errno == EINTR && ++interrupted <= 16) continue;
            if (result < 0) throw system_error("write xdevcfg");
            if (result == 0 || static_cast<size_t>(result) > request)
                throw std::runtime_error("invalid/zero xdevcfg write result");
            sent += static_cast<size_t>(result);
            interrupted = 0;
        }
        bool configured = false;
        for (unsigned attempt = 0; attempt < 101; ++attempt) {
            if (device.done() == 1) { configured = true; break; }
            if (attempt != 100) device.wait();
        }
        if (!configured) throw std::runtime_error("all bytes accepted but PCFG_DONE did not assert");
        log << "E310_CHECKED_LOAD_TRANSFER_COMPLETE bytes=" << sent
            << " prog_done=1 before_release=true" << std::endl;
    } catch (...) {
        try { device.close(); } catch (...) { log << "E310_CHECKED_LOAD_CLEANUP_CLOSE_FAILED\n"; }
        throw;
    }
    device.close();
    if (device.done() != 1) throw std::runtime_error("PCFG_DONE lost after device release");
    log << "E310_CHECKED_LOAD_PASS bytes=" << bytes.size()
        << " prog_done=1 runtime_verified=false rf_armed_by_loader=false" << std::endl;
}
} // namespace

#ifndef E310_CHECKED_LOADER_TEST
int main(int argc, char** argv) {
    try {
        if (argc != 3 || (std::string(argv[1]) != "--inspect" && std::string(argv[1]) != "--load"))
            throw std::runtime_error("Use --inspect IMAGE.bit or --load IMAGE.bit (requires recovery guardian)");
        auto bytes = read_image(argv[2]);
        const auto info = inspect(bytes);
        if (std::string(argv[1]) == "--inspect") {
            std::cout << "E310_BIT_CONTAINER_PASS bytes=" << bytes.size() << " part="
                      << info.part << " payload_bytes=" << info.payload_size
                      << " hardware_access=false\n";
            return 0;
        }
        const char* guard = std::getenv("GF_E310_RECOVERY_GUARD");
        if (!guard || std::string(guard) != "1")
            throw std::runtime_error("run through gf_e310_recovery_guard; recovery is not yet board-qualified");
        Xdevcfg device;
        program(bytes, device, std::cout);
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "E310_CHECKED_LOADER_FAILED " << error.what() << '\n';
        return 1;
    }
}
#endif

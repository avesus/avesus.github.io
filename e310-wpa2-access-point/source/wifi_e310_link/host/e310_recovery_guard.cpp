// SPDX-License-Identifier: MIT
// Native C++14 recovery guard for the observed E310 Linux 3.14 image.
// Own /dev/watchdog exclusively. Its old device tree requests IRQ-only mode;
// change only the live PS watchdog MODE, never the boot DT, clock or image.
// Register contract: Xilinx linux-xlnx xilinx-v2014.4 cadence_wdt.c and UG585.
#include <cerrno>
#include <chrono>
#include <csignal>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <fstream>
#include <iostream>
#include <linux/watchdog.h>
#include <stdexcept>
#include <string>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <thread>
#include <unistd.h>

namespace {
volatile sig_atomic_t interrupted = 0;
void signal_handler(int) { interrupted = 1; }
void barrier() { __sync_synchronize(); }
std::runtime_error error(const char* what) {
    return std::runtime_error(std::string(what) + ": " + std::strerror(errno));
}
class PsWatchdog {
    int mem_ = -1, fd_ = -1;
    volatile uint32_t* regs_ = nullptr;
public:
    PsWatchdog() {
        // This is a PS peripheral, independent of GP0 and the radio clock.
        std::ifstream compatible("/proc/device-tree/amba@0/ps7-wdt@f8005000/compatible");
        std::string name;
        std::getline(compatible, name, '\0');
        if (name != "xlnx,zynq-wdt-r1p2")
            throw std::runtime_error("Unexpected watchdog device-tree identity");
        mem_ = open("/dev/mem", O_RDWR | O_SYNC | O_CLOEXEC);
        if (mem_ < 0) throw error("open PS /dev/mem");
        void* mapping = mmap(nullptr, 4096, PROT_READ | PROT_WRITE,
                             MAP_SHARED, mem_, 0xf8005000);
        if (mapping == MAP_FAILED) {
            close(mem_);
            throw error("map PS watchdog");
        }
        regs_ = static_cast<volatile uint32_t*>(mapping);
    }
    ~PsWatchdog() {
        // No magic close on an unexpected exception: retain reset fallback.
        if (fd_ >= 0) close(fd_);
        if (regs_) munmap(const_cast<uint32_t*>(regs_), 4096);
        if (mem_ >= 0) close(mem_);
    }
    uint32_t mode() const { barrier(); auto value = regs_[0]; barrier(); return value; }
    void start(int seconds) {
        if (mode() & 1u) throw std::runtime_error("Watchdog already enabled; not taking over");
        fd_ = open("/dev/watchdog", O_WRONLY | O_CLOEXEC);
        if (fd_ < 0) throw error("exclusive watchdog open");
        try {
            watchdog_info info = {};
            if (ioctl(fd_, WDIOC_GETSUPPORT, &info) < 0) throw error("watchdog identity");
            if (std::string(reinterpret_cast<char*>(info.identity)) != "cdns_wdt watchdog")
                throw std::runtime_error("Unexpected Linux watchdog driver");
            if (ioctl(fd_, WDIOC_SETTIMEOUT, &seconds) < 0) throw error("watchdog timeout");
            // The stock driver selected IRQ-only because DT reset=<0>.
            // Disable before changing MODE. Leave CONTROL/clock untouched.
            regs_[0] = 0x00abc000; barrier();
            regs_[0] = 0x00abc033; barrier(); // WDEN + RSTEN, no IRQ, 16-cycle pulse
            ping();
            if ((mode() & 7u) != 3u) throw std::runtime_error("Watchdog reset mode readback failed");
            std::cout << "E310_RECOVERY_WATCHDOG_ARMED timeout=" << seconds
                      << " mode=0x" << std::hex << mode() << std::dec
                      << " peripheral=PS reset_output=true" << std::endl;
        } catch (...) {
            stop();
            throw;
        }
    }
    void ping() {
        if (ioctl(fd_, WDIOC_KEEPALIVE, nullptr) < 0) throw error("watchdog keepalive");
    }
    void stop() {
        if (fd_ < 0) return;
        int options = WDIOS_DISABLECARD;
        if (ioctl(fd_, WDIOC_SETOPTIONS, &options) < 0) throw error("watchdog disable");
        if (write(fd_, "V", 1) != 1) throw error("watchdog magic close");
        close(fd_); fd_ = -1;
        if (mode() & 1u) throw std::runtime_error("Watchdog did not disable");
        std::cout << "E310_RECOVERY_WATCHDOG_STOPPED enabled=false" << std::endl;
    }
};

int expire_and_wait(PsWatchdog& watchdog, int timeout) {
    std::cout << "E310_WATCHDOG_EXPIRY_REQUESTED reset_is_hardware_not_reboot_command=true"
              << std::endl;
    // fsync is meaningful for retained regular-file evidence, not a pipe or
    // UART. In particular, piping this command must not cancel the test.
    struct stat output_status = {};
    if (fstat(STDOUT_FILENO, &output_status) < 0) throw error("inspect evidence output");
    if (S_ISREG(output_status.st_mode) && fsync(STDOUT_FILENO) < 0)
        throw error("persist watchdog expiry evidence");
    // No ioctl, ping, reboot syscall or shell reboot occurs in this interval.
    const auto started = std::chrono::steady_clock::now();
    const auto end = started + std::chrono::seconds(timeout + 15);
    auto report_at = started + std::chrono::seconds(1);
    while (std::chrono::steady_clock::now() < end) {
        const auto now = std::chrono::steady_clock::now();
        if (now >= report_at) {
            std::cout << "E310_WATCHDOG_EXPIRY_WAIT elapsed_ms="
                      << std::chrono::duration_cast<std::chrono::milliseconds>(now - started).count()
                      << " keepalive_sent=false" << std::endl;
            report_at = now + std::chrono::seconds(1);
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    watchdog.stop();
    std::cerr << "E310_WATCHDOG_RESET_FAILED system_still_running=true\n";
    return 1;
}
}

int main(int argc, char** argv) {
    try {
        if (argc < 2) throw std::runtime_error("Use --probe, --self-test, --reset-test, --guard, or --guard-reset-test DEADLINE -- COMMAND...");
        const std::string mode(argv[1]);
        if (mode != "--probe" && mode != "--self-test" && mode != "--reset-test" && mode != "--guard" && mode != "--guard-reset-test" && mode != "--service")
            throw std::runtime_error("Unknown recovery mode");
        int deadline = 0;
        const bool continuous = mode == "--service";
        std::string progress_path;
        if (continuous) {
            if (argc < 5 || std::string(argv[3]) != "--")
                throw std::runtime_error("Use --service NEW_PROGRESS_LOG -- COMMAND ARG...");
            progress_path = argv[2];
            struct stat previous = {};
            if (lstat(progress_path.c_str(), &previous) == 0 || errno != ENOENT)
                throw std::runtime_error("Continuous guard requires a new, absent progress log");
        } else if (mode == "--guard" || mode == "--guard-reset-test") {
            if (argc < 5 || std::string(argv[3]) != "--")
                throw std::runtime_error("Use --guard DEADLINE -- COMMAND ARG...");
            deadline = std::stoi(argv[2]);
            if (deadline < 5 || deadline > 600) throw std::runtime_error("Diagnostic deadline must be 5..600 seconds");
        } else if (argc != 2) throw std::runtime_error("Unexpected recovery arguments");
        PsWatchdog watchdog;
        std::cout << "E310_RECOVERY_PROBE mode=0x" << std::hex << watchdog.mode()
                  << std::dec << " watchdog_opened=false rf_arm_performed=false rf_state_not_inspected=true" << std::endl;
        if (mode == "--probe") return 0;
        std::signal(SIGINT, signal_handler);
        std::signal(SIGTERM, signal_handler);
        // Flush project evidence before enabling a reset fallback, not after
        // a potential bus stall. No board boot files are modified here.
        sync();
        const int timeout = 10;
        watchdog.start(timeout);
        if (mode == "--reset-test") return expire_and_wait(watchdog, timeout);
        if (mode == "--self-test") {
            for (int i = 0; i < 3 && !interrupted; ++i) { sleep(1); watchdog.ping(); }
            watchdog.stop();
            std::cout << "E310_WATCHDOG_START_PING_STOP_PASS reset_tested=false" << std::endl;
            return 0;
        }
        const pid_t child = fork();
        if (child < 0) { watchdog.stop(); throw error("fork guarded command"); }
        if (child == 0) {
            setpgid(0, 0);
            setenv("GF_E310_RECOVERY_GUARD", "1", 1);
            execvp(argv[4], argv + 4);
            _exit(127);
        }
        setpgid(child, child);
        const auto started = std::chrono::steady_clock::now();
        auto next_report = started;
        auto progress_deadline = started + std::chrono::seconds(90);
        off_t progress_size = 0;
        std::cout << "E310_GUARD_CHILD_STARTED pid=" << child
                  << " deadline_seconds=" << deadline
                  << " continuous=" << (continuous ? "true" : "false") << std::endl;
        int status = 0;
        while (!interrupted && (continuous || std::chrono::steady_clock::now() - started < std::chrono::seconds(deadline))) {
            const pid_t waited = waitpid(child, &status, WNOHANG);
            if (waited == child) {
                // Flush before reading another hardware register. The last
                // custom-image failure stopped between child cleanup and the
                // old combined mode-read/expiry line; do not hide that edge.
                std::cout << "E310_GUARD_CHILD_EXIT wait_status=" << status << std::endl;
                if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
                    if (mode == "--guard-reset-test") {
                        std::cout << "E310_CUSTOM_IMAGE_MODE_READ_BEGIN" << std::endl;
                        std::cout << "E310_CUSTOM_IMAGE_EXPIRY_TEST mode=0x"
                                  << std::hex << watchdog.mode() << std::dec << std::endl;
                        return expire_and_wait(watchdog, timeout);
                    }
                    watchdog.stop();
                    std::cout << "E310_GUARDED_COMMAND_PASS" << std::endl;
                    return 0;
                }
                break;
            }
            if (waited < 0 && errno != EINTR) break;
            const auto now = std::chrono::steady_clock::now();
            if (continuous) {
                // AP emits a beacon log record only after its real MMIO TX
                // completes. Require that file to keep advancing; merely
                // keeping this watchdog process alive is not service health.
                struct stat progress = {};
                if (lstat(progress_path.c_str(), &progress) == 0) {
                    if (!S_ISREG(progress.st_mode) || progress.st_size < progress_size) break;
                    if (progress.st_size > progress_size) {
                        progress_size = progress.st_size;
                        progress_deadline = now + std::chrono::seconds(10);
                    }
                } else if (errno != ENOENT) break;
                if (now >= progress_deadline) {
                    std::cout << "E310_SERVICE_PROGRESS_TIMEOUT last_bytes=" << progress_size << std::endl;
                    break;
                }
            }
            const bool report = now >= next_report;
            if (report)
                std::cout << "E310_GUARD_KEEPALIVE_BEGIN elapsed_ms="
                          << std::chrono::duration_cast<std::chrono::milliseconds>(now - started).count()
                          << std::endl;
            watchdog.ping();
            if (report) {
                std::cout << "E310_GUARD_KEEPALIVE_OK" << std::endl;
                next_report = now + std::chrono::seconds(5);
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(250));
        }
        // Give the child its normal RF-off/stock-restore cleanup opportunity.
        kill(-child, SIGTERM);
        std::cout << "E310_GUARDED_COMMAND_FAULT recovery=hardware_watchdog" << std::endl;
        return expire_and_wait(watchdog, timeout);
    } catch (const std::exception& ex) {
        std::cerr << "fatal: " << ex.what() << '\n';
        return 1;
    }
}

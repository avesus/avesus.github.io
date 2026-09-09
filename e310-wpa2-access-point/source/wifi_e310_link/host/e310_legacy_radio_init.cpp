// SPDX-License-Identifier: GPL-3.0-or-later
// Post-PL-load AD9361 initialization on the 2017 E310 Linux image.
// Uses the matching upstream calibration driver, not a stale register replay.
// The custom RF gate must remain killed throughout; this sends no TX samples.
#include <cstdint>
#include "ad9361_device.h"
#include <boost/make_shared.hpp>
#include <cmath>
#include <cerrno>
#include <cstring>
#include <fcntl.h>
#include <iostream>
#include <linux/spi/spidev.h>
#include <stdexcept>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>

namespace {
struct Fd {
    int value;
    explicit Fd(const char* path) : value(open(path, O_RDWR | O_SYNC)) {
        if (value < 0) throw std::runtime_error(std::string(path) + ": " + strerror(errno));
    }
    ~Fd() { close(value); }
    Fd(const Fd&) = delete;
    Fd& operator=(const Fd&) = delete;
};

class Spi final : public uhd::usrp::ad9361_io {
    Fd fd_{"/dev/spidev0.1"};
    uint8_t transfer(uint32_t reg, uint8_t value, bool write) {
        if (reg > 0x3ff) throw std::runtime_error("Invalid AD9361 register");
        uint8_t tx[3] = {uint8_t((reg >> 8) | (write ? 0x80 : 0)), uint8_t(reg), value};
        uint8_t rx[3] = {};
        spi_ioc_transfer tr = {};
        tr.tx_buf = reinterpret_cast<uintptr_t>(tx);
        tr.rx_buf = reinterpret_cast<uintptr_t>(rx);
        tr.len = 3;
        tr.speed_hz = 2000000;
        tr.bits_per_word = 8;
        tr.tx_nbits = 1;
        tr.rx_nbits = 1;
        if (ioctl(fd_.value, SPI_IOC_MESSAGE(1), &tr) != 3)
            throw std::runtime_error("AD9361 SPI transfer failed");
        return rx[2];
    }
public:
    Spi() {
        uint8_t mode = SPI_CPHA, bits = 8;
        uint32_t speed = 2000000;
        if (ioctl(fd_.value, SPI_IOC_WR_MODE, &mode) < 0 ||
            ioctl(fd_.value, SPI_IOC_WR_BITS_PER_WORD, &bits) < 0 ||
            ioctl(fd_.value, SPI_IOC_WR_MAX_SPEED_HZ, &speed) < 0)
            throw std::runtime_error("AD9361 SPI setup failed");
    }
    uint8_t peek8(uint32_t reg) override { return transfer(reg, 0, false); }
    void poke8(uint32_t reg, uint8_t value) override { transfer(reg, value, true); }
};

class Board final : public uhd::usrp::ad9361_params {
public:
    uhd::usrp::digital_interface_delays_t get_digital_interface_timing() override {
        // Match the physical I/O timing constraints of the custom image.
        return {0, 15, 0, 15};
    }
    uhd::usrp::digital_interface_mode_t get_digital_interface_mode() override {
        return uhd::usrp::AD9361_DDR_FDD_LVCMOS;
    }
    uhd::usrp::clocking_mode_t get_clocking_mode() override {
        return uhd::usrp::AD9361_XTAL_N_CLK_PATH;
    }
    double get_band_edge(uhd::usrp::frequency_band_t band) override {
        switch (band) {
        case uhd::usrp::AD9361_RX_BAND0: return 1.2e9;
        case uhd::usrp::AD9361_RX_BAND1: return 2.6e9;
        case uhd::usrp::AD9361_TX_BAND0: return 2.94e9;
        default: return 0;
        }
    }
};

struct KilledMapping {
    Fd mem{"/dev/mem"};
    volatile uint32_t* regs;
    KilledMapping() {
        void* p = mmap(nullptr, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, mem.value, 0x40010000);
        if (p == MAP_FAILED) throw std::runtime_error("Custom MMIO mapping failed");
        regs = static_cast<volatile uint32_t*>(p);
        const auto version = regs[0x22c / 4];
        // v1.2/v1.3 add observation-only registers; the RF kill/control ABI is
        // unchanged. Keep the list explicit instead of accepting any image.
        if (regs[0x200 / 4] != 0x47464531 ||
            (version != 0x00010001 && version != 0x00010002 && version != 0x00010003) ||
            (regs[0x210 / 4] & 3) != 2) {
            munmap(p, 4096);
            throw std::runtime_error("Expected recognized, killed custom FPGA before radio setup");
        }
    }
    ~KilledMapping() {
        regs[0x204 / 4] = 2;
        __sync_synchronize();
        munmap(const_cast<uint32_t*>(regs), 4096);
    }
};
}

int main(int argc, char** argv) {
    try {
        if (argc < 2 || std::string(argv[1]) != "--prepare")
            throw std::runtime_error("Use --prepare [--channel N] [--tx-gain DB] [--rx-gain DB]");
        int channel = 6;
        double tx_gain = 0, rx_gain = 20;
        for (int index = 2; index < argc; index += 2) {
            if (index + 1 >= argc) throw std::runtime_error("Missing radio option value");
            const std::string option(argv[index]);
            if (option == "--channel") channel = std::stoi(argv[index + 1]);
            else if (option == "--tx-gain") tx_gain = std::stod(argv[index + 1]);
            else if (option == "--rx-gain") rx_gain = std::stod(argv[index + 1]);
            else throw std::runtime_error("Unknown radio setup option");
        }
        if (channel < 1 || channel > 11 || !std::isfinite(tx_gain) ||
            !std::isfinite(rx_gain) || tx_gain < 0 || tx_gain > 89.75 ||
            rx_gain < 0 || rx_gain > 76)
            throw std::runtime_error("Radio option outside supported range");
        const double center = (2407 + 5 * channel) * 1e6;
        KilledMapping gate;
        auto spi = boost::make_shared<Spi>();
        auto board = boost::make_shared<Board>();
        using Device = uhd::usrp::ad9361_device_t;
        Device radio(board, spi);
        radio.initialize();
        const double rate = radio.set_clock_rate(20e6);
        radio.set_active_chains(true, true, true, true);
        const double rx_hz = radio.tune(Device::RX, center);
        const double tx_hz = radio.tune(Device::TX, center);
        for (auto chain : {Device::CHAIN_1, Device::CHAIN_2}) {
            radio.set_agc(chain, false);
            radio.set_gain(Device::RX, chain, rx_gain);
            radio.set_gain(Device::TX, chain, tx_gain);
        }
        radio.set_bw_filter(Device::RX, 20e6);
        radio.set_bw_filter(Device::TX, 20e6);
        radio.data_port_loopback(false);
        radio.digital_test_tone(false);
        if (std::abs(rate - 20e6) > 1 || std::abs(rx_hz - center) > 100 ||
            std::abs(tx_hz - center) > 100 || spi->peek8(0x006) != 0x0f ||
            spi->peek8(0x007) != 0x0f || (spi->peek8(0x247) & 2) == 0 ||
            (spi->peek8(0x287) & 2) == 0)
            throw std::runtime_error("Radio setup readback failed");
        for (unsigned address : {0x073u, 0x075u}) {
            const unsigned attenuation = spi->peek8(address) | ((spi->peek8(address + 1) & 1) << 8);
            if (std::abs((89.75 - attenuation * 0.25) - tx_gain) > 0.251)
                throw std::runtime_error("TX attenuation readback failed");
        }
        usleep(10000);
        const auto status = gate.regs[0x210 / 4];
        std::cout << "E310_POST_LOAD_RADIO rate=" << rate << " rx_hz=" << rx_hz
                  << " tx_hz=" << tx_hz << " tx_gain_db=" << tx_gain << " rx_gain_db=" << rx_gain
                  << " status=0x" << std::hex << status << std::dec
                  << " radio_ready=" << ((status >> 13) & 1)
                  << " rf_armed=false tx_samples=0 calibrated_power=false" << std::endl;
        if ((status & 0x2003) != 0x2002)
            throw std::runtime_error("Custom FPGA radio-ready/killed gate failed");
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "fatal: " << error.what() << std::endl;
        return 1;
    }
}

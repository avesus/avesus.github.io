// One-shot AD9361 setup while the stock E310 image is still active.
// This process never starts RX and never submits a TX sample.  no_reload_fpga
// keeps MPM from replacing the configured full image with its idle image when
// the session closes; the open PL shell is loaded only after this tool exits.

#include <uhd/types/device_addr.hpp>
#include <uhd/types/tune_request.hpp>
#include <uhd/usrp/multi_usrp.hpp>
#include <uhd/version.hpp>

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>
#include <chrono>
#include <thread>
#include <dirent.h>
#include <unistd.h>

namespace {

constexpr double kSampleRate = 20'000'000.0;
constexpr double kBandwidth = 20'000'000.0;

struct Options {
    bool prepare = false;
    bool self_test = false;
    std::string uhd_args =
        "type=e3xx,master_clock_rate=20e6,no_reload_fpga=1";
    int channel = 6;
    double rx_gain_db = 30.0;
    double tx_gain_db = 0.0;
    std::string rx_antenna = "RX2";
    std::string tx_antenna = "TX/RX";
    int legacy_keep_seconds = 0;
};

std::string normalized_uhd_args(const std::string& text) {
    uhd::device_addr_t args(text);
    if (args.has_key("no_reload_fpga")) {
        auto value = args["no_reload_fpga"];
        std::transform(value.begin(), value.end(), value.begin(),
                       [](unsigned char character) {
                           return static_cast<char>(std::tolower(character));
                       });
        if (!value.empty() && value != "1" && value != "true" &&
            value != "yes" && value != "t") {
            throw std::runtime_error(
                "no_reload_fpga must be true; refusing a teardown-capable session");
        }
    }
    // Rewrite even an accepted spelling to one unambiguous MPM value.
    args["no_reload_fpga"] = "1";
    return args.to_string();
}

Options parse_options(int argc, char** argv) {
    Options options;
    auto next = [&](int& index, const char* name) -> std::string {
        if (++index >= argc)
            throw std::runtime_error(std::string("missing value for ") + name);
        return argv[index];
    };
    for (int index = 1; index < argc; ++index) {
        const std::string argument = argv[index];
        if (argument == "--prepare") options.prepare = true;
        else if (argument == "--self-test") options.self_test = true;
        else if (argument == "--uhd-args")
            options.uhd_args = next(index, "--uhd-args");
        else if (argument == "--channel")
            options.channel = std::stoi(next(index, "--channel"));
        else if (argument == "--rx-gain")
            options.rx_gain_db = std::stod(next(index, "--rx-gain"));
        else if (argument == "--tx-gain")
            options.tx_gain_db = std::stod(next(index, "--tx-gain"));
        else if (argument == "--rx-antenna")
            options.rx_antenna = next(index, "--rx-antenna");
        else if (argument == "--tx-antenna")
            options.tx_antenna = next(index, "--tx-antenna");
        else if (argument == "--legacy-keep-seconds")
            options.legacy_keep_seconds = std::stoi(next(index, "--legacy-keep-seconds"));
        else if (argument == "--help" || argument == "-h") {
            std::cout
                << "gf_e310_rf_preset --self-test\n"
                   "gf_e310_rf_preset --prepare [--channel 1..11] "
                   "[--rx-gain DB] [--tx-gain DB] "
                   "[--rx-antenna NAME] [--tx-antenna NAME] "
                   "[--uhd-args ARGS]\n"
                   "--legacy-keep-seconds N retains the legacy AXI descriptor after UHD teardown; -1 holds until terminated.\n"
                   "Configures the stock AD9361 for the later open shell; "
                   "sends zero samples.\n";
            std::exit(0);
        } else {
            throw std::runtime_error("unknown argument: " + argument);
        }
    }
    if (options.prepare == options.self_test)
        throw std::runtime_error(
            "choose exactly one of --prepare or --self-test");
    if (options.channel < 1 || options.channel > 11)
        throw std::runtime_error("--channel must be in 1..11");
    if (!std::isfinite(options.rx_gain_db) || !std::isfinite(options.tx_gain_db))
        throw std::runtime_error("RF gains must be finite");
    if (options.legacy_keep_seconds < -1 || options.legacy_keep_seconds > 300)
        throw std::runtime_error("legacy keep duration must be -1 or 0..300 seconds");
    options.uhd_args = normalized_uhd_args(options.uhd_args);
    return options;
}

bool contains(const std::vector<std::string>& values,
              const std::string& requested) {
    return std::find(values.begin(), values.end(), requested) != values.end();
}

void run_self_test() {
    for (const auto* value : {
             "type=e3xx",
             "type=e3xx,no_reload_fpga=1",
             "type=e3xx,no_reload_fpga=TRUE",
             "type=e3xx,no_reload_fpga=yes",
             "type=e3xx,no_reload_fpga="}) {
        const uhd::device_addr_t normalized(normalized_uhd_args(value));
        if (!normalized.has_key("no_reload_fpga") ||
            normalized["no_reload_fpga"] != "1") {
            throw std::runtime_error("safe no_reload_fpga normalization failed");
        }
    }
    for (const auto* value : {
             "type=e3xx,no_reload_fpga=0",
             "type=e3xx,no_reload_fpga=false",
             "type=e3xx,no_reload_fpga=no"}) {
        bool rejected = false;
        try {
            (void)normalized_uhd_args(value);
        } catch (const std::runtime_error&) {
            rejected = true;
        }
        if (!rejected)
            throw std::runtime_error("unsafe no_reload_fpga value was accepted");
    }
    std::cout << "E310_RF_PRESET_SELFTEST_PASS tx_samples=0 "
                 "no_reload_fpga=forced_true hardware_access=false\n";
}

}  // namespace

int main(int argc, char** argv) {
    try {
        const auto options = parse_options(argc, argv);
        if (options.self_test) {
            run_self_test();
            return 0;
        }
        const auto center_hz =
            static_cast<double>(2407 + 5 * options.channel) * 1e6;
        auto usrp = uhd::usrp::multi_usrp::make(options.uhd_args);
        if (std::abs(usrp->get_master_clock_rate() - kSampleRate) > 1.0)
            throw std::runtime_error("E310 did not enter exact 20 MHz clock mode");
        if (usrp->get_tx_num_channels() < 2 ||
            usrp->get_rx_num_channels() < 2) {
            throw std::runtime_error("E310 does not expose two RF channels");
        }

        for (std::size_t channel = 0; channel < 2; ++channel) {
            const auto tx_range = usrp->get_tx_gain_range(channel);
            const auto rx_range = usrp->get_rx_gain_range(channel);
            if (options.tx_gain_db < tx_range.start() ||
                options.tx_gain_db > tx_range.stop() ||
                options.rx_gain_db < rx_range.start() ||
                options.rx_gain_db > rx_range.stop()) {
                throw std::runtime_error("requested RF gain is outside the device range");
            }
            if (!contains(usrp->get_rx_antennas(channel), options.rx_antenna))
                throw std::runtime_error("requested RX antenna is unavailable");
            if (!contains(usrp->get_tx_antennas(channel), options.tx_antenna))
                throw std::runtime_error("requested TX antenna is unavailable");
            usrp->set_rx_rate(kSampleRate, channel);
            usrp->set_tx_rate(kSampleRate, channel);
            usrp->set_rx_bandwidth(kBandwidth, channel);
            usrp->set_tx_bandwidth(kBandwidth, channel);
            usrp->set_rx_gain(options.rx_gain_db, channel);
            usrp->set_tx_gain(options.tx_gain_db, channel);
            const auto actual_tx_gain = usrp->get_tx_gain(channel);
            const auto actual_rx_gain = usrp->get_rx_gain(channel);
            if (std::abs(actual_tx_gain - options.tx_gain_db) > 0.126 ||
                std::abs(actual_rx_gain - options.rx_gain_db) > 0.51) {
                throw std::runtime_error("RF gain readback does not match the requested setting");
            }
            std::cout << "E310_GAIN_READBACK logical_channel=" << channel
                      << " tx_gain_db=" << actual_tx_gain
                      << " rx_gain_db=" << actual_rx_gain
                      << " tx_gain_min_db=" << tx_range.start()
                      << " tx_gain_max_db=" << tx_range.stop()
                      << " calibrated_output_power=false\n";
            usrp->set_rx_antenna(options.rx_antenna, channel);
            usrp->set_tx_antenna(options.tx_antenna, channel);
            usrp->set_rx_freq(uhd::tune_request_t(center_hz), channel);
            usrp->set_tx_freq(uhd::tune_request_t(center_hz), channel);
        }

        // Connecting both directions and both channels makes UHD request the
        // AD9361 2R2T timing mode. No stream command and no send() follows.
        uhd::stream_args_t stream_args("sc16", "sc16");
        stream_args.channels = {0, 1};
        auto tx_stream = usrp->get_tx_stream(stream_args);
        auto rx_stream = usrp->get_rx_stream(stream_args);
        if (!tx_stream || !rx_stream || tx_stream->get_num_channels() != 2 ||
            rx_stream->get_num_channels() != 2) {
            throw std::runtime_error("E310 could not establish 2R2T topology");
        }
        for (std::size_t channel = 0; channel < 2; ++channel) {
            if (std::abs(usrp->get_rx_rate(channel) - kSampleRate) > 1.0 ||
                std::abs(usrp->get_tx_rate(channel) - kSampleRate) > 1.0) {
                throw std::runtime_error("E310 rate readback is not 20 MS/s");
            }
        }

        std::cout << "E310_RF_PRESET_PASS channel=" << options.channel
                  << " center_hz=" << static_cast<unsigned long long>(center_hz)
                  << " channels=2 sample_rate=20000000 tx_samples=0"
                     " no_reload_fpga=true uhd_version="
                  << uhd::get_version_string() << '\n';
        if (options.legacy_keep_seconds != 0) {
            // The legacy driver is exclusive-open. dup() retains that same
            // open file description without reopening or retaining UHD tasks.
            DIR* descriptors = opendir("/proc/self/fd");
            if (!descriptors) throw std::runtime_error("cannot inspect own AXI descriptor");
            int keep_fd = -1;
            while (const dirent* entry = readdir(descriptors)) {
                const std::string path = std::string("/proc/self/fd/") + entry->d_name;
                char target[256] = {};
                const auto count = readlink(path.c_str(), target, sizeof(target) - 1);
                if (count > 0 && std::string(target, static_cast<std::size_t>(count)) == "/dev/axi_fpga") {
                    keep_fd = dup(std::stoi(entry->d_name));
                    break;
                }
            }
            closedir(descriptors);
            if (keep_fd < 0) throw std::runtime_error("legacy AXI descriptor not found");
            rx_stream.reset();
            tx_stream.reset();
            usrp.reset();
            std::cout << "E310_LEGACY_HANDOFF_READY uhd_destroyed=true kept_axi_fd="
                      << keep_fd << " seconds=" << options.legacy_keep_seconds << std::endl;
            if (options.legacy_keep_seconds == -1) {
                // No UHD task remains. Keep only the exclusive-open descriptor;
                // the supervising launcher restores stock before terminating us.
                for (;;) pause();
            }
            std::this_thread::sleep_for(std::chrono::seconds(options.legacy_keep_seconds));
            close(keep_fd);
            std::cout << "E310_LEGACY_HANDOFF_CLOSED" << std::endl;
        }
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "fatal: " << error.what() << '\n';
        return 1;
    }
}

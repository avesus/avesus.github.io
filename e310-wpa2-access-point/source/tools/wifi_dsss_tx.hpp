#pragma once

// Portable long-preamble IEEE 802.11 1 Mb/s DSSS waveform formatter.
// This is host-side packet formatting only: it consumes a complete PSDU,
// including FCS, and returns interleaved signed IQ16 at the requested rate.

#include <algorithm>
#include <array>
#include <cmath>
#include <complex>
#include <cstddef>
#include <cstdint>
#include <numeric>
#include <stdexcept>
#include <vector>

namespace gf::dsss_tx {

using Complex = std::complex<double>;

inline constexpr double kPi = 3.1415926535897932384626433832795;
inline constexpr std::int64_t kDefaultSampleRate = 20'000'000;
inline constexpr double kChipRate = 11'000'000.0;
inline constexpr std::array<int, 11> kBarker = {
    1, -1, 1, 1, -1, 1, 1, 1, -1, -1, -1};
inline constexpr std::array<std::uint8_t, 16> kLongSfd = {
    0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1};

inline void append_le16(std::vector<std::uint8_t>& output,
                        std::uint16_t value) {
    output.push_back(static_cast<std::uint8_t>(value));
    output.push_back(static_cast<std::uint8_t>(value >> 8));
}

inline std::uint16_t crc16_plcp(const std::uint8_t* data,
                               std::size_t size) {
    std::uint16_t crc = 0xffffu;
    for (std::size_t index = 0; index < size; ++index) {
        for (int bit = 0; bit < 8; ++bit) {
            const bool mix = ((crc ^ (data[index] >> bit)) & 1u) != 0;
            crc >>= 1;
            if (mix) crc ^= 0x8408u;
        }
    }
    return static_cast<std::uint16_t>(crc ^ 0xffffu);
}

inline std::vector<std::uint8_t> lsb_bits(
    const std::vector<std::uint8_t>& bytes) {
    std::vector<std::uint8_t> bits;
    bits.reserve(bytes.size() * 8);
    for (const auto value : bytes) {
        for (int bit = 0; bit < 8; ++bit)
            bits.push_back(static_cast<std::uint8_t>((value >> bit) & 1u));
    }
    return bits;
}

inline std::vector<std::uint8_t> scramble(
    const std::vector<std::uint8_t>& bits, std::uint8_t state = 0x5d) {
    std::vector<std::uint8_t> output;
    output.reserve(bits.size());
    for (const auto input : bits) {
        const auto transmitted = static_cast<std::uint8_t>(
            (input & 1u) ^ ((state >> 3) & 1u) ^ ((state >> 6) & 1u));
        output.push_back(transmitted);
        state = static_cast<std::uint8_t>(
            ((state << 1) | transmitted) & 0x7fu);
    }
    return output;
}

inline std::vector<Complex> make_long_1mbps_chips(
    const std::vector<std::uint8_t>& psdu) {
    if (psdu.empty() || psdu.size() > 4095)
        throw std::runtime_error(
            "DSSS PSDU length is outside 1..4095 bytes");

    const auto duration_us = static_cast<std::uint16_t>(psdu.size() * 8);
    std::vector<std::uint8_t> header = {
        0x0a, 0x00, static_cast<std::uint8_t>(duration_us),
        static_cast<std::uint8_t>(duration_us >> 8)};
    append_le16(header, crc16_plcp(header.data(), header.size()));

    std::vector<std::uint8_t> plain;
    plain.insert(plain.end(), 128, 1);
    plain.insert(plain.end(), kLongSfd.begin(), kLongSfd.end());
    const auto header_bits = lsb_bits(header);
    plain.insert(plain.end(), header_bits.begin(), header_bits.end());
    const auto payload_bits = lsb_bits(psdu);
    plain.insert(plain.end(), payload_bits.begin(), payload_bits.end());

    const auto scrambled = scramble(plain);
    std::vector<Complex> chips;
    chips.reserve(scrambled.size() * kBarker.size());
    Complex carrier{1.0, 0.0};
    for (const auto bit : scrambled) {
        if (bit != 0) carrier = -carrier;
        for (const int chip : kBarker)
            chips.push_back(carrier * static_cast<double>(chip));
    }
    return chips;
}

inline std::vector<Complex> sinc_resample(
    const std::vector<Complex>& input, double input_rate,
    double output_rate, int half_taps = 24) {
    if (input_rate <= 0.0 || output_rate <= 0.0 || half_taps < 1)
        throw std::runtime_error("invalid DSSS resampler configuration");

    const auto input_hz = static_cast<std::int64_t>(std::llround(input_rate));
    const auto output_hz = static_cast<std::int64_t>(std::llround(output_rate));
    const bool integral_rates = input_hz > 0 && output_hz > 0 &&
        std::abs(input_rate - static_cast<double>(input_hz)) < 0.5 &&
        std::abs(output_rate - static_cast<double>(output_hz)) < 0.5;
    const auto divisor = integral_rates ? std::gcd(input_hz, output_hz) : 1;
    const auto phase_count = integral_rates ? output_hz / divisor : 0;

    if (integral_rates && phase_count > 0 && phase_count <= 1024) {
        struct RationalCache {
            std::int64_t input_hz = 0;
            std::int64_t output_hz = 0;
            int half_taps = 0;
            std::int64_t phase_count = 0;
            std::int64_t advance = 0;
            std::vector<double> weights;
        };
        static thread_local RationalCache cache;
        const auto tap_count = static_cast<std::size_t>(half_taps * 2);
        const int first_tap = -half_taps + 1;
        if (cache.input_hz != input_hz ||
            cache.output_hz != output_hz ||
            cache.half_taps != half_taps) {
            cache.input_hz = input_hz;
            cache.output_hz = output_hz;
            cache.half_taps = half_taps;
            cache.phase_count = phase_count;
            cache.advance = input_hz / divisor;
            cache.weights.assign(
                static_cast<std::size_t>(phase_count) * tap_count, 0.0);
            const double cutoff =
                0.94 * std::min(1.0, output_rate / input_rate);
            for (std::int64_t phase = 0; phase < phase_count; ++phase) {
                const double fraction = static_cast<double>(phase) /
                                        static_cast<double>(phase_count);
                for (std::size_t index = 0; index < tap_count; ++index) {
                    const int tap = first_tap + static_cast<int>(index);
                    const double distance =
                        fraction - static_cast<double>(tap);
                    const double window_position = distance / half_taps;
                    if (std::abs(window_position) >= 1.0) continue;
                    const double x = cutoff * distance;
                    const double sinc = std::abs(x) < 1e-12
                        ? 1.0 : std::sin(kPi * x) / (kPi * x);
                    const double window =
                        0.42 + 0.5 * std::cos(kPi * window_position) +
                        0.08 * std::cos(2.0 * kPi * window_position);
                    cache.weights[
                        static_cast<std::size_t>(phase) * tap_count + index] =
                        cutoff * sinc * window;
                }
            }
        }

        const auto output_size = static_cast<std::size_t>(
            static_cast<unsigned long long>(input.size()) *
            static_cast<unsigned long long>(output_hz) /
            static_cast<unsigned long long>(input_hz));
        std::vector<Complex> output(output_size);
        std::uint64_t position_numerator = 0;
        for (std::size_t out = 0; out < output.size(); ++out) {
            const auto center = static_cast<std::ptrdiff_t>(
                position_numerator /
                static_cast<std::uint64_t>(cache.phase_count));
            const auto phase = static_cast<std::size_t>(
                position_numerator %
                static_cast<std::uint64_t>(cache.phase_count));
            position_numerator += static_cast<std::uint64_t>(cache.advance);
            Complex sum{};
            double weight_sum = 0.0;
            for (std::size_t index = 0; index < tap_count; ++index) {
                const auto source = center + first_tap +
                                    static_cast<std::ptrdiff_t>(index);
                if (source < 0 ||
                    source >= static_cast<std::ptrdiff_t>(input.size()))
                    continue;
                const double weight =
                    cache.weights[phase * tap_count + index];
                sum += input[static_cast<std::size_t>(source)] * weight;
                weight_sum += weight;
            }
            output[out] = weight_sum != 0.0 ? sum / weight_sum : Complex{};
        }
        return output;
    }

    const auto output_size = static_cast<std::size_t>(
        std::floor(input.size() * output_rate / input_rate));
    std::vector<Complex> output(output_size);
    const double cutoff = 0.94 * std::min(1.0, output_rate / input_rate);
    for (std::size_t out = 0; out < output.size(); ++out) {
        const double position = out * input_rate / output_rate;
        const auto center =
            static_cast<std::ptrdiff_t>(std::floor(position));
        Complex sum{};
        double weight_sum = 0.0;
        for (int tap = -half_taps + 1; tap <= half_taps; ++tap) {
            const auto source = center + tap;
            if (source < 0 ||
                source >= static_cast<std::ptrdiff_t>(input.size()))
                continue;
            const double distance = position - static_cast<double>(source);
            const double x = cutoff * distance;
            const double sinc = std::abs(x) < 1e-12
                ? 1.0 : std::sin(kPi * x) / (kPi * x);
            const double window_position = distance / half_taps;
            if (std::abs(window_position) >= 1.0) continue;
            const double window =
                0.42 + 0.5 * std::cos(kPi * window_position) +
                0.08 * std::cos(2.0 * kPi * window_position);
            const double weight = cutoff * sinc * window;
            sum += input[static_cast<std::size_t>(source)] * weight;
            weight_sum += weight;
        }
        output[out] = weight_sum != 0.0 ? sum / weight_sum : Complex{};
    }
    return output;
}

inline std::vector<std::int16_t> make_waveform(
    const std::vector<std::uint8_t>& psdu, double lead_ms = 1.0,
    double tail_ms = 2.0, double amplitude = 0.25,
    std::size_t guard_chips = 32,
    std::int64_t output_sample_rate = kDefaultSampleRate) {
    if (output_sample_rate <= 0)
        throw std::runtime_error("waveform sample rate must be positive");
    if (!(amplitude > 0.0 && amplitude < 1.0))
        throw std::runtime_error("waveform amplitude must be between 0 and 1");
    if (lead_ms < 0.0 || tail_ms < 0.0)
        throw std::runtime_error("waveform guards must be nonnegative");

    auto chips = make_long_1mbps_chips(psdu);
    std::vector<Complex> padded(guard_chips, Complex{});
    padded.insert(padded.end(), chips.begin(), chips.end());
    padded.insert(padded.end(), guard_chips, Complex{});
    const auto packet = sinc_resample(
        padded, kChipRate, static_cast<double>(output_sample_rate));
    const auto lead = static_cast<std::size_t>(
        std::llround(lead_ms * output_sample_rate / 1000.0));
    const auto tail = static_cast<std::size_t>(
        std::llround(tail_ms * output_sample_rate / 1000.0));
    std::vector<std::int16_t> output(
        (lead + packet.size() + tail) * 2, 0);
    const auto quantize = [amplitude](double sample) {
        const auto scaled =
            std::clamp(sample * amplitude, -0.999969, 0.999969);
        return static_cast<std::int16_t>(
            std::llround(scaled * 32767.0));
    };
    for (std::size_t index = 0; index < packet.size(); ++index) {
        output[(lead + index) * 2] = quantize(packet[index].real());
        output[(lead + index) * 2 + 1] = quantize(packet[index].imag());
    }
    return output;
}

}  // namespace gf::dsss_tx

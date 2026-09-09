#pragma once
#include <array>
#include <cstdint>

namespace gf::e310::counters {
// Absolute GP0 offsets. All other fields, including TX-rejected at 0x248,
// are already binary/status/payload and must never pass through this decoder.
constexpr std::uint32_t capability_address = 0x280;
constexpr std::uint32_t gray32 = 0x47523332; // GR32
constexpr std::array<std::uint32_t,11> addresses{
    0x218,0x21c,0x220,0x224,0x228,0x23c,0x24c,0x260,0x264,0x268,0x26c};
using Words = std::array<std::uint32_t,addresses.size()>;
constexpr bool supported(std::uint32_t capability) noexcept {
    return capability == 0 || capability == 0xdead0280 || capability == gray32;
}
constexpr bool encoded_address(std::uint32_t address) noexcept {
    switch (address) {
    case 0x218: case 0x21c: case 0x220: case 0x224: case 0x228:
    case 0x23c: case 0x24c:
    case 0x260: case 0x264: case 0x268: case 0x26c: return true;
    default: return false;
    }
}
constexpr std::uint32_t decode(std::uint32_t gray) noexcept {
    gray ^= gray >> 1;
    gray ^= gray >> 2;
    gray ^= gray >> 4;
    gray ^= gray >> 8;
    gray ^= gray >> 16;
    return gray;
}
constexpr std::uint32_t normalize(bool is_gray, std::uint32_t address,
                                  std::uint32_t value) noexcept {
    return is_gray && encoded_address(address) ? decode(value) : value;
}
} // namespace gf::e310::counters

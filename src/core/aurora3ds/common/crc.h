// Copyright 2026 Aurora Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <cstddef>
#include <cstdint>

namespace Common::CRC {

template <typename T>
constexpr T Reflect(T value, std::size_t bits) {
    T result = 0;
    for (std::size_t i = 0; i < bits; ++i) {
        if ((value >> i) & 1) {
            result |= static_cast<T>(1) << (bits - 1 - i);
        }
    }
    return result;
}

template <typename T>
constexpr T Compute(const void* data, std::size_t size, T polynomial, T init, T xor_out,
                    bool reflect_in, bool reflect_out) {
    const auto* bytes = static_cast<const std::uint8_t*>(data);
    T crc = init;
    constexpr std::size_t kBitWidth = sizeof(T) * 8;
    constexpr T kTopBit = static_cast<T>(T{1} << (kBitWidth - 1));
    for (std::size_t i = 0; i < size; ++i) {
        auto current_byte = static_cast<T>(bytes[i]);
        if (reflect_in) {
            current_byte = Reflect(current_byte, 8);
        }
        crc ^= current_byte << (kBitWidth - 8);
        for (std::size_t bit = 0; bit < 8; ++bit) {
            if ((crc & kTopBit) != 0) {
                crc = static_cast<T>((crc << 1) ^ polynomial);
            } else {
                crc = static_cast<T>(crc << 1);
            }
        }
    }
    if (reflect_out) {
        crc = Reflect(crc, kBitWidth);
    }
    return static_cast<T>(crc ^ xor_out);
}

inline std::uint8_t CRC8_07(const void* data, std::size_t size) {
    return Compute<std::uint8_t>(data, size, 0x07, 0x00, 0x00, false, false);
}

inline std::uint16_t CRC16_1021(const void* data, std::size_t size) {
    return Compute<std::uint16_t>(data, size, 0x1021, 0x0000, 0x0000, false, false);
}

inline std::uint32_t CRC32_04C11DB7(const void* data, std::size_t size) {
    return Compute<std::uint32_t>(data, size, 0x04C11DB7u, 0xFFFFFFFFu, 0xFFFFFFFFu, true, true);
}

} // namespace Common::CRC

//FILE MODIFIED BY AzaharPlus OCTOBER 2025

// Copyright Citra Emulator Project / Azahar Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include <algorithm>
#include "math_util.h"

#define CITRA_HAS_NEON
#include <arm_neon.h>

// iOS device-only build uses clang.
#define DISABLE_VECTORIZE _Pragma("clang loop vectorize(disable)")

namespace Common {
std::pair<u8, u8> FindMinMax(const std::span<const u8>& data) {
    const size_t count = data.size();
    const u8* data_ptr = data.data();
    u8 final_min, final_max;
    final_min = 0xFF;
    final_max = 0;
	
#if defined(CITRA_HAS_NEON)
    u8 simd_min = 0xFF;
    u8 simd_max = 0;
    size_t i = 0;
    constexpr size_t simd_line_count = 16;
    constexpr size_t count_threshold = simd_line_count * 2;
    if (count >= count_threshold) {
        uint8x16_t vmin = vdupq_n_u8(0xFF);
        uint8x16_t vmax = vdupq_n_u8(0);
        for (; i + simd_line_count <= count; i += simd_line_count) {
            uint8x16_t vals = vld1q_u8(data_ptr + i);
            vmin = vminq_u8(vmin, vals);
            vmax = vmaxq_u8(vmax, vals);
        }
        alignas(16) uint8_t tmp[simd_line_count];
        vst1q_u8(tmp, vmin);
        simd_min = *std::min_element(tmp, tmp + simd_line_count);
        vst1q_u8(tmp, vmax);
        simd_max = *std::max_element(tmp, tmp + simd_line_count);
    }
    DISABLE_VECTORIZE
    for (; i < count; ++i) {
        const u8 val = data_ptr[i];
        simd_min = std::min(simd_min, val);
        simd_max = std::max(simd_max, val);
    }

    final_min = simd_min;
    final_max = simd_max;

#else
    // Scalar fallback

    for (size_t i = 0; i < count; ++i) {
        const u8 val = data_ptr[i];
        final_min = std::min(final_min, val);
        final_max = std::max(final_max, val);
    }
#endif // CITRA_HAS_NEON

    return {final_min, final_max};
}

std::pair<u16, u16> FindMinMax(const std::span<const u16>& data) {
    const size_t count = data.size();
    const u16* data_ptr = data.data();
    u16 final_min, final_max;
    final_min = 0xFFFF;
    final_max = 0;

#if defined(CITRA_HAS_NEON)
    u16 simd_min = 0xFFFF;
    u16 simd_max = 0;
    size_t i = 0;
    constexpr size_t simd_line_count = 8;
    constexpr size_t count_threshold = simd_line_count * 2;
    if (count >= count_threshold) {
        uint16x8_t vmin = vdupq_n_u16(static_cast<u16>(0xFFFF));
        uint16x8_t vmax = vdupq_n_u16(0);
        for (; i + simd_line_count <= count; i += simd_line_count) {
            uint16x8_t vals = vld1q_u16(data_ptr + i);
            vmin = vminq_u16(vmin, vals);
            vmax = vmaxq_u16(vmax, vals);
        }
        alignas(16) uint16_t tmp[simd_line_count];
        vst1q_u16(tmp, vmin);
        simd_min = *std::min_element(tmp, tmp + simd_line_count);
        vst1q_u16(tmp, vmax);
        simd_max = *std::max_element(tmp, tmp + simd_line_count);
    }
    DISABLE_VECTORIZE
    for (; i < count; ++i) {
        const u16 val = data_ptr[i];
        simd_min = std::min(simd_min, val);
        simd_max = std::max(simd_max, val);
    }

    final_min = simd_min;
    final_max = simd_max;

#else
    // Scalar fallback
    for (u32 i = 0; i < count; ++i) {
        const u16 val = data_ptr[i];
        final_min = std::min(final_min, val);
        final_max = std::max(final_max, val);
    }
#endif // CITRA_HAS_NEON

    return {final_min, final_max};
}
} // namespace Common

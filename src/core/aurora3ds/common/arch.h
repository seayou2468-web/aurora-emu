// Copyright 2023 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <cstdint>

#define CITRA_ARCH(NAME) (CITRA_ARCH_##NAME)

#if defined(__x86_64__) || defined(_M_X64)
#define CITRA_ARCH_x86_64 1
#else
#define CITRA_ARCH_x86_64 0
#endif

#if (defined(__aarch64__) || defined(_M_ARM64)) && (UINTPTR_MAX == 0xffffffffffffffffULL)
#define CITRA_ARCH_arm64 1
#else
#define CITRA_ARCH_arm64 0
#endif

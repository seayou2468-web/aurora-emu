// Copyright 2023 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <cstdint>

#define CITRA_ARCH(NAME) (CITRA_ARCH_##NAME)

// iOS device-only build: arm64 is the only supported target architecture.
#define CITRA_ARCH_x86_64 0
#define CITRA_ARCH_arm64 1

// Copyright Citra Emulator Project / Azahar Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

// Copyright 2013 Dolphin Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include <cstddef>
#include <cerrno>
#include <cstring>

#include "common/error.h"

namespace Common {

std::string NativeErrorToString(int e) {
    char err_str[255];

    // Thread safe (XSI-compliant)
    int second_err = strerror_r(e, err_str, sizeof(err_str));
    if (second_err != 0) {
        return "(strerror_r failed to format error)";
    }
    return std::string(err_str);
}

std::string GetLastErrorMsg() {
    return NativeErrorToString(errno);
}

} // namespace Common

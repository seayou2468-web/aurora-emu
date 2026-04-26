// Copyright 2026 Aurora Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <optional>

#include "common/serialization/compat.h"

namespace Common::SerializationCompat {

template <class Archive, typename T>
void save(Archive& ar, const std::optional<T>& opt, const unsigned int) {
    bool has_value = opt.has_value();
    ar & has_value;
    if (has_value) {
        T value = *opt;
        ar & value;
    }
}

template <class Archive, typename T>
void load(Archive& ar, std::optional<T>& opt, const unsigned int) {
    bool has_value{};
    ar & has_value;
    if (!has_value) {
        opt.reset();
        return;
    }

    T value{};
    ar & value;
    opt = std::move(value);
}

template <class Archive, typename T>
void serialize(Archive& ar, std::optional<T>& opt, const unsigned int file_version) {
    if constexpr (Archive::is_saving::value) {
        save(ar, opt, file_version);
    } else {
        load(ar, opt, file_version);
    }
}

} // namespace Common::SerializationCompat

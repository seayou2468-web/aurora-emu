// Copyright 2026 Aurora Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include "common/boost_compat/all.h"
#include <optional>

namespace boost::serialization {

template <class Archive, typename T>
void save(Archive& ar, const std::optional<T>& opt, const unsigned int) {
    const bool has_value = opt.has_value();
    ar & has_value;
    if (has_value) {
        ar & *opt;
    }
}

template <class Archive, typename T>
void load(Archive& ar, std::optional<T>& opt, const unsigned int) {
    bool has_value{};
    ar & has_value;
    if (has_value) {
        T value{};
        ar & value;
        opt = std::move(value);
    } else {
        opt.reset();
    }
}

template <class Archive, typename T>
void serialize(Archive& ar, std::optional<T>& opt, const unsigned int file_version) {
    split_free(ar, opt, file_version);
}

} // namespace boost::serialization

// Copyright 2020 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <atomic>

#include "common/serialization/compat.h"

namespace Common::SerializationCompat {

template <class Archive, class T>
void save(Archive& ar, const std::atomic<T>& value, const unsigned int) {
    T tmp = value.load(std::memory_order_relaxed);
    ar & tmp;
}

template <class Archive, class T>
void load(Archive& ar, std::atomic<T>& value, const unsigned int) {
    T tmp{};
    ar & tmp;
    value.store(tmp, std::memory_order_relaxed);
}

template <class Archive, class T>
void serialize(Archive& ar, std::atomic<T>& value, const unsigned int file_version) {
    if constexpr (Archive::is_saving::value) {
        save(ar, value, file_version);
    } else {
        load(ar, value, file_version);
    }
}

} // namespace Common::SerializationCompat

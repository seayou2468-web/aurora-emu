// Copyright 2026 Aurora Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include "common/boost_compat/all.h"
#include <vector>
#include "common/interval_set.h"

namespace boost::serialization {

template <class Archive, typename T>
void serialize(Archive& ar, typename Common::IntervalSet<T>::Interval& interval,
               const unsigned int) {
    ar & interval.lo;
    ar & interval.hi;
}

template <class Archive, typename T>
void save(Archive& ar, const Common::IntervalSet<T>& set, const unsigned int) {
    std::vector<typename Common::IntervalSet<T>::Interval> intervals(set.begin(), set.end());
    ar & intervals;
}

template <class Archive, typename T>
void load(Archive& ar, Common::IntervalSet<T>& set, const unsigned int) {
    std::vector<typename Common::IntervalSet<T>::Interval> intervals;
    ar & intervals;
    set.clear();
    for (const auto& interval : intervals) {
        set += interval;
    }
}

template <class Archive, typename T>
void serialize(Archive& ar, Common::IntervalSet<T>& set, const unsigned int file_version) {
    split_free(ar, set, file_version);
}

} // namespace boost::serialization

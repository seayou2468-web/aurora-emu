// Copyright 2026 Aurora Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <algorithm>
#include <cstddef>
#include <set>

namespace Common {

template <typename T>
class IntervalSet {
public:
    struct Interval {
        T lo{};
        T hi{};

        static Interval right_open(T lower, T upper) {
            return Interval{lower, upper};
        }

        T lower() const {
            return lo;
        }
        T upper() const {
            return hi;
        }
    };

    struct IntervalLess {
        bool operator()(const Interval& lhs, const Interval& rhs) const {
            return lhs.lo < rhs.lo || (lhs.lo == rhs.lo && lhs.hi < rhs.hi);
        }
    };
    using interval_type = Interval;
    using storage_type = std::set<Interval, IntervalLess>;
    using const_iterator = typename storage_type::const_iterator;
    using const_reverse_iterator = typename storage_type::const_reverse_iterator;

    const_iterator begin() const { return intervals.begin(); }
    const_iterator end() const { return intervals.end(); }
    const_reverse_iterator rbegin() const { return intervals.rbegin(); }
    const_reverse_iterator rend() const { return intervals.rend(); }
    bool empty() const { return intervals.empty(); }
    std::size_t size() const { return intervals.size(); }
    void clear() { intervals.clear(); }

    void insert(const Interval& interval) { Add(interval); }

    IntervalSet& operator+=(const Interval& interval) {
        Add(interval);
        return *this;
    }
    IntervalSet& operator-=(const Interval& interval) {
        Remove(interval);
        return *this;
    }
    IntervalSet& operator+=(const IntervalSet& other) {
        for (const auto& i : other.intervals) {
            Add(i);
        }
        return *this;
    }
    IntervalSet& operator-=(const IntervalSet& other) {
        for (const auto& i : other.intervals) {
            Remove(i);
        }
        return *this;
    }

    friend bool Contains(const IntervalSet& set, const Interval& interval) {
        auto it = set.intervals.upper_bound(Interval{interval.lo, interval.lo});
        if (it == set.intervals.begin()) {
            return false;
        }
        --it;
        return it->lo <= interval.lo && interval.hi <= it->hi;
    }

    friend bool Intersects(const IntervalSet& set, const Interval& interval) {
        auto it = set.intervals.lower_bound(Interval{interval.lo, interval.lo});
        if (it != set.intervals.end() && it->lo < interval.hi && interval.lo < it->hi) {
            return true;
        }
        if (it != set.intervals.begin()) {
            --it;
            if (it->lo < interval.hi && interval.lo < it->hi) {
                return true;
            }
        }
        return false;
    }

private:
    void Add(Interval interval) {
        if (!(interval.lo < interval.hi)) {
            return;
        }

        auto it = intervals.lower_bound(Interval{interval.lo, interval.lo});
        if (it != intervals.begin()) {
            auto prev = std::prev(it);
            if (prev->hi >= interval.lo) {
                interval.lo = std::min(interval.lo, prev->lo);
                interval.hi = std::max(interval.hi, prev->hi);
                it = intervals.erase(prev);
            }
        }
        while (it != intervals.end() && it->lo <= interval.hi) {
            interval.lo = std::min(interval.lo, it->lo);
            interval.hi = std::max(interval.hi, it->hi);
            it = intervals.erase(it);
        }
        intervals.insert(it, interval);
    }

    void Remove(const Interval& interval) {
        if (!(interval.lo < interval.hi)) {
            return;
        }
        auto it = intervals.lower_bound(Interval{interval.lo, interval.lo});
        if (it != intervals.begin()) {
            --it;
        }
        while (it != intervals.end()) {
            if (it->hi <= interval.lo) {
                ++it;
                continue;
            }
            if (it->lo >= interval.hi) {
                break;
            }

            const Interval current = *it;
            it = intervals.erase(it);
            if (current.lo < interval.lo) {
                intervals.insert(Interval{current.lo, interval.lo});
            }
            if (interval.hi < current.hi) {
                intervals.insert(Interval{interval.hi, current.hi});
                break;
            }
        }
    }

    storage_type intervals;
};

} // namespace Common

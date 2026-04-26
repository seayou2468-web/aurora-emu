// Copyright 2026 Aurora Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <algorithm>
#include <cstddef>
#include <type_traits>
#include <utility>
#include <vector>

namespace boost::icl {

struct partial_absorber {};
struct inplace_plus {};
struct inter_section {};

using bound_type = unsigned;

template <typename T>
struct interval_bounds {
    explicit interval_bounds(T bits_) : bits(bits_) {}
    T bits;
};

template <typename T>
class right_open_interval {
public:
    using domain_type = T;

    right_open_interval() = default;
    right_open_interval(T lower_, T upper_) : lower_value(lower_), upper_value(upper_) {}

    static right_open_interval right_open(T lower_, T upper_) {
        return right_open_interval(lower_, upper_);
    }

    T lower() const { return lower_value; }
    T upper() const { return upper_value; }

    right_open_interval operator&(const right_open_interval& other) const {
        return right_open_interval(std::max(lower_value, other.lower_value),
                                   std::min(upper_value, other.upper_value));
    }

private:
    T lower_value{};
    T upper_value{};
};

template <typename T>
using discrete_interval = right_open_interval<T>;

template <typename Interval>
auto first(const Interval& interval) {
    return interval.lower();
}

template <typename Interval>
auto last_next(const Interval& interval) {
    return interval.upper();
}

template <typename Interval>
auto lower(const Interval& interval) {
    return interval.lower();
}

template <typename Interval>
auto length(const Interval& interval) {
    const auto lo = interval.lower();
    const auto hi = interval.upper();
    return hi > lo ? (hi - lo) : 0;
}

template <typename Interval>
bool is_empty(const Interval& interval) {
    return interval.upper() <= interval.lower();
}

template <typename T, typename Compare = std::less<T>, typename Interval = right_open_interval<T>>
class interval_set {
public:
    using interval_type = Interval;
    using value_type = interval_type;
    using storage_type = std::vector<interval_type>;
    using const_iterator = typename storage_type::const_iterator;

    bool empty() const { return intervals.empty(); }
    std::size_t size() const { return intervals.size(); }
    std::size_t iterative_size() const { return intervals.size(); }

    void clear() { intervals.clear(); }

    const_iterator begin() const { return intervals.begin(); }
    const_iterator end() const { return intervals.end(); }

    interval_set& operator+=(const interval_type& interval) {
        if (!is_empty(interval))
            intervals.push_back(interval);
        Normalize();
        return *this;
    }

    interval_set& operator-=(const interval_type& interval) {
        if (is_empty(interval) || intervals.empty())
            return *this;

        storage_type result;
        result.reserve(intervals.size());
        for (const auto& current : intervals) {
            if (last_next(current) <= first(interval) || last_next(interval) <= first(current)) {
                result.push_back(current);
                continue;
            }

            if (first(current) < first(interval)) {
                result.emplace_back(first(current), std::min(last_next(current), first(interval)));
            }
            if (last_next(interval) < last_next(current)) {
                result.emplace_back(std::max(first(current), last_next(interval)),
                                    last_next(current));
            }
        }
        intervals = std::move(result);
        return *this;
    }

private:
    void Normalize() {
        if (intervals.empty())
            return;

        std::sort(intervals.begin(), intervals.end(), [](const auto& lhs, const auto& rhs) {
            if (first(lhs) != first(rhs))
                return first(lhs) < first(rhs);
            return last_next(lhs) < last_next(rhs);
        });

        storage_type merged;
        merged.reserve(intervals.size());
        merged.push_back(intervals.front());
        for (std::size_t i = 1; i < intervals.size(); ++i) {
            auto& back = merged.back();
            if (first(intervals[i]) <= last_next(back)) {
                back = interval_type(first(back), std::max(last_next(back), last_next(intervals[i])));
            } else {
                merged.push_back(intervals[i]);
            }
        }
        intervals = std::move(merged);
    }

    storage_type intervals;
};

template <typename K, typename V, typename Absorber = partial_absorber,
          typename Compare = std::less<K>, typename Combiner = inplace_plus,
          typename Section = inter_section, typename Interval = right_open_interval<K>>
class interval_map {
public:
    using interval_type = Interval;
    using value_type = std::pair<interval_type, V>;
    using storage_type = std::vector<value_type>;
    using iterator = typename storage_type::iterator;
    using const_iterator = typename storage_type::const_iterator;

    iterator begin() { return data.begin(); }
    iterator end() { return data.end(); }
    const_iterator begin() const { return data.begin(); }
    const_iterator end() const { return data.end(); }

    bool empty() const { return data.empty(); }
    void clear() { data.clear(); }

    void add(const value_type& entry) {
        const auto& interval = entry.first;
        const auto value = entry.second;
        if (is_empty(interval))
            return;

        std::vector<value_type> out;
        out.reserve(data.size() + 2);
        bool inserted = false;
        for (const auto& [current_interval, current_value] : data) {
            if (last_next(current_interval) <= first(interval) ||
                last_next(interval) <= first(current_interval)) {
                if (!inserted && first(interval) < first(current_interval)) {
                    out.emplace_back(interval, value);
                    inserted = true;
                }
                out.emplace_back(current_interval, current_value);
                continue;
            }

            const K lo = std::max(first(current_interval), first(interval));
            const K hi = std::min(last_next(current_interval), last_next(interval));
            if (first(current_interval) < lo) {
                out.emplace_back(interval_type(first(current_interval), lo), current_value);
            }
            out.emplace_back(interval_type(lo, hi), current_value + value);
            if (hi < last_next(current_interval)) {
                out.emplace_back(interval_type(hi, last_next(current_interval)), current_value);
            }

            if (!inserted && first(interval) < first(current_interval)) {
                inserted = true;
            }
        }
        if (!inserted) {
            out.emplace_back(interval, value);
        }
        data = std::move(out);
        Normalize();
    }

    void set(const value_type& entry) {
        erase(entry.first);
        if (!is_empty(entry.first)) {
            data.push_back(entry);
            Normalize();
        }
    }

    void erase(const interval_type& interval) {
        if (is_empty(interval) || data.empty())
            return;
        storage_type out;
        out.reserve(data.size());
        for (const auto& [current_interval, current_value] : data) {
            if (last_next(current_interval) <= first(interval) ||
                last_next(interval) <= first(current_interval)) {
                out.emplace_back(current_interval, current_value);
                continue;
            }
            if (first(current_interval) < first(interval)) {
                out.emplace_back(interval_type(first(current_interval), first(interval)), current_value);
            }
            if (last_next(interval) < last_next(current_interval)) {
                out.emplace_back(interval_type(last_next(interval), last_next(current_interval)),
                                 current_value);
            }
        }
        data = std::move(out);
    }

    interval_map& operator-=(const interval_type& interval) {
        erase(interval);
        return *this;
    }

    template <typename TSet>
    interval_map& operator-=(const TSet& set) {
        for (const auto& interval : set) {
            erase(interval);
        }
        return *this;
    }

    iterator find(const interval_type& interval) {
        return std::find_if(data.begin(), data.end(), [&](const auto& entry) {
            return !is_empty(entry.first & interval);
        });
    }
    const_iterator find(const interval_type& interval) const {
        return std::find_if(data.begin(), data.end(), [&](const auto& entry) {
            return !is_empty(entry.first & interval);
        });
    }

    std::pair<iterator, iterator> equal_range(const interval_type& interval) {
        auto first_it = std::find_if(data.begin(), data.end(), [&](const auto& entry) {
            return !is_empty(entry.first & interval);
        });
        if (first_it == data.end())
            return {data.end(), data.end()};
        auto last_it = first_it;
        for (; last_it != data.end() && !is_empty(last_it->first & interval); ++last_it) {
        }
        return {first_it, last_it};
    }
    std::pair<const_iterator, const_iterator> equal_range(const interval_type& interval) const {
        auto first_it = std::find_if(data.begin(), data.end(), [&](const auto& entry) {
            return !is_empty(entry.first & interval);
        });
        if (first_it == data.end())
            return {data.end(), data.end()};
        auto last_it = first_it;
        for (; last_it != data.end() && !is_empty(last_it->first & interval); ++last_it) {
        }
        return {first_it, last_it};
    }

private:
    void Normalize() {
        if (data.empty())
            return;

        std::sort(data.begin(), data.end(), [](const auto& lhs, const auto& rhs) {
            return first(lhs.first) < first(rhs.first);
        });

        storage_type merged;
        merged.reserve(data.size());
        for (const auto& item : data) {
            if (is_empty(item.first))
                continue;
            if (merged.empty()) {
                merged.push_back(item);
                continue;
            }
            auto& back = merged.back();
            if (back.second == item.second && last_next(back.first) >= first(item.first)) {
                back.first = interval_type(first(back.first),
                                           std::max(last_next(back.first), last_next(item.first)));
            } else {
                merged.push_back(item);
            }
        }
        data = std::move(merged);
    }

    storage_type data;
};

} // namespace boost::icl

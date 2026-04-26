#pragma once

#include <variant>

#include "common/serialization/compat.h"

namespace Common::SerializationCompat {

template <class Archive, class... Types>
void save(Archive& ar, const std::variant<Types...>& value, const unsigned int) {
    std::uint32_t index = static_cast<std::uint32_t>(value.index());
    ar & index;
    std::visit([&](const auto& held) {
        using Held = std::decay_t<decltype(held)>;
        Held copy = held;
        ar & copy;
    }, value);
}

template <class Archive, class... Types>
void load(Archive& ar, std::variant<Types...>& value, const unsigned int) {
    std::uint32_t index{};
    ar & index;

    bool restored = false;
    std::size_t current = 0;
    ([&] {
        if (!restored && current == index) {
            using T = Types;
            T item{};
            ar & item;
            value = std::move(item);
            restored = true;
        }
        ++current;
    }(), ...);

    if (!restored) {
        throw_exception(std::runtime_error("variant index out of range"));
    }
}

template <class Archive, class... Types>
void serialize(Archive& ar, std::variant<Types...>& value, const unsigned int file_version) {
    if constexpr (Archive::is_saving::value) {
        save(ar, value, file_version);
    } else {
        load(ar, value, file_version);
    }
}

template <class Archive>
void serialize(Archive&, std::monostate&, const unsigned int) {}

} // namespace Common::SerializationCompat

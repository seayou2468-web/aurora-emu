// Copyright 2026 Aurora Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <deque>
#include <functional>
#include <istream>
#include <list>
#include <map>
#include <memory>
#include <optional>
#include <ostream>
#include <set>
#include <stdexcept>
#include <string>
#include <type_traits>
#include <unordered_map>
#include <utility>
#include <variant>
#include <vector>

namespace Common::Serialization::Std {

class ArchiveError : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};

class access {
public:
    template <typename Archive, typename T>
    static void serialize(Archive& ar, T& value, const unsigned int version) {
        value.serialize(ar, version);
    }
};

class BinaryOutputArchive;
class BinaryInputArchive;

template <typename Archive, typename T>
void SerializeValue(Archive& ar, T& value);

class BinaryOutputArchive {
public:
    using is_saving = std::true_type;
    using is_loading = std::false_type;

    explicit BinaryOutputArchive(std::ostream& stream_) : stream(stream_) {}

    void save_binary(const void* data, std::size_t size) {
        stream.write(reinterpret_cast<const char*>(data), static_cast<std::streamsize>(size));
        if (!stream) {
            throw ArchiveError("failed to write binary payload");
        }
    }

    template <typename T>
    BinaryOutputArchive& operator&(T& value) {
        SerializeValue(*this, value);
        return *this;
    }
    template <typename T>
    BinaryOutputArchive& operator<<(T& value) {
        return (*this & value);
    }

private:
    std::ostream& stream;
};

class BinaryInputArchive {
public:
    using is_saving = std::false_type;
    using is_loading = std::true_type;

    explicit BinaryInputArchive(std::istream& stream_) : stream(stream_) {}

    void load_binary(void* data, std::size_t size) {
        stream.read(reinterpret_cast<char*>(data), static_cast<std::streamsize>(size));
        if (!stream) {
            throw ArchiveError("failed to read binary payload");
        }
    }

    template <typename T>
    BinaryInputArchive& operator&(T& value) {
        SerializeValue(*this, value);
        return *this;
    }
    template <typename T>
    BinaryInputArchive& operator>>(T& value) {
        return (*this & value);
    }

private:
    std::istream& stream;
};

struct BinaryBlob {
    void* data{};
    std::size_t size{};
};

inline BinaryBlob make_binary_object(void* data, std::size_t size) {
    return BinaryBlob{data, size};
}

inline BinaryBlob make_binary_object(const void* data, std::size_t size) {
    return BinaryBlob{const_cast<void*>(data), size};
}

template <typename Archive>
void SerializeValue(Archive& ar, BinaryBlob& blob) {
    if constexpr (Archive::is_saving::value) {
        ar.save_binary(blob.data, blob.size);
    } else {
        ar.load_binary(blob.data, blob.size);
    }
}

template <typename Archive, typename T, typename = void>
struct HasSerializeMember : std::false_type {};

template <typename Archive, typename T>
struct HasSerializeMember<Archive, T,
                          std::void_t<decltype(std::declval<T&>().serialize(
                              std::declval<Archive&>(), std::declval<unsigned int>()))>>
    : std::true_type {};

template <typename Archive>
void SerializeValue(Archive& ar, std::string& value) {
    std::uint64_t size = static_cast<std::uint64_t>(value.size());
    ar & size;
    if constexpr (Archive::is_loading::value) {
        value.resize(static_cast<std::size_t>(size));
    }
    if (size != 0) {
        auto blob = make_binary_object(value.data(), static_cast<std::size_t>(size));
        ar & blob;
    }
}

template <typename Archive, typename T, std::size_t N>
void SerializeValue(Archive& ar, std::array<T, N>& value) {
    for (auto& item : value) {
        ar & item;
    }
}

template <typename Archive, typename T>
void SerializeValue(Archive& ar, std::vector<T>& value) {
    std::uint64_t size = static_cast<std::uint64_t>(value.size());
    ar & size;
    if constexpr (Archive::is_loading::value) {
        value.resize(static_cast<std::size_t>(size));
    }
    for (auto& item : value) {
        ar & item;
    }
}

template <typename Archive, typename T>
void SerializeValue(Archive& ar, std::deque<T>& value) {
    std::uint64_t size = static_cast<std::uint64_t>(value.size());
    ar & size;
    if constexpr (Archive::is_loading::value) {
        value.clear();
        for (std::uint64_t i = 0; i < size; ++i) {
            T item{};
            ar & item;
            value.push_back(std::move(item));
        }
        return;
    }
    for (auto& item : value) {
        ar & item;
    }
}

template <typename Archive, typename T>
void SerializeValue(Archive& ar, std::list<T>& value) {
    std::uint64_t size = static_cast<std::uint64_t>(value.size());
    ar & size;
    if constexpr (Archive::is_loading::value) {
        value.clear();
        for (std::uint64_t i = 0; i < size; ++i) {
            T item{};
            ar & item;
            value.push_back(std::move(item));
        }
        return;
    }
    for (auto& item : value) {
        ar & item;
    }
}

template <typename Archive, typename T>
void SerializeValue(Archive& ar, std::set<T>& value) {
    std::uint64_t size = static_cast<std::uint64_t>(value.size());
    ar & size;
    if constexpr (Archive::is_loading::value) {
        value.clear();
        for (std::uint64_t i = 0; i < size; ++i) {
            T item{};
            ar & item;
            value.insert(std::move(item));
        }
        return;
    }
    for (auto& item : value) {
        auto tmp = item;
        ar & tmp;
    }
}

template <typename Archive, typename K, typename V>
void SerializeValue(Archive& ar, std::map<K, V>& value) {
    std::uint64_t size = static_cast<std::uint64_t>(value.size());
    ar & size;
    if constexpr (Archive::is_loading::value) {
        value.clear();
        for (std::uint64_t i = 0; i < size; ++i) {
            K key{};
            V mapped{};
            ar & key;
            ar & mapped;
            value.emplace(std::move(key), std::move(mapped));
        }
        return;
    }
    for (auto& [key, mapped] : value) {
        auto key_copy = key;
        ar & key_copy;
        ar & mapped;
    }
}

template <typename Archive, typename K, typename V>
void SerializeValue(Archive& ar, std::unordered_map<K, V>& value) {
    std::uint64_t size = static_cast<std::uint64_t>(value.size());
    ar & size;
    if constexpr (Archive::is_loading::value) {
        value.clear();
        value.reserve(static_cast<std::size_t>(size));
        for (std::uint64_t i = 0; i < size; ++i) {
            K key{};
            V mapped{};
            ar & key;
            ar & mapped;
            value.emplace(std::move(key), std::move(mapped));
        }
        return;
    }
    for (auto& [key, mapped] : value) {
        auto key_copy = key;
        ar & key_copy;
        ar & mapped;
    }
}

template <typename Archive, typename T>
void SerializeValue(Archive& ar, std::optional<T>& value) {
    bool has_value = value.has_value();
    ar & has_value;
    if constexpr (Archive::is_loading::value) {
        if (!has_value) {
            value.reset();
            return;
        }
        T data{};
        ar & data;
        value = std::move(data);
        return;
    }
    if (has_value) {
        ar & *value;
    }
}

template <typename Archive, typename... Ts>
void SerializeValue(Archive& ar, std::variant<Ts...>& value) {
    std::uint32_t index = static_cast<std::uint32_t>(value.index());
    ar & index;
    if constexpr (Archive::is_loading::value) {
        bool restored = false;
        std::size_t i = 0;
        ([&] {
            if (!restored && index == i) {
                using T = Ts;
                T data{};
                ar & data;
                value = std::move(data);
                restored = true;
            }
            ++i;
        }(), ...);
        if (!restored) {
            throw ArchiveError("variant index out of range");
        }
        return;
    }

    std::visit([&](auto& held) { ar & held; }, value);
}

template <typename Archive, typename T>
void SerializeValue(Archive& ar, std::unique_ptr<T>& value) {
    bool has_value = static_cast<bool>(value);
    ar & has_value;
    if constexpr (Archive::is_loading::value) {
        if (!has_value) {
            value.reset();
            return;
        }
        value = std::make_unique<T>();
        ar & *value;
        return;
    }
    if (has_value) {
        ar & *value;
    }
}

template <typename Archive, typename T>
void SerializeValue(Archive& ar, std::shared_ptr<T>& value) {
    bool has_value = static_cast<bool>(value);
    ar & has_value;
    if constexpr (Archive::is_loading::value) {
        if (!has_value) {
            value.reset();
            return;
        }
        value = std::make_shared<T>();
        ar & *value;
        return;
    }
    if (has_value) {
        ar & *value;
    }
}

template <typename Archive, typename T>
void SerializeValue(Archive& ar, T& value) {
    if constexpr (std::is_arithmetic_v<T> || std::is_enum_v<T>) {
        static_assert(std::is_trivially_copyable_v<T>);
        auto blob = make_binary_object(&value, sizeof(T));
        ar & blob;
    } else if constexpr (HasSerializeMember<Archive, T>::value) {
        access::serialize(ar, value, 0U);
    } else {
        static_assert(sizeof(T) == 0, "No serializer available for this type");
    }
}

template <typename Base>
using FactoryFn = std::function<std::shared_ptr<Base>()>;

template <typename Base>
class PolymorphicRegistry {
public:
    template <typename Derived>
    void Register(const std::string& type_name) {
        factories[type_name] = [] { return std::make_shared<Derived>(); };
    }

    std::shared_ptr<Base> Create(const std::string& type_name) const {
        const auto it = factories.find(type_name);
        if (it == factories.end()) {
            throw ArchiveError("unknown polymorphic type: " + type_name);
        }
        return it->second();
    }

private:
    std::unordered_map<std::string, FactoryFn<Base>> factories;
};

} // namespace Common::Serialization::Std

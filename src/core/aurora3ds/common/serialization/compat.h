// Copyright 2026 Aurora Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <string>
#include <type_traits>
#include <typeinfo>
#include <unordered_map>

#include "common/serialization/std_archive.h"

namespace Common::SerializationCompat {
struct access : Common::Serialization::Std::access {};
using Common::Serialization::Std::make_binary_object;

template <typename Base, typename Derived>
Base& base_object(Derived& derived) {
    return static_cast<Base&>(derived);
}

template <typename Base, typename Derived>
const Base& base_object(const Derived& derived) {
    return static_cast<const Base&>(derived);
}

template <typename Archive, typename T>
void split_free(Archive& ar, T& value, const unsigned int file_version) {
    if constexpr (Archive::is_saving::value) {
        save(ar, value, file_version);
    } else {
        load(ar, value, file_version);
    }
}

template <typename Archive, typename T>
void split_member(Archive& ar, T& value, const unsigned int file_version) {
    if constexpr (Archive::is_saving::value) {
        value.save(ar, file_version);
    } else {
        value.load(ar, file_version);
    }
}

template <typename Exception>
[[noreturn]] void throw_exception(Exception&& ex) {
    throw std::forward<Exception>(ex);
}

namespace Detail {
inline std::unordered_map<std::string, unsigned int>& VersionTable() {
    static std::unordered_map<std::string, unsigned int> versions;
    return versions;
}
} // namespace Detail

template <typename T>
void RegisterVersion(unsigned int version) {
    Detail::VersionTable()[typeid(T).name()] = version;
}

template <typename T>
unsigned int GetVersion() {
    const auto it = Detail::VersionTable().find(typeid(T).name());
    return it == Detail::VersionTable().end() ? 0U : it->second;
}

} // namespace Common::SerializationCompat

namespace Common::SerializationCompat::Export {
template <typename T>
struct ExportKey {
    static constexpr const char* value = nullptr;
};
} // namespace Common::SerializationCompat::Export

#define SERIALIZATION_COMPAT_CLASS_EXPORT_KEY(Type)                                                \
    template <>                                                                                    \
    struct Common::SerializationCompat::Export::ExportKey<Type> {                                 \
        static constexpr const char* value = #Type;                                                \
    };

#define SERIALIZATION_COMPAT_CONSTRUCT(Type)

namespace Common::SerializationCompat::Version {
template <typename T>
struct VersionValue {
    static constexpr unsigned int value = 0U;
};
} // namespace Common::SerializationCompat::Version

#define SERIALIZATION_COMPAT_CLASS_VERSION(Type, VersionNumber)                                    \
    template <>                                                                                    \
    struct Common::SerializationCompat::Version::VersionValue<Type> {                             \
        static constexpr unsigned int value = VersionNumber;                                       \
    };

#define SERIALIZATION_COMPAT_SPLIT_MEMBER()                                                         \
    template <typename Archive>                                                                     \
    void serialize(Archive& ar, const unsigned int file_version) {                                 \
        Common::SerializationCompat::split_member(ar, *this, file_version);                         \
    }

#define SERIALIZATION_COMPAT_EXT_NAMESPACE_BEGIN namespace Common::SerializationCompat {
#define SERIALIZATION_COMPAT_EXT_NAMESPACE_END }

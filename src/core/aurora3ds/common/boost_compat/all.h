// Copyright 2026 Aurora Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

// Centralized compatibility boundary for legacy Boost-style aurora3ds call sites.

#include <stdexcept>

#include "common/serialization/compat.h"
#include "common/serialization/std_archive.h"

namespace boost::archive {
class archive_exception : public std::runtime_error {
public:
    enum exception_code { unsupported_version };

    explicit archive_exception(exception_code)
        : std::runtime_error("archive_exception: unsupported_version") {}
};

using binary_iarchive = Common::Serialization::Std::BinaryInputArchive;
using binary_oarchive = Common::Serialization::Std::BinaryOutputArchive;
} // namespace boost::archive

namespace boost::serialization {
using access = Common::SerializationCompat::access;
using Common::SerializationCompat::make_binary_object;
using Common::SerializationCompat::split_free;
using Common::SerializationCompat::split_member;
using Common::SerializationCompat::throw_exception;

template <typename Base, typename Derived>
Base& base_object(Derived& derived) {
    return Common::SerializationCompat::base_object<Base>(derived);
}

template <typename Base, typename Derived>
const Base& base_object(const Derived& derived) {
    return Common::SerializationCompat::base_object<Base>(derived);
}

template <typename T>
struct wrapper_traits {};
} // namespace boost::serialization

#ifndef BOOST_CLASS_EXPORT_KEY
#define BOOST_CLASS_EXPORT_KEY(Type) SERIALIZATION_COMPAT_CLASS_EXPORT_KEY(Type)
#endif
#ifndef BOOST_SERIALIZATION_CONSTRUCT
#define BOOST_SERIALIZATION_CONSTRUCT(Type)
#endif
#ifndef BOOST_CLASS_VERSION
#define BOOST_CLASS_VERSION(Type, VersionNumber)                                                   \
    SERIALIZATION_COMPAT_CLASS_VERSION(Type, VersionNumber)
#endif
#ifndef BOOST_SERIALIZATION_SPLIT_MEMBER
#define BOOST_SERIALIZATION_SPLIT_MEMBER() SERIALIZATION_COMPAT_SPLIT_MEMBER()
#endif
#ifndef BOOST_CLASS_EXPORT_IMPLEMENT
#define BOOST_CLASS_EXPORT_IMPLEMENT(Type)                                                         \
    static_assert(Common::SerializationCompat::Export::ExportKey<Type>::value != nullptr,         \
                  "BOOST_CLASS_EXPORT_KEY missing for type")
#endif
#ifndef BOOST_SERIALIZATION_REGISTER_ARCHIVE
#define BOOST_SERIALIZATION_REGISTER_ARCHIVE(ArchiveType) static_assert(true, "archive registered")
#endif
#ifndef BOOST_SERIALIZATION_NVP
#define BOOST_SERIALIZATION_NVP(Value) Value
#endif

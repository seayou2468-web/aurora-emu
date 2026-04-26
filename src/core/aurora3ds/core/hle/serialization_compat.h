// Copyright 2026 Aurora Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include "common/boost_compat/all.h"

// NOTE:

#define SERIALIZATION_CLASS_EXPORT_KEY(...) BOOST_CLASS_EXPORT_KEY(__VA_ARGS__)
#define SERIALIZATION_CONSTRUCT(...) BOOST_SERIALIZATION_CONSTRUCT(__VA_ARGS__)
#define SERIALIZATION_CLASS_VERSION(...) BOOST_CLASS_VERSION(__VA_ARGS__)
#define SERIALIZATION_SPLIT_MEMBER() BOOST_SERIALIZATION_SPLIT_MEMBER()
#define SERIALIZATION_EXT_NAMESPACE_BEGIN namespace boost::serialization {
#define SERIALIZATION_EXT_NAMESPACE_END }

// This header centralizes serialization include dependencies used across the HLE layer.
// HLE code should depend on SerializationCompat instead of direct boost::serialization symbols.
namespace SerializationCompat {
using access = boost::serialization::access;

using boost::serialization::make_binary_object;
using boost::serialization::split_free;
using boost::serialization::split_member;
using boost::serialization::throw_exception;

template <typename Base, typename Derived>
auto base_object(Derived& derived) -> decltype(boost::serialization::base_object<Base>(derived)) {
    return boost::serialization::base_object<Base>(derived);
}

template <typename Base, typename Derived>
auto base_object(const Derived& derived)
    -> decltype(boost::serialization::base_object<Base>(derived)) {
    return boost::serialization::base_object<Base>(derived);
}
} // namespace SerializationCompat

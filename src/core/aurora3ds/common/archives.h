// Copyright Citra Emulator Project / Azahar Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once


#include "common/serialization/compat.h"
#include "common/serialization/std_archive.h"

using iarchive = Common::Serialization::Std::BinaryInputArchive;
using oarchive = Common::Serialization::Std::BinaryOutputArchive;

#define SERIALIZE_IMPL(A)                                                                          \
    template void A::serialize<iarchive>(iarchive & ar, const unsigned int file_version);          \
    template void A::serialize<oarchive>(oarchive & ar, const unsigned int file_version);

#define SERIALIZE_EXPORT_IMPL(A)                                                                   \
    static_assert(Common::SerializationCompat::Export::ExportKey<A>::value != nullptr,            \
                  "SERIALIZATION_CLASS_EXPORT_KEY must be declared for exported type");

#define DEBUG_SERIALIZATION_POINT                                                                  \
    do {                                                                                           \
        LOG_DEBUG(Savestate, "");                                                                  \
    } while (0)

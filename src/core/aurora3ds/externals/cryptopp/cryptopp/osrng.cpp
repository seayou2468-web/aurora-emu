// osrng.cpp - Aurora iOS-only RNG implementation.
#include "pch.h"
#include "config.h"
#include "osrng.h"
#include "rng.h"

#include <Security/SecRandom.h>

NAMESPACE_BEGIN(CryptoPP)

OS_RNG_Err::OS_RNG_Err(const std::string& operation)
    : Exception(OTHER_ERROR, "OS_Rng: " + operation + " operation failed") {
}

NonblockingRng::NonblockingRng() = default;
NonblockingRng::~NonblockingRng() = default;
BlockingRng::BlockingRng() = default;
BlockingRng::~BlockingRng() = default;

void NonblockingRng::GenerateBlock(byte* output, size_t size) {
    if (size == 0) return;
    if (SecRandomCopyBytes(kSecRandomDefault, size, output) != errSecSuccess) {
        throw OS_RNG_Err("SecRandomCopyBytes");
    }
}

void BlockingRng::GenerateBlock(byte* output, size_t size) {
    if (size == 0) return;
    if (SecRandomCopyBytes(kSecRandomDefault, size, output) != errSecSuccess) {
        throw OS_RNG_Err("SecRandomCopyBytes");
    }
}

void OS_GenerateRandomBlock(bool blocking, byte* output, size_t size) {
    if (blocking) {
        BlockingRng rng;
        rng.GenerateBlock(output, size);
        return;
    }

    NonblockingRng rng;
    rng.GenerateBlock(output, size);
}

void AutoSeededRandomPool::Reseed(bool blocking, unsigned int seedSize) {
    SecByteBlock seed(seedSize);
    OS_GenerateRandomBlock(blocking, seed, seedSize);
    IncorporateEntropy(seed, seedSize);
}

NAMESPACE_END

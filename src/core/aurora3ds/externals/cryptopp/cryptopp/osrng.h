// osrng.h - Aurora iOS-only RNG implementation surface.
#ifndef CRYPTOPP_OSRNG_H
#define CRYPTOPP_OSRNG_H

#include "config.h"
#include "cryptlib.h"
#include "randpool.h"
#include "rng.h"

NAMESPACE_BEGIN(CryptoPP)

class CRYPTOPP_DLL OS_RNG_Err : public Exception {
public:
    OS_RNG_Err(const std::string& operation);
};

class CRYPTOPP_DLL NonblockingRng : public RandomNumberGenerator {
public:
    CRYPTOPP_STATIC_CONSTEXPR const char* StaticAlgorithmName() { return "NonblockingRng"; }
    NonblockingRng();
    ~NonblockingRng();
    void GenerateBlock(byte* output, size_t size);
};

class CRYPTOPP_DLL BlockingRng : public RandomNumberGenerator {
public:
    CRYPTOPP_STATIC_CONSTEXPR const char* StaticAlgorithmName() { return "BlockingRng"; }
    BlockingRng();
    ~BlockingRng();
    void GenerateBlock(byte* output, size_t size);
};

CRYPTOPP_DLL void CRYPTOPP_API OS_GenerateRandomBlock(bool blocking, byte* output, size_t size);

class CRYPTOPP_DLL AutoSeededRandomPool : public RandomPool {
public:
    CRYPTOPP_STATIC_CONSTEXPR const char* StaticAlgorithmName() { return "AutoSeededRandomPool"; }
    ~AutoSeededRandomPool() {}
    explicit AutoSeededRandomPool(bool blocking = false, unsigned int seedSize = 32)
        {Reseed(blocking, seedSize);}
    void Reseed(bool blocking = false, unsigned int seedSize = 32);
};

NAMESPACE_END

#endif  // CRYPTOPP_OSRNG_H

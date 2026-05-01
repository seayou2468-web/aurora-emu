cmake_minimum_required(VERSION 3.20)
project(aurora LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(AURORA_BUILD_LINUX "Build aurora_linux frontend target" ON)

file(GLOB_RECURSE CORE_CPP CONFIGURE_DEPENDS src/core/*.cpp)
file(GLOB_RECURSE CORE_C CONFIGURE_DEPENDS src/core/*.c)

list(FILTER CORE_CPP EXCLUDE REGEX ".*/bridge_cores/.*")
list(FILTER CORE_CPP EXCLUDE REGEX ".*/teakra/tests/.*")
list(FILTER CORE_C EXCLUDE REGEX ".*/bridge_cores/.*")
list(FILTER CORE_C EXCLUDE REGEX ".*/teakra/tests/.*")

add_library(aurora_core STATIC
  ${CORE_CPP}
  ${CORE_C}
)

target_include_directories(aurora_core PUBLIC
  .
  Platforms/API
  src
  src/core/api
  src/core/module_cores
)

target_compile_options(aurora_core PRIVATE
  $<$<COMPILE_LANGUAGE:C>:-Wno-error>
  $<$<COMPILE_LANGUAGE:CXX>:-Wno-error>
)

if(AURORA_BUILD_LINUX)
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(SDL2 REQUIRED sdl2)

  add_executable(aurora_linux
    Platforms/linux/main.c
  )

  target_include_directories(aurora_linux PRIVATE
    .
    Platforms/API
    ${SDL2_INCLUDE_DIRS}
  )

  target_compile_options(aurora_linux PRIVATE
    $<$<COMPILE_LANGUAGE:C>:-Wno-error>
  )

  target_link_libraries(aurora_linux PRIVATE aurora_core ${SDL2_LIBRARIES} z)
endif()

option(AURORA_BUILD_IOS_APP "Build AuroraIOS .app via CMake/Xcode" OFF)

if(APPLE AND AURORA_BUILD_IOS_APP)
  enable_language(Swift)

  file(GLOB_RECURSE AURORA_IOS_SWIFT CONFIGURE_DEPENDS Platforms/AuroraIOS/swift/*.swift)
  file(GLOB_RECURSE AURORA_IOS_CORE_CPP CONFIGURE_DEPENDS src/core/*.cpp)
  file(GLOB_RECURSE AURORA_IOS_CORE_C CONFIGURE_DEPENDS src/core/*.c)

  list(FILTER AURORA_IOS_CORE_CPP EXCLUDE REGEX ".*/bridge_cores/.*")
  list(FILTER AURORA_IOS_CORE_CPP EXCLUDE REGEX ".*/teakra/tests/.*")
  list(FILTER AURORA_IOS_CORE_CPP EXCLUDE REGEX ".*/teakra/src/.*/main\\.cpp$")
  list(FILTER AURORA_IOS_CORE_CPP EXCLUDE REGEX ".*/teakra/src/test_generator\\.cpp$")
  list(FILTER AURORA_IOS_CORE_CPP EXCLUDE REGEX ".*/teakra/src/test_verifier/.*")
  list(FILTER AURORA_IOS_CORE_C EXCLUDE REGEX ".*/bridge_cores/.*")
  list(FILTER AURORA_IOS_CORE_C EXCLUDE REGEX ".*/teakra/tests/.*")

  add_executable(AuroraIOS MACOSX_BUNDLE
    ${AURORA_IOS_SWIFT}
    Platforms/API/AUREmulatorCoreAPI.h
    ${AURORA_IOS_CORE_CPP}
    ${AURORA_IOS_CORE_C}
  )

  target_include_directories(AuroraIOS PRIVATE
    .
    Platforms/API
    src
    src/core/api
    src/core/module_cores
  )

  set_target_properties(AuroraIOS PROPERTIES
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.frappev.rn"
    XCODE_ATTRIBUTE_SWIFT_VERSION "6.3"
    XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "26.0"
    XCODE_ATTRIBUTE_SWIFT_OBJC_BRIDGING_HEADER "Platforms/AuroraIOS/swift/Bridge/AuroraSwift-Bridging-Header.h"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO"
    XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
    XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
    XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "gnu++20"
    XCODE_ATTRIBUTE_OTHER_LDFLAGS "-lc++;-lz;-liconv"
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/Config/Info.plist"
    XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${CMAKE_SOURCE_DIR}/Config/Entitlements.plist"
  )
endif()

cmake_minimum_required(VERSION 3.20)
project(aurora LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(PkgConfig REQUIRED)
pkg_check_modules(SDL2 REQUIRED sdl2)

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

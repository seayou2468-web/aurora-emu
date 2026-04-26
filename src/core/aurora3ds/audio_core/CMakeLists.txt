add_library(audio_core STATIC
    audio_types.h
    codec.cpp
    codec.h
    dsp_interface.cpp
    dsp_interface.h
    hle/aac_decoder.cpp
    hle/aac_decoder.h
    hle/common.h
    hle/decoder.cpp
    hle/decoder.h
    hle/filter.cpp
    hle/filter.h
    hle/hle.cpp
    hle/hle.h
    hle/mixers.cpp
    hle/mixers.h
    hle/shared_memory.h
    hle/source.cpp
    hle/source.h
    lle/lle.cpp
    lle/lle.h
    input.h
    input_details.cpp
    input_details.h
    interpolate.cpp
    interpolate.h
    null_input.h
    null_sink.h
    precompiled_headers.h
    sink.h
    sink_details.cpp
    sink_details.h
    static_input.cpp
    static_input.h
    time_stretch.cpp
    time_stretch.h

    $<$<BOOL:${ENABLE_CUBEB}>:cubeb_sink.cpp cubeb_sink.h cubeb_input.cpp cubeb_input.h>
)

create_target_directory_groups(audio_core)

if (NOT TARGET teakra)
    add_library(teakra STATIC
        ../../melonds/teakra/src/ahbm.cpp
        ../../melonds/teakra/src/apbp.cpp
        ../../melonds/teakra/src/btdmp.cpp
        ../../melonds/teakra/src/disassembler.cpp
        ../../melonds/teakra/src/dma.cpp
        ../../melonds/teakra/src/memory_interface.cpp
        ../../melonds/teakra/src/mmio.cpp
        ../../melonds/teakra/src/parser.cpp
        ../../melonds/teakra/src/processor.cpp
        ../../melonds/teakra/src/teakra.cpp
        ../../melonds/teakra/src/timer.cpp
    )
    target_include_directories(teakra PUBLIC
        ../../melonds/teakra/include
    )
    target_include_directories(teakra PRIVATE
        ../../melonds/teakra/src
    )
endif()

target_link_libraries(audio_core PUBLIC citra_common citra_core)
target_link_libraries(audio_core PRIVATE faad2 teakra)

find_library(SOUNDTOUCH_LIBRARY NAMES SoundTouch soundtouch)
if (SOUNDTOUCH_LIBRARY)
    target_link_libraries(audio_core PRIVATE ${SOUNDTOUCH_LIBRARY})
endif()

if(ENABLE_CUBEB)
    target_link_libraries(audio_core PRIVATE cubeb)
    target_compile_definitions(audio_core PUBLIC HAVE_CUBEB)
endif()

if (CITRA_USE_PRECOMPILED_HEADERS)
    target_precompile_headers(audio_core PRIVATE precompiled_headers.h)
endif()

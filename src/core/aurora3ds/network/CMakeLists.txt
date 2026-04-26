add_library(network STATIC
    artic_base/artic_base_client.cpp
    artic_base/artic_base_client.h
    artic_base/artic_base_common.h
    network.cpp
    network.h
    network_settings.cpp
    network_settings.h
    packet.cpp
    packet.h
    precompiled_headers.h
    socket_manager.cpp
    socket_manager.h
    verify_user.cpp
    verify_user.h
)

create_target_directory_groups(network)

target_link_libraries(network PRIVATE citra_common enet httplib)

if (CITRA_USE_PRECOMPILED_HEADERS)
    target_precompile_headers(network PRIVATE precompiled_headers.h)
endif()

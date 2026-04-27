#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "../api/emulator_core_c_api.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum Aurora3DSROMFileType {
    AURORA3DS_ROM_FILE_TYPE_ERROR = 0,
    AURORA3DS_ROM_FILE_TYPE_UNKNOWN = 1,
    AURORA3DS_ROM_FILE_TYPE_CCI = 2,
    AURORA3DS_ROM_FILE_TYPE_CXI = 3,
    AURORA3DS_ROM_FILE_TYPE_CIA = 4,
    AURORA3DS_ROM_FILE_TYPE_ELF = 5,
    AURORA3DS_ROM_FILE_TYPE_3DSX = 6,
} Aurora3DSROMFileType;

typedef enum Aurora3DSROMLoaderStatus {
    AURORA3DS_ROM_LOADER_STATUS_SUCCESS = 0,
    AURORA3DS_ROM_LOADER_STATUS_ERROR = 1,
    AURORA3DS_ROM_LOADER_STATUS_INVALID_FORMAT = 2,
    AURORA3DS_ROM_LOADER_STATUS_NOT_IMPLEMENTED = 3,
    AURORA3DS_ROM_LOADER_STATUS_NOT_LOADED = 4,
    AURORA3DS_ROM_LOADER_STATUS_NOT_USED = 5,
    AURORA3DS_ROM_LOADER_STATUS_ALREADY_LOADED = 6,
    AURORA3DS_ROM_LOADER_STATUS_MEMORY_ALLOCATION_FAILED = 7,
    AURORA3DS_ROM_LOADER_STATUS_ENCRYPTED = 8,
    AURORA3DS_ROM_LOADER_STATUS_GBA_TITLE = 9,
    AURORA3DS_ROM_LOADER_STATUS_ARTIC = 10,
    AURORA3DS_ROM_LOADER_STATUS_NOT_FOUND = 11,
} Aurora3DSROMLoaderStatus;

typedef struct Aurora3DSROMProbeInfo {
    Aurora3DSROMFileType file_type;
    Aurora3DSROMLoaderStatus loader_status;
    uint64_t program_id;
    bool has_program_id;
    bool is_compressed;
} Aurora3DSROMProbeInfo;

void* Aurora3DSBridge_Create(void);
void Aurora3DSBridge_Destroy(void* runtime);
bool Aurora3DSBridge_LoadBIOSFromPath(void* runtime, const char* bios_path);
bool Aurora3DSBridge_LoadROMFromPath(void* runtime, const char* rom_path);
bool Aurora3DSBridge_ProbeROMFromPath(const char* rom_path, Aurora3DSROMProbeInfo* out_info);
bool Aurora3DSBridge_LoadROMFromMemory(void* runtime, const void* rom_data, size_t rom_size);
bool Aurora3DSBridge_StepFrame(void* runtime);
bool Aurora3DSBridge_SetRenderSurfaces(
    void* runtime,
    void* top_surface,
    void* bottom_surface,
    uint32_t top_width,
    uint32_t top_height,
    uint32_t bottom_width,
    uint32_t bottom_height,
    float render_surface_scale);
void Aurora3DSBridge_SetKeyStatus(void* runtime, int key, bool pressed);
bool Aurora3DSBridge_GetVideoSpec(void* runtime, EmulatorVideoSpec* out_spec);
const uint32_t* Aurora3DSBridge_GetFrameBufferRGBA(void* runtime, size_t* pixel_count);
bool Aurora3DSBridge_SaveStateToBuffer(void* runtime, void* out_buffer, size_t buffer_size, size_t* out_size);
bool Aurora3DSBridge_LoadStateFromBuffer(void* runtime, const void* state_buffer, size_t state_size);
bool Aurora3DSBridge_ApplyCheatCode(void* runtime, const char* cheat_code);
const char* Aurora3DSBridge_GetLastError(void* runtime);

// Canonical Aurora3DS C bridge symbols.
void* Aurora3DS_Create(void);
void Aurora3DS_Destroy(void* runtime);
bool Aurora3DS_LoadBIOSFromPath(void* runtime, const char* bios_path);
bool Aurora3DS_LoadROMFromPath(void* runtime, const char* rom_path);
bool Aurora3DS_ProbeROMFromPath(const char* rom_path, Aurora3DSROMProbeInfo* out_info);
bool Aurora3DS_LoadROMFromMemory(void* runtime, const void* rom_data, size_t rom_size);
bool Aurora3DS_StepFrame(void* runtime);
bool Aurora3DS_SetRenderSurfaces(
    void* runtime,
    void* top_surface,
    void* bottom_surface,
    uint32_t top_width,
    uint32_t top_height,
    uint32_t bottom_width,
    uint32_t bottom_height,
    float render_surface_scale);
void Aurora3DS_SetKeyStatus(void* runtime, int key, bool pressed);
bool Aurora3DS_GetVideoSpec(void* runtime, EmulatorVideoSpec* out_spec);
const uint32_t* Aurora3DS_GetFrameBufferRGBA(void* runtime, size_t* pixel_count);
bool Aurora3DS_SaveStateToBuffer(void* runtime, void* out_buffer, size_t buffer_size, size_t* out_size);
bool Aurora3DS_LoadStateFromBuffer(void* runtime, const void* state_buffer, size_t state_size);
bool Aurora3DS_ApplyCheatCode(void* runtime, const char* cheat_code);
const char* Aurora3DS_GetLastError(void* runtime);

#ifdef __cplusplus
}
#endif

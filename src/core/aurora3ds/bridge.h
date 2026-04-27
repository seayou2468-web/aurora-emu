#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "../api/emulator_core_c_api.h"

#ifdef __cplusplus
extern "C" {
#endif

void* Aurora3DSBridge_Create(void);
void Aurora3DSBridge_Destroy(void* runtime);
bool Aurora3DSBridge_LoadBIOSFromPath(void* runtime, const char* bios_path);
bool Aurora3DSBridge_LoadROMFromPath(void* runtime, const char* rom_path);
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

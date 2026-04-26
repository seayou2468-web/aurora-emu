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
void Aurora3DSBridge_SetKeyStatus(void* runtime, int key, bool pressed);
bool Aurora3DSBridge_GetVideoSpec(void* runtime, EmulatorVideoSpec* out_spec);
const uint32_t* Aurora3DSBridge_GetFrameBufferRGBA(void* runtime, size_t* pixel_count);
bool Aurora3DSBridge_SaveStateToBuffer(void* runtime, void* out_buffer, size_t buffer_size, size_t* out_size);
bool Aurora3DSBridge_LoadStateFromBuffer(void* runtime, const void* state_buffer, size_t state_size);
bool Aurora3DSBridge_ApplyCheatCode(void* runtime, const char* cheat_code);
const char* Aurora3DSBridge_GetLastError(void* runtime);

#ifdef __cplusplus
}
#endif

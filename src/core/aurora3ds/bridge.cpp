#include "./bridge.h"

extern "C" {

#if defined(__APPLE__)

void* Aurora3DS_Create(void) {
  return Aurora3DSBridge_Create();
}

void Aurora3DS_Destroy(void* runtime) {
  Aurora3DSBridge_Destroy(runtime);
}

bool Aurora3DS_LoadBIOSFromPath(void* runtime, const char* bios_path) {
  return Aurora3DSBridge_LoadBIOSFromPath(runtime, bios_path);
}

bool Aurora3DS_LoadROMFromPath(void* runtime, const char* rom_path) {
  return Aurora3DSBridge_LoadROMFromPath(runtime, rom_path);
}

bool Aurora3DS_LoadROMFromMemory(void* runtime, const void* rom_data, size_t rom_size) {
  return Aurora3DSBridge_LoadROMFromMemory(runtime, rom_data, rom_size);
}

bool Aurora3DS_StepFrame(void* runtime) {
  return Aurora3DSBridge_StepFrame(runtime);
}

void Aurora3DS_SetKeyStatus(void* runtime, int key, bool pressed) {
  Aurora3DSBridge_SetKeyStatus(runtime, key, pressed);
}

bool Aurora3DS_GetVideoSpec(void* runtime, EmulatorVideoSpec* out_spec) {
  return Aurora3DSBridge_GetVideoSpec(runtime, out_spec);
}

const uint32_t* Aurora3DS_GetFrameBufferRGBA(void* runtime, size_t* pixel_count) {
  return Aurora3DSBridge_GetFrameBufferRGBA(runtime, pixel_count);
}

bool Aurora3DS_SaveStateToBuffer(void* runtime, void* out_buffer, size_t buffer_size, size_t* out_size) {
  return Aurora3DSBridge_SaveStateToBuffer(runtime, out_buffer, buffer_size, out_size);
}

bool Aurora3DS_LoadStateFromBuffer(void* runtime, const void* state_buffer, size_t state_size) {
  return Aurora3DSBridge_LoadStateFromBuffer(runtime, state_buffer, state_size);
}

bool Aurora3DS_ApplyCheatCode(void* runtime, const char* cheat_code) {
  return Aurora3DSBridge_ApplyCheatCode(runtime, cheat_code);
}

const char* Aurora3DS_GetLastError(void* runtime) {
  return Aurora3DSBridge_GetLastError(runtime);
}

#else

void* Aurora3DS_Create(void) { return nullptr; }
void Aurora3DS_Destroy(void*) {}
bool Aurora3DS_LoadBIOSFromPath(void*, const char*) { return false; }
bool Aurora3DS_LoadROMFromPath(void*, const char*) { return false; }
bool Aurora3DS_LoadROMFromMemory(void*, const void*, size_t) { return false; }
bool Aurora3DS_StepFrame(void*) { return false; }
void Aurora3DS_SetKeyStatus(void*, int, bool) {}
bool Aurora3DS_GetVideoSpec(void*, EmulatorVideoSpec*) { return false; }
const uint32_t* Aurora3DS_GetFrameBufferRGBA(void*, size_t* pixel_count) {
  if (pixel_count) *pixel_count = 0;
  return nullptr;
}
bool Aurora3DS_SaveStateToBuffer(void*, void*, size_t, size_t*) { return false; }
bool Aurora3DS_LoadStateFromBuffer(void*, const void*, size_t) { return false; }
bool Aurora3DS_ApplyCheatCode(void*, const char*) { return false; }
const char* Aurora3DS_GetLastError(void*) { return "aurora3ds is only available on Apple targets"; }

#endif

}  // extern "C"

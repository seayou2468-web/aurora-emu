#include "./bridge.h"

#include <dlfcn.h>

#include <cstddef>
#include <cstdint>
#include <initializer_list>

namespace {

template <typename T>
T ResolveAny(const std::initializer_list<const char*> names) {
  for (const char* name : names) {
    if (void* sym = dlsym(RTLD_DEFAULT, name)) {
      return reinterpret_cast<T>(sym);
    }
  }
  return nullptr;
}

struct BridgeSymbols {
  void* (*create)() = nullptr;
  void (*destroy)(void*) = nullptr;
  bool (*load_bios_from_path)(void*, const char*) = nullptr;
  bool (*load_rom_from_path)(void*, const char*) = nullptr;
  bool (*load_rom_from_memory)(void*, const void*, size_t) = nullptr;
  bool (*step_frame)(void*) = nullptr;
  void (*set_key_status)(void*, int, bool) = nullptr;
  bool (*get_video_spec)(void*, EmulatorVideoSpec*) = nullptr;
  const uint32_t* (*get_frame_rgba)(void*, size_t*) = nullptr;
  bool (*save_state_to_buffer)(void*, void*, size_t, size_t*) = nullptr;
  bool (*load_state_from_buffer)(void*, const void*, size_t) = nullptr;
  bool (*apply_cheat_code)(void*, const char*) = nullptr;
  const char* (*get_last_error)(void*) = nullptr;
};

BridgeSymbols& Symbols() {
  static BridgeSymbols s;
  static bool initialized = false;
  if (!initialized) {
    initialized = true;
    s.create = ResolveAny<void* (*)()>({"Aurora3DSBridge_Create", "aurora3ds_bridge_create"});
    s.destroy = ResolveAny<void (*)(void*)>({"Aurora3DSBridge_Destroy", "aurora3ds_bridge_destroy"});
    s.load_bios_from_path = ResolveAny<bool (*)(void*, const char*)>({
        "Aurora3DSBridge_LoadBIOSFromPath", "aurora3ds_bridge_load_bios_from_path"});
    s.load_rom_from_path = ResolveAny<bool (*)(void*, const char*)>({
        "Aurora3DSBridge_LoadROMFromPath", "aurora3ds_bridge_load_rom_from_path"});
    s.load_rom_from_memory = ResolveAny<bool (*)(void*, const void*, size_t)>({
        "Aurora3DSBridge_LoadROMFromMemory", "aurora3ds_bridge_load_rom_from_memory"});
    s.step_frame = ResolveAny<bool (*)(void*)>({"Aurora3DSBridge_StepFrame", "aurora3ds_bridge_step_frame"});
    s.set_key_status = ResolveAny<void (*)(void*, int, bool)>({
        "Aurora3DSBridge_SetKeyStatus", "aurora3ds_bridge_set_key_status"});
    s.get_video_spec = ResolveAny<bool (*)(void*, EmulatorVideoSpec*)>({
        "Aurora3DSBridge_GetVideoSpec", "aurora3ds_bridge_get_video_spec"});
    s.get_frame_rgba = ResolveAny<const uint32_t* (*)(void*, size_t*)>({
        "Aurora3DSBridge_GetFrameBufferRGBA", "aurora3ds_bridge_get_framebuffer_rgba"});
    s.save_state_to_buffer = ResolveAny<bool (*)(void*, void*, size_t, size_t*)>({
        "Aurora3DSBridge_SaveStateToBuffer", "aurora3ds_bridge_save_state_to_buffer"});
    s.load_state_from_buffer = ResolveAny<bool (*)(void*, const void*, size_t)>({
        "Aurora3DSBridge_LoadStateFromBuffer", "aurora3ds_bridge_load_state_from_buffer"});
    s.apply_cheat_code = ResolveAny<bool (*)(void*, const char*)>({
        "Aurora3DSBridge_ApplyCheatCode", "aurora3ds_bridge_apply_cheat_code"});
    s.get_last_error = ResolveAny<const char* (*)(void*)>({
        "Aurora3DSBridge_GetLastError", "aurora3ds_bridge_get_last_error"});
  }
  return s;
}

const char* MissingBridgeError() {
  return "aurora3ds bridge symbols are missing";
}

}  // namespace

extern "C" {

void* Aurora3DS_Create(void) {
  auto& s = Symbols();
  return s.create ? s.create() : nullptr;
}

void Aurora3DS_Destroy(void* runtime) {
  auto& s = Symbols();
  if (s.destroy) s.destroy(runtime);
}

bool Aurora3DS_LoadBIOSFromPath(void* runtime, const char* bios_path) {
  auto& s = Symbols();
  return s.load_bios_from_path ? s.load_bios_from_path(runtime, bios_path) : false;
}

bool Aurora3DS_LoadROMFromPath(void* runtime, const char* rom_path) {
  auto& s = Symbols();
  return s.load_rom_from_path ? s.load_rom_from_path(runtime, rom_path) : false;
}

bool Aurora3DS_LoadROMFromMemory(void* runtime, const void* rom_data, size_t rom_size) {
  auto& s = Symbols();
  return s.load_rom_from_memory ? s.load_rom_from_memory(runtime, rom_data, rom_size) : false;
}

bool Aurora3DS_StepFrame(void* runtime) {
  auto& s = Symbols();
  return s.step_frame ? s.step_frame(runtime) : false;
}

void Aurora3DS_SetKeyStatus(void* runtime, int key, bool pressed) {
  auto& s = Symbols();
  if (s.set_key_status) s.set_key_status(runtime, key, pressed);
}

bool Aurora3DS_GetVideoSpec(void* runtime, EmulatorVideoSpec* out_spec) {
  auto& s = Symbols();
  return s.get_video_spec ? s.get_video_spec(runtime, out_spec) : false;
}

const uint32_t* Aurora3DS_GetFrameBufferRGBA(void* runtime, size_t* pixel_count) {
  auto& s = Symbols();
  if (pixel_count) *pixel_count = 0;
  return s.get_frame_rgba ? s.get_frame_rgba(runtime, pixel_count) : nullptr;
}

bool Aurora3DS_SaveStateToBuffer(void* runtime, void* out_buffer, size_t buffer_size, size_t* out_size) {
  auto& s = Symbols();
  return s.save_state_to_buffer ? s.save_state_to_buffer(runtime, out_buffer, buffer_size, out_size) : false;
}

bool Aurora3DS_LoadStateFromBuffer(void* runtime, const void* state_buffer, size_t state_size) {
  auto& s = Symbols();
  return s.load_state_from_buffer ? s.load_state_from_buffer(runtime, state_buffer, state_size) : false;
}

bool Aurora3DS_ApplyCheatCode(void* runtime, const char* cheat_code) {
  auto& s = Symbols();
  return s.apply_cheat_code ? s.apply_cheat_code(runtime, cheat_code) : false;
}

const char* Aurora3DS_GetLastError(void* runtime) {
  auto& s = Symbols();
  if (s.get_last_error) return s.get_last_error(runtime);
  return MissingBridgeError();
}

}  // extern "C"

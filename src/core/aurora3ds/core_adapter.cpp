#include "../core_adapter.hpp"

#include "bridge.h"

#include <string>

namespace {

struct Aurora3DSRuntime {
  void* bridge_runtime = nullptr;
};

const char* LastBridgeError(Aurora3DSRuntime* runtime) {
  if (!runtime || !runtime->bridge_runtime) return nullptr;
  return Aurora3DSBridge_GetLastError(runtime->bridge_runtime);
}

void SetBridgeError(Aurora3DSRuntime* runtime, std::string& last_error, const char* fallback) {
  const char* bridge_error = LastBridgeError(runtime);
  last_error = (bridge_error && bridge_error[0] != '\0') ? bridge_error : fallback;
}

void* CreateRuntime() {
  auto* runtime = new Aurora3DSRuntime();
  runtime->bridge_runtime = Aurora3DSBridge_Create();
  if (!runtime->bridge_runtime) {
    delete runtime;
    return nullptr;
  }
  return runtime;
}

void DestroyRuntime(void* runtime_ptr) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime) return;
  if (runtime->bridge_runtime) {
    Aurora3DSBridge_Destroy(runtime->bridge_runtime);
  }
  delete runtime;
}

bool LoadBIOSFromPath(void* runtime_ptr, const char* bios_path, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->bridge_runtime || !Aurora3DSBridge_LoadBIOSFromPath(runtime->bridge_runtime, bios_path)) {
    SetBridgeError(runtime, last_error, "aurora3ds BIOS load failed");
    return false;
  }
  return true;
}

bool LoadROMFromPath(void* runtime_ptr, const char* rom_path, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->bridge_runtime || !Aurora3DSBridge_LoadROMFromPath(runtime->bridge_runtime, rom_path)) {
    SetBridgeError(runtime, last_error, "aurora3ds ROM load failed");
    return false;
  }
  return true;
}

bool LoadROMFromMemory(void* runtime_ptr, const void* rom_data, size_t rom_size, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->bridge_runtime ||
      !Aurora3DSBridge_LoadROMFromMemory(runtime->bridge_runtime, rom_data, rom_size)) {
    SetBridgeError(runtime, last_error, "aurora3ds ROM memory load failed");
    return false;
  }
  return true;
}

void StepFrame(void* runtime_ptr, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->bridge_runtime || !Aurora3DSBridge_StepFrame(runtime->bridge_runtime)) {
    SetBridgeError(runtime, last_error, "aurora3ds frame step failed");
  }
}

void SetKeyStatus(void* runtime_ptr, int key, bool pressed) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->bridge_runtime) return;
  Aurora3DSBridge_SetKeyStatus(runtime->bridge_runtime, key, pressed);
}

const uint32_t* GetFrameBufferRGBA(void* runtime_ptr, size_t* pixel_count) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (pixel_count) *pixel_count = 0;
  if (!runtime || !runtime->bridge_runtime) return nullptr;
  return Aurora3DSBridge_GetFrameBufferRGBA(runtime->bridge_runtime, pixel_count);
}

bool SaveStateToBuffer(void* runtime_ptr, void* out_buffer, size_t buffer_size, size_t* out_size, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->bridge_runtime ||
      !Aurora3DSBridge_SaveStateToBuffer(runtime->bridge_runtime, out_buffer, buffer_size, out_size)) {
    SetBridgeError(runtime, last_error, "aurora3ds save state failed");
    return false;
  }
  return true;
}

bool LoadStateFromBuffer(void* runtime_ptr, const void* state_buffer, size_t state_size, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->bridge_runtime ||
      !Aurora3DSBridge_LoadStateFromBuffer(runtime->bridge_runtime, state_buffer, state_size)) {
    SetBridgeError(runtime, last_error, "aurora3ds load state failed");
    return false;
  }
  return true;
}

bool ApplyCheatCode(void* runtime_ptr, const char* cheat_code, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->bridge_runtime || !Aurora3DSBridge_ApplyCheatCode(runtime->bridge_runtime, cheat_code)) {
    SetBridgeError(runtime, last_error, "aurora3ds cheat apply failed");
    return false;
  }
  return true;
}

bool GetVideoSpec(EmulatorVideoSpec* out_spec) {
  return Aurora3DSBridge_GetVideoSpec(nullptr, out_spec);
}

}  // namespace

namespace core {

extern const CoreAdapter kAurora3DSAdapter = {
    .name = "aurora3ds",
    .type = EMULATOR_CORE_TYPE_3DS,
    .create_runtime = CreateRuntime,
    .destroy_runtime = DestroyRuntime,
    .load_bios_from_path = LoadBIOSFromPath,
    .load_rom_from_path = LoadROMFromPath,
    .load_rom_from_memory = LoadROMFromMemory,
    .step_frame = StepFrame,
    .set_key_status = SetKeyStatus,
    .get_video_spec = GetVideoSpec,
    .get_framebuffer_rgba = GetFrameBufferRGBA,
    .save_state_to_buffer = SaveStateToBuffer,
    .load_state_from_buffer = LoadStateFromBuffer,
    .apply_cheat_code = ApplyCheatCode,
};

}  // namespace core

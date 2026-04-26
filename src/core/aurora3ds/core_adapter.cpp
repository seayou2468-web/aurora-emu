#include "../core_adapter.hpp"

#include <cstddef>
#include <cstdint>
#include <dlfcn.h>
#include <string>

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

struct Aurora3DSBridgeSymbols {
  void* (*create)() = nullptr;
  void (*destroy)(void*) = nullptr;
  bool (*load_bios_from_path)(void*, const char*) = nullptr;
  bool (*load_rom_from_path)(void*, const char*) = nullptr;
  bool (*load_rom_from_memory)(void*, const void*, size_t) = nullptr;
  bool (*step_frame)(void*) = nullptr;
  void (*set_key_status)(void*, int, bool) = nullptr;
  const uint32_t* (*get_frame_rgba)(void*, size_t*) = nullptr;
  bool (*save_state_to_buffer)(void*, void*, size_t, size_t*) = nullptr;
  bool (*load_state_from_buffer)(void*, const void*, size_t) = nullptr;
  bool (*apply_cheat_code)(void*, const char*) = nullptr;
  const char* (*get_last_error)(void*) = nullptr;
};

Aurora3DSBridgeSymbols& BridgeSymbols() {
  static Aurora3DSBridgeSymbols symbols;
  static bool initialized = false;
  if (!initialized) {
    initialized = true;

    symbols.create = ResolveAny<void* (*)()>({
        "Aurora3DSBridge_Create", "Aurora3DS_Create", "aurora3ds_bridge_create"});
    symbols.destroy = ResolveAny<void (*)(void*)>({
        "Aurora3DSBridge_Destroy", "Aurora3DS_Destroy", "aurora3ds_bridge_destroy"});
    symbols.load_bios_from_path = ResolveAny<bool (*)(void*, const char*)>({
        "Aurora3DSBridge_LoadBIOSFromPath", "Aurora3DS_LoadBIOSFromPath", "aurora3ds_bridge_load_bios_from_path"});
    symbols.load_rom_from_path = ResolveAny<bool (*)(void*, const char*)>({
        "Aurora3DSBridge_LoadROMFromPath", "Aurora3DS_LoadROMFromPath", "aurora3ds_bridge_load_rom_from_path"});
    symbols.load_rom_from_memory = ResolveAny<bool (*)(void*, const void*, size_t)>({
        "Aurora3DSBridge_LoadROMFromMemory", "Aurora3DS_LoadROMFromMemory", "aurora3ds_bridge_load_rom_from_memory"});
    symbols.step_frame = ResolveAny<bool (*)(void*)>({
        "Aurora3DSBridge_StepFrame", "Aurora3DS_StepFrame", "aurora3ds_bridge_step_frame"});
    symbols.set_key_status = ResolveAny<void (*)(void*, int, bool)>({
        "Aurora3DSBridge_SetKeyStatus", "Aurora3DS_SetKeyStatus", "aurora3ds_bridge_set_key_status"});
    symbols.get_frame_rgba = ResolveAny<const uint32_t* (*)(void*, size_t*)>({
        "Aurora3DSBridge_GetFrameBufferRGBA", "Aurora3DS_GetFrameBufferRGBA", "aurora3ds_bridge_get_framebuffer_rgba"});
    symbols.save_state_to_buffer = ResolveAny<bool (*)(void*, void*, size_t, size_t*)>({
        "Aurora3DSBridge_SaveStateToBuffer", "Aurora3DS_SaveStateToBuffer", "aurora3ds_bridge_save_state_to_buffer"});
    symbols.load_state_from_buffer = ResolveAny<bool (*)(void*, const void*, size_t)>({
        "Aurora3DSBridge_LoadStateFromBuffer", "Aurora3DS_LoadStateFromBuffer", "aurora3ds_bridge_load_state_from_buffer"});
    symbols.apply_cheat_code = ResolveAny<bool (*)(void*, const char*)>({
        "Aurora3DSBridge_ApplyCheatCode", "Aurora3DS_ApplyCheatCode", "aurora3ds_bridge_apply_cheat_code"});
    symbols.get_last_error = ResolveAny<const char* (*)(void*)>({
        "Aurora3DSBridge_GetLastError", "Aurora3DS_GetLastError", "aurora3ds_bridge_get_last_error"});
  }
  return symbols;
}

bool BridgeReady() {
  const auto& b = BridgeSymbols();
  return b.create && b.destroy && b.load_rom_from_path && b.load_rom_from_memory &&
         b.step_frame && b.set_key_status && b.get_frame_rgba;
}

struct Aurora3DSRuntime {
  void* backend = nullptr;
};

void SetBridgeMissingError(std::string& last_error) {
  last_error = "aurora3ds backend bridge is not linked";
}

void SetBackendError(const Aurora3DSRuntime* runtime, std::string& last_error) {
  const auto& bridge = BridgeSymbols();
  if (runtime && runtime->backend && bridge.get_last_error) {
    const char* err = bridge.get_last_error(runtime->backend);
    if (err && err[0] != '\0') {
      last_error = err;
      return;
    }
  }
  last_error = "aurora3ds backend operation failed";
}

void* CreateRuntime() {
  const auto& bridge = BridgeSymbols();
  if (!BridgeReady()) {
    return nullptr;
  }

  auto* runtime = new Aurora3DSRuntime();
  runtime->backend = bridge.create();
  if (!runtime->backend) {
    delete runtime;
    return nullptr;
  }
  return runtime;
}

void DestroyRuntime(void* runtime_ptr) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime) return;
  const auto& bridge = BridgeSymbols();
  if (runtime->backend && bridge.destroy) {
    bridge.destroy(runtime->backend);
  }
  delete runtime;
}

bool LoadBIOSFromPath(void* runtime_ptr, const char* bios_path, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime || !runtime->backend || !bridge.load_bios_from_path) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (bridge.load_bios_from_path(runtime->backend, bios_path)) return true;
  SetBackendError(runtime, last_error);
  return false;
}

bool LoadROMFromPath(void* runtime_ptr, const char* rom_path, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime || !runtime->backend || !bridge.load_rom_from_path) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (bridge.load_rom_from_path(runtime->backend, rom_path)) return true;
  SetBackendError(runtime, last_error);
  return false;
}

bool LoadROMFromMemory(void* runtime_ptr, const void* rom_data, size_t rom_size, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime || !runtime->backend || !bridge.load_rom_from_memory) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (bridge.load_rom_from_memory(runtime->backend, rom_data, rom_size)) return true;
  SetBackendError(runtime, last_error);
  return false;
}

void StepFrame(void* runtime_ptr, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime || !runtime->backend || !bridge.step_frame) {
    SetBridgeMissingError(last_error);
    return;
  }
  if (!bridge.step_frame(runtime->backend)) {
    SetBackendError(runtime, last_error);
  }
}

void SetKeyStatus(void* runtime_ptr, int key, bool pressed) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime || !runtime->backend || !bridge.set_key_status) return;
  bridge.set_key_status(runtime->backend, key, pressed);
}

const uint32_t* GetFrameBufferRGBA(void* runtime_ptr, size_t* pixel_count) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (pixel_count) *pixel_count = 0;
  if (!runtime || !runtime->backend || !bridge.get_frame_rgba) return nullptr;
  return bridge.get_frame_rgba(runtime->backend, pixel_count);
}

bool SaveStateToBuffer(void* runtime_ptr, void* out_buffer, size_t buffer_size, size_t* out_size, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime || !runtime->backend || !bridge.save_state_to_buffer) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (bridge.save_state_to_buffer(runtime->backend, out_buffer, buffer_size, out_size)) return true;
  SetBackendError(runtime, last_error);
  return false;
}

bool LoadStateFromBuffer(void* runtime_ptr, const void* state_buffer, size_t state_size, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime || !runtime->backend || !bridge.load_state_from_buffer) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (bridge.load_state_from_buffer(runtime->backend, state_buffer, state_size)) return true;
  SetBackendError(runtime, last_error);
  return false;
}

bool ApplyCheatCode(void* runtime_ptr, const char* cheat_code, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime || !runtime->backend || !bridge.apply_cheat_code) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (bridge.apply_cheat_code(runtime->backend, cheat_code)) return true;
  SetBackendError(runtime, last_error);
  return false;
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
    .get_video_spec = [](EmulatorVideoSpec* out_spec) -> bool {
      if (!out_spec) return false;
      out_spec->width = 400;
      out_spec->height = 480;
      out_spec->pixel_format = EMULATOR_PIXEL_FORMAT_RGBA8888;
      return true;
    },
    .get_framebuffer_rgba = GetFrameBufferRGBA,
    .save_state_to_buffer = SaveStateToBuffer,
    .load_state_from_buffer = LoadStateFromBuffer,
    .apply_cheat_code = ApplyCheatCode,
};

}  // namespace core

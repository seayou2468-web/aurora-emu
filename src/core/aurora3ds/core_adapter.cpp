#include "../core_adapter.hpp"
#include "./bridge.h"

#include <cstddef>
#include <cstdint>
#include <string>

namespace {

struct Aurora3DSRuntime {
  void* backend = nullptr;
};

void SetBridgeMissingError(std::string& last_error) {
  last_error = "aurora3ds backend bridge is not linked";
}

void SetBackendError(const Aurora3DSRuntime* runtime, std::string& last_error) {
  if (runtime && runtime->backend) {
    const char* err = Aurora3DS_GetLastError(runtime->backend);
    if (err && err[0] != '\0') {
      last_error = err;
      return;
    }
  }
  last_error = "aurora3ds backend operation failed";
}

void* CreateRuntime() {
  auto* runtime = new Aurora3DSRuntime();
  runtime->backend = Aurora3DS_Create();
  return runtime;
}

void DestroyRuntime(void* runtime_ptr) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime) return;
  if (runtime->backend) {
    Aurora3DS_Destroy(runtime->backend);
  }
  delete runtime;
}

bool LoadBIOSFromPath(void* runtime_ptr, const char* bios_path, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->backend) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (Aurora3DS_LoadBIOSFromPath(runtime->backend, bios_path)) return true;
  SetBackendError(runtime, last_error);
  return false;
}

bool LoadROMFromPath(void* runtime_ptr, const char* rom_path, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->backend) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (Aurora3DS_LoadROMFromPath(runtime->backend, rom_path)) return true;
  SetBackendError(runtime, last_error);
  return false;
}

bool LoadROMFromMemory(void* runtime_ptr, const void* rom_data, size_t rom_size, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->backend) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (Aurora3DS_LoadROMFromMemory(runtime->backend, rom_data, rom_size)) return true;
  SetBackendError(runtime, last_error);
  return false;
}

void StepFrame(void* runtime_ptr, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->backend) {
    SetBridgeMissingError(last_error);
    return;
  }
  if (!Aurora3DS_StepFrame(runtime->backend)) {
    SetBackendError(runtime, last_error);
  }
}

void SetKeyStatus(void* runtime_ptr, int key, bool pressed) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->backend) return;
  Aurora3DS_SetKeyStatus(runtime->backend, key, pressed);
}

bool SetRenderSurfaces(
    void* runtime_ptr,
    void* top_surface,
    void* bottom_surface,
    uint32_t top_width,
    uint32_t top_height,
    uint32_t bottom_width,
    uint32_t bottom_height,
    float render_surface_scale,
    std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->backend) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (Aurora3DS_SetRenderSurfaces(
          runtime->backend,
          top_surface,
          bottom_surface,
          top_width,
          top_height,
          bottom_width,
          bottom_height,
          render_surface_scale)) {
    return true;
  }
  SetBackendError(runtime, last_error);
  return false;
}

const uint32_t* GetFrameBufferRGBA(void* runtime_ptr, size_t* pixel_count) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (pixel_count) *pixel_count = 0;
  if (!runtime || !runtime->backend) return nullptr;
  return Aurora3DS_GetFrameBufferRGBA(runtime->backend, pixel_count);
}

bool SaveStateToBuffer(void* runtime_ptr, void* out_buffer, size_t buffer_size, size_t* out_size, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->backend) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (Aurora3DS_SaveStateToBuffer(runtime->backend, out_buffer, buffer_size, out_size)) return true;
  SetBackendError(runtime, last_error);
  return false;
}

bool LoadStateFromBuffer(void* runtime_ptr, const void* state_buffer, size_t state_size, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->backend) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (Aurora3DS_LoadStateFromBuffer(runtime->backend, state_buffer, state_size)) return true;
  SetBackendError(runtime, last_error);
  return false;
}

bool ApplyCheatCode(void* runtime_ptr, const char* cheat_code, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime || !runtime->backend) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (Aurora3DS_ApplyCheatCode(runtime->backend, cheat_code)) return true;
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
    .set_render_surfaces = SetRenderSurfaces,
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

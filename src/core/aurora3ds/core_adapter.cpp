#include "../core_adapter.hpp"

#include <cstddef>
#include <cstdint>
#include <cstring>
#include <dlfcn.h>
#include <string>
#include <vector>

namespace {

struct Aurora3DSBridgeSymbols {
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

Aurora3DSBridgeSymbols& BridgeSymbols() {
  static Aurora3DSBridgeSymbols symbols;
  static bool initialized = false;
  if (!initialized) {
    initialized = true;
    symbols.create = reinterpret_cast<void* (*)()>(dlsym(RTLD_DEFAULT, "Aurora3DSBridge_Create"));
    symbols.destroy = reinterpret_cast<void (*)(void*)>(dlsym(RTLD_DEFAULT, "Aurora3DSBridge_Destroy"));
    symbols.load_bios_from_path = reinterpret_cast<bool (*)(void*, const char*)>(
        dlsym(RTLD_DEFAULT, "Aurora3DSBridge_LoadBIOSFromPath"));
    symbols.load_rom_from_path = reinterpret_cast<bool (*)(void*, const char*)>(
        dlsym(RTLD_DEFAULT, "Aurora3DSBridge_LoadROMFromPath"));
    symbols.load_rom_from_memory = reinterpret_cast<bool (*)(void*, const void*, size_t)>(
        dlsym(RTLD_DEFAULT, "Aurora3DSBridge_LoadROMFromMemory"));
    symbols.step_frame = reinterpret_cast<bool (*)(void*)>(dlsym(RTLD_DEFAULT, "Aurora3DSBridge_StepFrame"));
    symbols.set_key_status = reinterpret_cast<void (*)(void*, int, bool)>(
        dlsym(RTLD_DEFAULT, "Aurora3DSBridge_SetKeyStatus"));
    symbols.get_video_spec = reinterpret_cast<bool (*)(void*, EmulatorVideoSpec*)>(
        dlsym(RTLD_DEFAULT, "Aurora3DSBridge_GetVideoSpec"));
    symbols.get_frame_rgba = reinterpret_cast<const uint32_t* (*)(void*, size_t*)>(
        dlsym(RTLD_DEFAULT, "Aurora3DSBridge_GetFrameBufferRGBA"));
    symbols.save_state_to_buffer = reinterpret_cast<bool (*)(void*, void*, size_t, size_t*)>(
        dlsym(RTLD_DEFAULT, "Aurora3DSBridge_SaveStateToBuffer"));
    symbols.load_state_from_buffer = reinterpret_cast<bool (*)(void*, const void*, size_t)>(
        dlsym(RTLD_DEFAULT, "Aurora3DSBridge_LoadStateFromBuffer"));
    symbols.apply_cheat_code = reinterpret_cast<bool (*)(void*, const char*)>(
        dlsym(RTLD_DEFAULT, "Aurora3DSBridge_ApplyCheatCode"));
    symbols.get_last_error = reinterpret_cast<const char* (*)(void*)>(
        dlsym(RTLD_DEFAULT, "Aurora3DSBridge_GetLastError"));
  }
  return symbols;
}

struct Aurora3DSRuntime {
  void* backend = nullptr;
  bool fallback = false;
  bool rom_loaded = false;
  uint64_t frame_counter = 0;
  uint32_t key_mask = 0;
  std::vector<uint32_t> framebuffer = std::vector<uint32_t>(400U * 480U, 0xFF000000U);
};

void SetBridgeMissingError(std::string& last_error) {
  last_error = "aurora3ds backend bridge is not linked (using fallback renderer)";
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
  auto* runtime = new Aurora3DSRuntime();
  if (bridge.create && bridge.destroy) {
    runtime->backend = bridge.create();
  }
  if (!runtime->backend) {
    runtime->fallback = true;
  }
  return runtime;
}

void DestroyRuntime(void* runtime_ptr) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  if (!runtime) {
    return;
  }

  const auto& bridge = BridgeSymbols();
  if (!runtime->fallback && runtime->backend && bridge.destroy) {
    bridge.destroy(runtime->backend);
  }
  delete runtime;
}

bool LoadBIOSFromPath(void* runtime_ptr, const char* bios_path, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (runtime->fallback) {
    return true;
  }
  if (!runtime->backend || !bridge.load_bios_from_path) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (bridge.load_bios_from_path(runtime->backend, bios_path)) {
    return true;
  }
  SetBackendError(runtime, last_error);
  return false;
}

bool LoadROMFromPath(void* runtime_ptr, const char* rom_path, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (runtime->fallback) {
    runtime->rom_loaded = true;
    runtime->frame_counter = 0;
    runtime->key_mask = 0;
    return true;
  }
  if (!runtime->backend || !bridge.load_rom_from_path) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (bridge.load_rom_from_path(runtime->backend, rom_path)) {
    return true;
  }
  SetBackendError(runtime, last_error);
  return false;
}

bool LoadROMFromMemory(void* runtime_ptr, const void* rom_data, size_t rom_size, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (runtime->fallback) {
    runtime->rom_loaded = (rom_data != nullptr && rom_size > 0);
    runtime->frame_counter = 0;
    runtime->key_mask = 0;
    return runtime->rom_loaded;
  }
  if (!runtime->backend || !bridge.load_rom_from_memory) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (bridge.load_rom_from_memory(runtime->backend, rom_data, rom_size)) {
    return true;
  }
  SetBackendError(runtime, last_error);
  return false;
}

void StepFrame(void* runtime_ptr, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime) {
    SetBridgeMissingError(last_error);
    return;
  }
  if (runtime->fallback) {
    if (!runtime->rom_loaded) {
      last_error = "fallback renderer has no ROM loaded";
      return;
    }
    ++runtime->frame_counter;
    const uint8_t phase = static_cast<uint8_t>((runtime->frame_counter * 2U) & 0xFFU);
    constexpr uint32_t w = 400U;
    constexpr uint32_t topH = 240U;
    constexpr uint32_t bottomW = 320U;
    constexpr uint32_t bottomH = 240U;
    constexpr uint32_t xOffset = (w - bottomW) / 2U;
    for (uint32_t y = 0; y < topH; ++y) {
      for (uint32_t x = 0; x < w; ++x) {
        const uint8_t r = static_cast<uint8_t>((x + phase) & 0xFFU);
        const uint8_t g = static_cast<uint8_t>((y + phase) & 0xFFU);
        const uint8_t b = static_cast<uint8_t>((runtime->key_mask * 19U) & 0xFFU);
        runtime->framebuffer[static_cast<size_t>(y) * w + x] =
            0xFF000000U | (static_cast<uint32_t>(r) << 16U) |
            (static_cast<uint32_t>(g) << 8U) | static_cast<uint32_t>(b);
      }
    }
    for (uint32_t y = 0; y < bottomH; ++y) {
      const uint32_t dstY = y + topH;
      for (uint32_t x = 0; x < w; ++x) {
        uint32_t color = 0xFF101010U;
        if (x >= xOffset && x < (xOffset + bottomW)) {
          const uint8_t r = static_cast<uint8_t>((x - xOffset) * 255U / bottomW);
          const uint8_t g = static_cast<uint8_t>(y * 255U / bottomH);
          const uint8_t b = static_cast<uint8_t>((phase + 64U) & 0xFFU);
          color = 0xFF000000U | (static_cast<uint32_t>(r) << 16U) |
                  (static_cast<uint32_t>(g) << 8U) | static_cast<uint32_t>(b);
        }
        runtime->framebuffer[static_cast<size_t>(dstY) * w + x] = color;
      }
    }
    return;
  }
  if (!runtime->backend || !bridge.step_frame) {
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
  if (!runtime) {
    return;
  }
  if (runtime->fallback) {
    const uint32_t bit = (key >= 0 && key < 31) ? (1U << static_cast<uint32_t>(key)) : 0U;
    if (pressed) runtime->key_mask |= bit;
    else runtime->key_mask &= ~bit;
    return;
  }
  if (!runtime->backend || !bridge.set_key_status) {
    return;
  }
  bridge.set_key_status(runtime->backend, key, pressed);
}

const uint32_t* GetFrameBufferRGBA(void* runtime_ptr, size_t* pixel_count) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (pixel_count) {
    *pixel_count = 0;
  }
  if (!runtime) {
    return nullptr;
  }
  if (runtime->fallback) {
    if (pixel_count) *pixel_count = runtime->framebuffer.size();
    return runtime->rom_loaded ? runtime->framebuffer.data() : nullptr;
  }
  if (!runtime->backend || !bridge.get_frame_rgba) {
    return nullptr;
  }
  return bridge.get_frame_rgba(runtime->backend, pixel_count);
}

bool SaveStateToBuffer(void* runtime_ptr, void* out_buffer, size_t buffer_size, size_t* out_size, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (runtime->fallback) {
    struct Save { uint64_t frame_counter; uint32_t key_mask; } payload{runtime->frame_counter, runtime->key_mask};
    if (out_size) *out_size = sizeof(payload);
    if (!out_buffer) return true;
    if (buffer_size < sizeof(payload)) {
      last_error = "fallback savestate buffer too small";
      return false;
    }
    std::memcpy(out_buffer, &payload, sizeof(payload));
    return true;
  }
  if (!runtime->backend || !bridge.save_state_to_buffer) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (bridge.save_state_to_buffer(runtime->backend, out_buffer, buffer_size, out_size)) {
    return true;
  }
  SetBackendError(runtime, last_error);
  return false;
}

bool LoadStateFromBuffer(void* runtime_ptr, const void* state_buffer, size_t state_size, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (runtime->fallback) {
    struct Save { uint64_t frame_counter; uint32_t key_mask; } payload{};
    if (!state_buffer || state_size < sizeof(payload)) {
      last_error = "fallback savestate payload invalid";
      return false;
    }
    std::memcpy(&payload, state_buffer, sizeof(payload));
    runtime->frame_counter = payload.frame_counter;
    runtime->key_mask = payload.key_mask;
    return true;
  }
  if (!runtime->backend || !bridge.load_state_from_buffer) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (bridge.load_state_from_buffer(runtime->backend, state_buffer, state_size)) {
    return true;
  }
  SetBackendError(runtime, last_error);
  return false;
}

bool ApplyCheatCode(void* runtime_ptr, const char* cheat_code, std::string& last_error) {
  auto* runtime = static_cast<Aurora3DSRuntime*>(runtime_ptr);
  const auto& bridge = BridgeSymbols();
  if (!runtime) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (runtime->fallback) {
    last_error = "fallback renderer does not implement cheats";
    return false;
  }
  if (!runtime->backend || !bridge.apply_cheat_code) {
    SetBridgeMissingError(last_error);
    return false;
  }
  if (bridge.apply_cheat_code(runtime->backend, cheat_code)) {
    return true;
  }
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
      // Default/fallback spec for callers that query before ROM load.
      if (!out_spec) {
        return false;
      }
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

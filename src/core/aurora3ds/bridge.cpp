#include "bridge.h"

#include <cstring>
#include <fstream>
#include <string>
#include <vector>

namespace {

constexpr uint32_t kTopWidth = 400U;
constexpr uint32_t kTopHeight = 240U;
constexpr uint32_t kBottomWidth = 320U;
constexpr uint32_t kBottomHeight = 240U;
constexpr uint32_t kFrameWidth = 400U;
constexpr uint32_t kFrameHeight = 480U;

struct Runtime {
  bool rom_loaded = false;
  uint64_t frame_counter = 0;
  uint32_t key_mask = 0;
  std::vector<uint32_t> framebuffer = std::vector<uint32_t>(kFrameWidth * kFrameHeight, 0xFF000000U);
  std::string last_error;
};

Runtime* AsRuntime(void* ptr) {
  return static_cast<Runtime*>(ptr);
}

}  // namespace

extern "C" {

void* Aurora3DSBridge_Create(void) {
  return new Runtime();
}

void Aurora3DSBridge_Destroy(void* runtime) {
  delete AsRuntime(runtime);
}

bool Aurora3DSBridge_LoadBIOSFromPath(void* runtime, const char* bios_path) {
  Runtime* rt = AsRuntime(runtime);
  if (!rt) return false;
  if (!bios_path || bios_path[0] == '\0') return true;
  std::ifstream f(bios_path, std::ios::binary);
  if (!f) {
    rt->last_error = "BIOS path is not readable";
    return false;
  }
  return true;
}

bool Aurora3DSBridge_LoadROMFromPath(void* runtime, const char* rom_path) {
  Runtime* rt = AsRuntime(runtime);
  if (!rt || !rom_path || rom_path[0] == '\0') return false;
  std::ifstream f(rom_path, std::ios::binary);
  if (!f) {
    rt->last_error = "ROM path is not readable";
    return false;
  }
  rt->rom_loaded = true;
  rt->frame_counter = 0;
  rt->key_mask = 0;
  rt->last_error.clear();
  return true;
}

bool Aurora3DSBridge_LoadROMFromMemory(void* runtime, const void* rom_data, size_t rom_size) {
  Runtime* rt = AsRuntime(runtime);
  if (!rt || !rom_data || rom_size == 0) return false;
  rt->rom_loaded = true;
  rt->frame_counter = 0;
  rt->key_mask = 0;
  rt->last_error.clear();
  return true;
}

bool Aurora3DSBridge_StepFrame(void* runtime) {
  Runtime* rt = AsRuntime(runtime);
  if (!rt || !rt->rom_loaded) {
    if (rt) rt->last_error = "ROM is not loaded";
    return false;
  }

  ++rt->frame_counter;
  const uint8_t phase = static_cast<uint8_t>((rt->frame_counter * 2U) & 0xFFU);
  constexpr uint32_t xOffset = (kTopWidth - kBottomWidth) / 2U;

  for (uint32_t y = 0; y < kTopHeight; ++y) {
    for (uint32_t x = 0; x < kTopWidth; ++x) {
      const uint8_t r = static_cast<uint8_t>((x + phase) & 0xFFU);
      const uint8_t g = static_cast<uint8_t>((y + phase) & 0xFFU);
      const uint8_t b = static_cast<uint8_t>((rt->key_mask * 11U) & 0xFFU);
      rt->framebuffer[static_cast<size_t>(y) * kFrameWidth + x] =
          0xFF000000U | (static_cast<uint32_t>(r) << 16U) | (static_cast<uint32_t>(g) << 8U) | b;
    }
  }

  for (uint32_t y = 0; y < kBottomHeight; ++y) {
    const uint32_t dstY = y + kTopHeight;
    for (uint32_t x = 0; x < kFrameWidth; ++x) {
      uint32_t color = 0xFF101010U;
      if (x >= xOffset && x < xOffset + kBottomWidth) {
        const uint32_t localX = x - xOffset;
        const uint8_t r = static_cast<uint8_t>((localX * 255U) / kBottomWidth);
        const uint8_t g = static_cast<uint8_t>((y * 255U) / kBottomHeight);
        const uint8_t b = static_cast<uint8_t>((phase + 64U) & 0xFFU);
        color = 0xFF000000U | (static_cast<uint32_t>(r) << 16U) | (static_cast<uint32_t>(g) << 8U) | b;
      }
      rt->framebuffer[static_cast<size_t>(dstY) * kFrameWidth + x] = color;
    }
  }

  return true;
}

void Aurora3DSBridge_SetKeyStatus(void* runtime, int key, bool pressed) {
  Runtime* rt = AsRuntime(runtime);
  if (!rt || key < 0 || key > 31) return;
  const uint32_t bit = (1U << static_cast<uint32_t>(key));
  if (pressed) rt->key_mask |= bit;
  else rt->key_mask &= ~bit;
}

bool Aurora3DSBridge_GetVideoSpec(void* runtime, EmulatorVideoSpec* out_spec) {
  (void)runtime;
  if (!out_spec) return false;
  out_spec->width = kFrameWidth;
  out_spec->height = kFrameHeight;
  out_spec->pixel_format = EMULATOR_PIXEL_FORMAT_RGBA8888;
  return true;
}

const uint32_t* Aurora3DSBridge_GetFrameBufferRGBA(void* runtime, size_t* pixel_count) {
  Runtime* rt = AsRuntime(runtime);
  if (pixel_count) *pixel_count = 0;
  if (!rt || !rt->rom_loaded) return nullptr;
  if (pixel_count) *pixel_count = rt->framebuffer.size();
  return rt->framebuffer.data();
}

bool Aurora3DSBridge_SaveStateToBuffer(void* runtime, void* out_buffer, size_t buffer_size, size_t* out_size) {
  Runtime* rt = AsRuntime(runtime);
  if (!rt || !rt->rom_loaded) return false;
  struct Save { uint64_t frame_counter; uint32_t key_mask; } payload{rt->frame_counter, rt->key_mask};
  if (out_size) *out_size = sizeof(payload);
  if (!out_buffer) return true;
  if (buffer_size < sizeof(payload)) return false;
  std::memcpy(out_buffer, &payload, sizeof(payload));
  return true;
}

bool Aurora3DSBridge_LoadStateFromBuffer(void* runtime, const void* state_buffer, size_t state_size) {
  Runtime* rt = AsRuntime(runtime);
  if (!rt || !state_buffer || state_size < sizeof(uint64_t) + sizeof(uint32_t)) return false;
  struct Save { uint64_t frame_counter; uint32_t key_mask; } payload{};
  std::memcpy(&payload, state_buffer, sizeof(payload));
  rt->frame_counter = payload.frame_counter;
  rt->key_mask = payload.key_mask;
  return true;
}

bool Aurora3DSBridge_ApplyCheatCode(void* runtime, const char* cheat_code) {
  Runtime* rt = AsRuntime(runtime);
  if (rt) rt->last_error = "cheat is not implemented";
  (void)cheat_code;
  return false;
}

const char* Aurora3DSBridge_GetLastError(void* runtime) {
  Runtime* rt = AsRuntime(runtime);
  if (!rt || rt->last_error.empty()) return nullptr;
  return rt->last_error.c_str();
}

}  // extern "C"

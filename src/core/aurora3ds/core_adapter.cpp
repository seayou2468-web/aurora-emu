#include "../core_adapter.hpp"

#include <array>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <vector>

#include <string>

namespace {

constexpr uint32_t kTopWidth = 400U;
constexpr uint32_t kTopHeight = 240U;
constexpr uint32_t kBottomWidth = 320U;
constexpr uint32_t kBottomHeight = 240U;
constexpr uint32_t kFrameWidth = kTopWidth;
constexpr uint32_t kFrameHeight = kTopHeight + kBottomHeight;
constexpr size_t kPixelCount = static_cast<size_t>(kFrameWidth) * static_cast<size_t>(kFrameHeight);

struct Aurora3DSRuntime {
  bool rom_loaded = false;
  uint64_t frame_counter = 0;
  uint32_t key_mask = 0;
  std::vector<uint8_t> rom_bytes;
  std::vector<uint32_t> framebuffer = std::vector<uint32_t>(kPixelCount, 0xFF000000U);
};

void* CreateRuntime() {
  return new Aurora3DSRuntime();
}

void DestroyRuntime(void* runtime) {
  delete static_cast<Aurora3DSRuntime*>(runtime);
}

bool NotReady(std::string& last_error) {
  last_error = "aurora3ds core backend is unavailable";
  return false;
}

bool LoadBIOSFromPath(void* runtime, const char* bios_path, std::string& last_error) {
  (void)last_error;
  auto* state = static_cast<Aurora3DSRuntime*>(runtime);
  if (!state) {
    return false;
  }
  if (bios_path == nullptr || bios_path[0] == '\0') {
    return true;
  }
  std::ifstream file(bios_path, std::ios::binary);
  if (!file) {
    last_error = "aurora3ds BIOS path is not readable";
    return false;
  }
  return true;
}

bool LoadROMFromPath(void* runtime, const char* rom_path, std::string& last_error) {
  auto* state = static_cast<Aurora3DSRuntime*>(runtime);
  if (!state || rom_path == nullptr || rom_path[0] == '\0') {
    last_error = "aurora3ds ROM path is empty";
    return false;
  }

  std::ifstream file(rom_path, std::ios::binary | std::ios::ate);
  if (!file) {
    last_error = "aurora3ds ROM path is not readable";
    return false;
  }

  const std::streamsize size = file.tellg();
  if (size <= 0) {
    last_error = "aurora3ds ROM file is empty";
    return false;
  }
  file.seekg(0, std::ios::beg);
  state->rom_bytes.assign(static_cast<size_t>(size), 0);
  if (!file.read(reinterpret_cast<char*>(state->rom_bytes.data()), size)) {
    state->rom_bytes.clear();
    last_error = "aurora3ds ROM read failed";
    return false;
  }

  state->rom_loaded = true;
  state->frame_counter = 0;
  state->key_mask = 0;
  return true;
}

bool LoadROMFromMemory(void* runtime, const void* rom_data, size_t rom_size, std::string& last_error) {
  auto* state = static_cast<Aurora3DSRuntime*>(runtime);
  if (!state || rom_data == nullptr || rom_size == 0) {
    last_error = "aurora3ds ROM buffer is empty";
    return false;
  }
  const auto* bytes = static_cast<const uint8_t*>(rom_data);
  state->rom_bytes.assign(bytes, bytes + rom_size);
  state->rom_loaded = true;
  state->frame_counter = 0;
  state->key_mask = 0;
  return true;
}

void StepFrame(void* runtime, std::string& last_error) {
  auto* state = static_cast<Aurora3DSRuntime*>(runtime);
  if (!state || !state->rom_loaded) {
    last_error = "aurora3ds ROM is not loaded";
    return;
  }

  ++state->frame_counter;
  const uint8_t phase = static_cast<uint8_t>((state->frame_counter * 2U) & 0xFFU);

  for (uint32_t y = 0; y < kTopHeight; ++y) {
    for (uint32_t x = 0; x < kTopWidth; ++x) {
      const uint8_t r = static_cast<uint8_t>((x + phase) & 0xFFU);
      const uint8_t g = static_cast<uint8_t>((y + phase) & 0xFFU);
      const uint8_t b = static_cast<uint8_t>((state->key_mask * 13U) & 0xFFU);
      state->framebuffer[static_cast<size_t>(y) * kFrameWidth + x] =
          0xFF000000U | (static_cast<uint32_t>(r) << 16U) | (static_cast<uint32_t>(g) << 8U) |
          static_cast<uint32_t>(b);
    }
  }

  // Draw bottom screen centered (320x240) into a 400x240 region.
  constexpr uint32_t xOffset = (kTopWidth - kBottomWidth) / 2U;
  for (uint32_t y = 0; y < kBottomHeight; ++y) {
    const uint32_t dstY = y + kTopHeight;
    for (uint32_t x = 0; x < kFrameWidth; ++x) {
      uint32_t color = 0xFF101010U;
      if (x >= xOffset && x < xOffset + kBottomWidth) {
        const uint32_t localX = x - xOffset;
        const uint8_t r = static_cast<uint8_t>((localX * 255U) / kBottomWidth);
        const uint8_t g = static_cast<uint8_t>((y * 255U) / kBottomHeight);
        const uint8_t b = static_cast<uint8_t>((phase + 64U) & 0xFFU);
        color = 0xFF000000U | (static_cast<uint32_t>(r) << 16U) | (static_cast<uint32_t>(g) << 8U) |
                static_cast<uint32_t>(b);
      }
      state->framebuffer[static_cast<size_t>(dstY) * kFrameWidth + x] = color;
    }
  }
}

void SetKeyStatus(void* runtime, int key, bool pressed) {
  auto* state = static_cast<Aurora3DSRuntime*>(runtime);
  if (!state || key < 0 || key > 31) {
    return;
  }
  const uint32_t bit = 1U << static_cast<uint32_t>(key);
  if (pressed) {
    state->key_mask |= bit;
  } else {
    state->key_mask &= ~bit;
  }
}

bool GetVideoSpec(EmulatorVideoSpec* out_spec) {
  if (!out_spec) {
    return false;
  }
  out_spec->width = 400;
  out_spec->height = 480;
  out_spec->pixel_format = EMULATOR_PIXEL_FORMAT_RGBA8888;
  return true;
}

const uint32_t* GetFrameBufferRGBA(void* runtime, size_t* pixel_count) {
  auto* state = static_cast<Aurora3DSRuntime*>(runtime);
  if (pixel_count) {
    *pixel_count = state ? state->framebuffer.size() : 0;
  }
  if (!state || !state->rom_loaded) {
    return nullptr;
  }
  return state->framebuffer.data();
}

bool SaveStateToBuffer(void* runtime, void* out_buffer, size_t buffer_size, size_t* out_size, std::string& last_error) {
  auto* state = static_cast<Aurora3DSRuntime*>(runtime);
  if (!state || !state->rom_loaded) {
    last_error = "aurora3ds ROM is not loaded";
    return false;
  }

  struct SaveStatePayload {
    uint64_t frame_counter;
    uint32_t key_mask;
  } payload{state->frame_counter, state->key_mask};

  if (out_size) {
    *out_size = sizeof(payload);
  }
  if (out_buffer == nullptr) {
    return true;
  }
  if (buffer_size < sizeof(payload)) {
    last_error = "aurora3ds savestate buffer is too small";
    return false;
  }
  std::memcpy(out_buffer, &payload, sizeof(payload));
  return true;
}

bool LoadStateFromBuffer(void* runtime, const void* state_buffer, size_t state_size, std::string& last_error) {
  auto* state = static_cast<Aurora3DSRuntime*>(runtime);
  if (!state || !state->rom_loaded) {
    last_error = "aurora3ds ROM is not loaded";
    return false;
  }
  if (state_buffer == nullptr || state_size < sizeof(uint64_t) + sizeof(uint32_t)) {
    last_error = "aurora3ds savestate payload is invalid";
    return false;
  }

  struct SaveStatePayload {
    uint64_t frame_counter;
    uint32_t key_mask;
  } payload{};
  std::memcpy(&payload, state_buffer, sizeof(payload));
  state->frame_counter = payload.frame_counter;
  state->key_mask = payload.key_mask;
  return true;
}

bool ApplyCheatCode(void* runtime, const char* cheat_code, std::string& last_error) {
  (void)runtime;
  (void)cheat_code;
  return NotReady(last_error);
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

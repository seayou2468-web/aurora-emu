#include "./bridge.h"

#include <string>
#include <mutex>
#include <vector>

#if defined(__APPLE__) && __has_include(<boost/optional.hpp>) && \
    __has_include(<boost/serialization/version.hpp>)
#define AURORA3DS_EMBEDDED_CORE_AVAILABLE 1
#else
#define AURORA3DS_EMBEDDED_CORE_AVAILABLE 0
#endif

#if AURORA3DS_EMBEDDED_CORE_AVAILABLE
#include "./Core/include/core/core.h"
#include "./Core/include/core/dumping/backend.h"
#include "./Core/include/core/frontend/emu_window.h"
#include "./Core/include/core/frontend/framebuffer_layout.h"
#endif

extern "C" {

#if AURORA3DS_EMBEDDED_CORE_AVAILABLE

namespace {

class AURBridgeEmuWindow final : public Frontend::EmuWindow {
public:
  AURBridgeEmuWindow() : Frontend::EmuWindow(false) {
    window_info.type = Frontend::WindowSystemType::Headless;
    window_info.display_connection = nullptr;
    window_info.render_surface = nullptr;
    window_info.render_surface_scale = 1.0f;
    NotifyFramebufferLayoutChanged(Layout::DefaultFrameLayout(400, 480, false, false));
  }

  void PollEvents() override {}
};

struct AURBridgeRuntime {
  Core::System* system = nullptr;
  std::unique_ptr<AURBridgeEmuWindow> window;
  std::shared_ptr<class AURBridgeCaptureBackend> capture;
  std::vector<uint32_t> frame_rgba;
  std::string last_error;
};

class AURBridgeCaptureBackend final : public VideoDumper::Backend {
public:
  bool StartDumping(const std::string&, const Layout::FramebufferLayout& layout) override {
    std::scoped_lock lk(mu);
    dumping = true;
    fb_layout = layout;
    rgb.clear();
    return true;
  }

  void AddVideoFrame(VideoDumper::VideoFrame frame) override {
    std::scoped_lock lk(mu);
    rgb = std::move(frame.data);
  }

  void AddAudioFrame(AudioCore::StereoFrame16) override {}
  void AddAudioSample(const std::array<s16, 2>&) override {}

  void StopDumping() override {
    std::scoped_lock lk(mu);
    dumping = false;
  }

  bool IsDumping() const override { return dumping; }
  Layout::FramebufferLayout GetLayout() const override { return fb_layout; }

  bool CopyLatestRGBA(std::vector<uint32_t>& out) {
    std::scoped_lock lk(mu);
    if (rgb.empty()) return false;
    const size_t px = rgb.size() / 3;
    out.resize(px);
    for (size_t i = 0; i < px; ++i) {
      const uint8_t r = rgb[i * 3 + 0];
      const uint8_t g = rgb[i * 3 + 1];
      const uint8_t b = rgb[i * 3 + 2];
      out[i] = 0xFF000000u | (uint32_t(r) << 16) | (uint32_t(g) << 8) | uint32_t(b);
    }
    return true;
  }

private:
  mutable std::mutex mu;
  std::vector<uint8_t> rgb;
  Layout::FramebufferLayout fb_layout{};
  bool dumping = false;
};

const char* ToStatusString(Core::System::ResultStatus status) {
  switch (status) {
    case Core::System::ResultStatus::Success: return "success";
    case Core::System::ResultStatus::ErrorNotInitialized: return "not initialized";
    case Core::System::ResultStatus::ErrorGetLoader: return "loader not found";
    case Core::System::ResultStatus::ErrorSystemMode: return "system mode error";
    case Core::System::ResultStatus::ErrorLoader: return "loader error";
    case Core::System::ResultStatus::ErrorLoader_ErrorEncrypted: return "encrypted rom";
    case Core::System::ResultStatus::ErrorLoader_ErrorInvalidFormat: return "invalid rom format";
    case Core::System::ResultStatus::ErrorLoader_ErrorGbaTitle: return "gba title";
    case Core::System::ResultStatus::ErrorSystemFiles: return "system files missing";
    case Core::System::ResultStatus::ErrorSavestate: return "savestate error";
    case Core::System::ResultStatus::ShutdownRequested: return "shutdown requested";
    case Core::System::ResultStatus::ErrorUnknown: return "unknown error";
  }
  return "unknown error";
}

AURBridgeRuntime* AsRuntime(void* runtime) {
  return static_cast<AURBridgeRuntime*>(runtime);
}

}  // namespace

void* Aurora3DSBridge_Create(void) {
  auto* runtime = new AURBridgeRuntime();
  runtime->system = &Core::System::GetInstance();
  runtime->window = std::make_unique<AURBridgeEmuWindow>();
  runtime->capture = std::make_shared<AURBridgeCaptureBackend>();
  runtime->system->RegisterVideoDumper(runtime->capture);
  runtime->capture->StartDumping("", runtime->window->GetFramebufferLayout());
  return runtime;
}

void Aurora3DSBridge_Destroy(void* runtime_ptr) {
  auto* runtime = AsRuntime(runtime_ptr);
  if (!runtime) return;
  if (runtime->system && runtime->system->IsPoweredOn()) {
    runtime->system->Shutdown();
  }
  delete runtime;
}

bool Aurora3DSBridge_LoadBIOSFromPath(void*, const char*) {
  return true;
}

bool Aurora3DSBridge_LoadROMFromPath(void* runtime_ptr, const char* rom_path) {
  auto* runtime = AsRuntime(runtime_ptr);
  if (!runtime || !runtime->system || !runtime->window || !rom_path) return false;
  const auto status = runtime->system->Load(*runtime->window, std::string(rom_path));
  runtime->last_error = ToStatusString(status);
  return status == Core::System::ResultStatus::Success;
}

bool Aurora3DSBridge_LoadROMFromMemory(void*, const void*, size_t) {
  return false;
}

bool Aurora3DSBridge_StepFrame(void* runtime_ptr) {
  auto* runtime = AsRuntime(runtime_ptr);
  if (!runtime || !runtime->system) return false;
  const auto status = runtime->system->RunLoop(true);
  runtime->last_error = ToStatusString(status);
  runtime->capture->CopyLatestRGBA(runtime->frame_rgba);
  return status == Core::System::ResultStatus::Success ||
         status == Core::System::ResultStatus::ShutdownRequested;
}

void Aurora3DSBridge_SetKeyStatus(void*, int, bool) {}

bool Aurora3DSBridge_GetVideoSpec(void*, EmulatorVideoSpec* out_spec) {
  if (!out_spec) return false;
  out_spec->width = 400;
  out_spec->height = 480;
  out_spec->pixel_format = EMULATOR_PIXEL_FORMAT_RGBA8888;
  return true;
}

const uint32_t* Aurora3DSBridge_GetFrameBufferRGBA(void* runtime_ptr, size_t* pixel_count) {
  auto* runtime = AsRuntime(runtime_ptr);
  if (pixel_count) *pixel_count = 0;
  if (!runtime || runtime->frame_rgba.empty()) return nullptr;
  if (pixel_count) *pixel_count = runtime->frame_rgba.size();
  return runtime->frame_rgba.data();
}

bool Aurora3DSBridge_SaveStateToBuffer(void*, void*, size_t, size_t*) { return false; }
bool Aurora3DSBridge_LoadStateFromBuffer(void*, const void*, size_t) { return false; }
bool Aurora3DSBridge_ApplyCheatCode(void*, const char*) { return false; }

const char* Aurora3DSBridge_GetLastError(void* runtime_ptr) {
  auto* runtime = AsRuntime(runtime_ptr);
  if (!runtime) return "invalid runtime";
  return runtime->last_error.c_str();
}

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
const char* Aurora3DS_GetLastError(void*) {
#if defined(__APPLE__)
  return "aurora3ds embedded dependencies are missing (boost headers)";
#else
  return "aurora3ds is only available on Apple targets";
#endif
}

#endif

}  // extern "C"

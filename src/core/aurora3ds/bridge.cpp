#include "./bridge.h"

#include <string>
#include <mutex>
#include <memory>
#include <sstream>
#include <vector>

#if defined(__APPLE__)
#include <dlfcn.h>
#include "./Core/include/common/dynamic_library/dynamic_library.h"
#include "./Core/include/common/file_util.h"
#include "./Core/include/core/core.h"
#include "./Core/include/core/dumping/backend.h"
#include "./Core/include/core/frontend/emu_window.h"
#include "./Core/include/core/frontend/applets/default_applets.h"
#include "./Core/include/core/frontend/framebuffer_layout.h"
#include "./Core/include/core/loader/loader.h"
#include "./Core/include/common/logging/backend.h"
#include "./Core/include/common/logging/filter.h"
#include "./Core/include/common/settings.h"
#include "./Core/include/network/network.h"
#include "./CitraObjC/Camera/CameraFactory.h"
#include "./CitraObjC/Configuration/Configuration.h"
#include "./CitraObjC/EmulationWindow/GraphicsContext_Apple.h"
#include "./CitraObjC/InputManager/InputManager.h"
#endif

extern "C" {

#if defined(__APPLE__)

namespace {

class AURBridgeVulkanWindow final : public Frontend::EmuWindow {
public:
  AURBridgeVulkanWindow(void* render_surface, float render_surface_scale,
                        std::shared_ptr<Common::DynamicLibrary> driver_library)
      : Frontend::EmuWindow(false), driver_library_(std::move(driver_library)) {
    window_info.type = Frontend::WindowSystemType::MacOS;
    window_info.display_connection = nullptr;
    window_info.render_surface = render_surface;
    window_info.render_surface_scale = render_surface_scale;
    NotifyFramebufferLayoutChanged(Layout::DefaultFrameLayout(400, 480, false, false));
  }

  void PollEvents() override {}

  std::unique_ptr<Frontend::GraphicsContext> CreateSharedContext() const override {
    if (!driver_library_ || !driver_library_->IsLoaded()) {
      return nullptr;
    }
    return std::make_unique<GraphicsContext_Apple>(driver_library_);
  }

  void UpdateRenderSurface(void* render_surface, float render_surface_scale) {
    window_info.type = Frontend::WindowSystemType::MacOS;
    window_info.render_surface = render_surface;
    window_info.render_surface_scale = render_surface_scale;
  }

private:
  std::shared_ptr<Common::DynamicLibrary> driver_library_;
};

struct AURBridgeRuntime {
  Core::System* system = nullptr;
  std::unique_ptr<AURBridgeVulkanWindow> window;
  std::shared_ptr<class AURBridgeCaptureBackend> capture;
  std::shared_ptr<Common::DynamicLibrary> moltenvk_library;
  std::unique_ptr<Configuration> configuration;
  void* top_surface = nullptr;
  void* bottom_surface = nullptr;
  float render_surface_scale = 1.0f;
  std::vector<uint32_t> frame_rgba;
  size_t no_frame_counter = 0;
  Loader::FileType loader_file_type = Loader::FileType::Unknown;
  Loader::ResultStatus loader_status = Loader::ResultStatus::ErrorNotLoaded;
  u64 loader_program_id = 0;
  bool loader_program_id_valid = false;
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

const char* ToLoaderStatusString(Loader::ResultStatus status) {
  switch (status) {
    case Loader::ResultStatus::Success: return "success";
    case Loader::ResultStatus::Error: return "error";
    case Loader::ResultStatus::ErrorInvalidFormat: return "invalid format";
    case Loader::ResultStatus::ErrorNotImplemented: return "not implemented";
    case Loader::ResultStatus::ErrorNotLoaded: return "not loaded";
    case Loader::ResultStatus::ErrorNotUsed: return "not used";
    case Loader::ResultStatus::ErrorAlreadyLoaded: return "already loaded";
    case Loader::ResultStatus::ErrorMemoryAllocationFailed: return "memory allocation failed";
    case Loader::ResultStatus::ErrorEncrypted: return "encrypted";
    case Loader::ResultStatus::ErrorGbaTitle: return "gba title";
    case Loader::ResultStatus::ErrorArtic: return "artic";
    case Loader::ResultStatus::ErrorNotFound: return "not found";
  }
  return "unknown";
}

Aurora3DSROMFileType ToBridgeFileType(Loader::FileType type) {
  switch (type) {
    case Loader::FileType::CCI: return AURORA3DS_ROM_FILE_TYPE_CCI;
    case Loader::FileType::CXI: return AURORA3DS_ROM_FILE_TYPE_CXI;
    case Loader::FileType::CIA: return AURORA3DS_ROM_FILE_TYPE_CIA;
    case Loader::FileType::ELF: return AURORA3DS_ROM_FILE_TYPE_ELF;
    case Loader::FileType::THREEDSX: return AURORA3DS_ROM_FILE_TYPE_3DSX;
    case Loader::FileType::Error: return AURORA3DS_ROM_FILE_TYPE_ERROR;
    case Loader::FileType::Unknown: return AURORA3DS_ROM_FILE_TYPE_UNKNOWN;
  }
  return AURORA3DS_ROM_FILE_TYPE_UNKNOWN;
}

Aurora3DSROMLoaderStatus ToBridgeLoaderStatus(Loader::ResultStatus status) {
  switch (status) {
    case Loader::ResultStatus::Success: return AURORA3DS_ROM_LOADER_STATUS_SUCCESS;
    case Loader::ResultStatus::Error: return AURORA3DS_ROM_LOADER_STATUS_ERROR;
    case Loader::ResultStatus::ErrorInvalidFormat: return AURORA3DS_ROM_LOADER_STATUS_INVALID_FORMAT;
    case Loader::ResultStatus::ErrorNotImplemented: return AURORA3DS_ROM_LOADER_STATUS_NOT_IMPLEMENTED;
    case Loader::ResultStatus::ErrorNotLoaded: return AURORA3DS_ROM_LOADER_STATUS_NOT_LOADED;
    case Loader::ResultStatus::ErrorNotUsed: return AURORA3DS_ROM_LOADER_STATUS_NOT_USED;
    case Loader::ResultStatus::ErrorAlreadyLoaded: return AURORA3DS_ROM_LOADER_STATUS_ALREADY_LOADED;
    case Loader::ResultStatus::ErrorMemoryAllocationFailed:
      return AURORA3DS_ROM_LOADER_STATUS_MEMORY_ALLOCATION_FAILED;
    case Loader::ResultStatus::ErrorEncrypted: return AURORA3DS_ROM_LOADER_STATUS_ENCRYPTED;
    case Loader::ResultStatus::ErrorGbaTitle: return AURORA3DS_ROM_LOADER_STATUS_GBA_TITLE;
    case Loader::ResultStatus::ErrorArtic: return AURORA3DS_ROM_LOADER_STATUS_ARTIC;
    case Loader::ResultStatus::ErrorNotFound: return AURORA3DS_ROM_LOADER_STATUS_NOT_FOUND;
  }
  return AURORA3DS_ROM_LOADER_STATUS_ERROR;
}

AURBridgeRuntime* AsRuntime(void* runtime) {
  return static_cast<AURBridgeRuntime*>(runtime);
}

}  // namespace

void* Aurora3DSBridge_Create(void) {
  static bool logging_initialized = false;
  if (!logging_initialized) {
    Common::Log::Initialize();
    Common::Log::SetColorConsoleBackendEnabled(false);
    Common::Log::Start();
    Common::Log::Filter filter;
    filter.ParseFilterString(Settings::values.log_filter.GetValue());
    Common::Log::SetGlobalFilter(filter);
    logging_initialized = true;
  }

  auto* runtime = new AURBridgeRuntime();
  runtime->system = &Core::System::GetInstance();
  runtime->configuration = std::make_unique<Configuration>();
  runtime->system->ApplySettings();
  runtime->moltenvk_library =
      std::make_shared<Common::DynamicLibrary>(dlopen("@rpath/MoltenVK.framework/MoltenVK", RTLD_NOW));

  auto front_camera = std::make_unique<Camera::iOSFrontCameraFactory>();
  auto rear_camera = std::make_unique<Camera::iOSRearCameraFactory>();
  Camera::RegisterFactory("av_front", std::move(front_camera));
  Camera::RegisterFactory("av_rear", std::move(rear_camera));

  InputManager::Init();
  Network::Init();
  Frontend::RegisterDefaultApplets(*runtime->system);

  runtime->window = std::make_unique<AURBridgeVulkanWindow>(
      runtime->top_surface, runtime->render_surface_scale, runtime->moltenvk_library);
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
  Network::Shutdown();
  InputManager::Shutdown();
  delete runtime;
}

bool Aurora3DSBridge_LoadBIOSFromPath(void*, const char*) {
  return true;
}

bool Aurora3DSBridge_LoadROMFromPath(void* runtime_ptr, const char* rom_path) {
  auto* runtime = AsRuntime(runtime_ptr);
  if (!runtime || !runtime->system || !runtime->window || !rom_path) return false;
  FileUtil::SetCurrentRomPath(std::string(rom_path));
  auto app_loader = Loader::GetLoader(std::string(rom_path));
  if (!app_loader) {
    runtime->loader_file_type = Loader::FileType::Unknown;
    runtime->loader_status = Loader::ResultStatus::ErrorNotFound;
    runtime->loader_program_id_valid = false;
    runtime->last_error = "loader not found";
    return false;
  }

  runtime->loader_file_type = app_loader->GetFileType();
  runtime->loader_status = Loader::ResultStatus::Success;
  runtime->loader_program_id = 0;
  runtime->loader_program_id_valid =
      app_loader->ReadProgramId(runtime->loader_program_id) == Loader::ResultStatus::Success;

  runtime->system->ApplySettings();
  Settings::LogSettings();
  const auto status = runtime->system->Load(*runtime->window, std::string(rom_path));
  if (status == Core::System::ResultStatus::Success) {
    runtime->last_error.clear();
  } else {
    std::ostringstream loader_info;
    loader_info << "loader="
                << Loader::GetFileTypeString(runtime->loader_file_type, app_loader->IsFileCompressed())
                << ",status=" << ToLoaderStatusString(runtime->loader_status);
    if (runtime->loader_program_id_valid) {
      loader_info << ",program_id=0x" << std::hex << runtime->loader_program_id;
    }
    runtime->last_error = std::string(ToStatusString(status)) + " (" + loader_info.str() + ")";
  }
  return status == Core::System::ResultStatus::Success;
}

bool Aurora3DSBridge_ProbeROMFromPath(const char* rom_path, Aurora3DSROMProbeInfo* out_info) {
  if (!rom_path || !out_info) return false;
  out_info->file_type = AURORA3DS_ROM_FILE_TYPE_UNKNOWN;
  out_info->loader_status = AURORA3DS_ROM_LOADER_STATUS_ERROR;
  out_info->program_id = 0;
  out_info->has_program_id = false;
  out_info->is_compressed = false;

  auto app_loader = Loader::GetLoader(std::string(rom_path));
  if (!app_loader) {
    out_info->loader_status = AURORA3DS_ROM_LOADER_STATUS_NOT_FOUND;
    return false;
  }

  out_info->file_type = ToBridgeFileType(app_loader->GetFileType());
  out_info->is_compressed = app_loader->IsFileCompressed();
  const auto program_id_status = app_loader->ReadProgramId(out_info->program_id);
  out_info->has_program_id = program_id_status == Loader::ResultStatus::Success;
  out_info->loader_status = ToBridgeLoaderStatus(program_id_status);
  return true;
}

bool Aurora3DSBridge_LoadROMFromMemory(void*, const void*, size_t) {
  return false;
}

bool Aurora3DSBridge_SetRenderSurfaces(
    void* runtime_ptr,
    void* top_surface,
    void* bottom_surface,
    uint32_t,
    uint32_t,
    uint32_t,
    uint32_t,
    float render_surface_scale) {
  auto* runtime = AsRuntime(runtime_ptr);
  if (!runtime) return false;
  runtime->top_surface = top_surface;
  runtime->bottom_surface = bottom_surface;
  runtime->render_surface_scale = (render_surface_scale > 0.0f) ? render_surface_scale : 1.0f;
  if (runtime->window) {
    runtime->window->UpdateRenderSurface(runtime->top_surface, runtime->render_surface_scale);
  }
  return true;
}

bool Aurora3DSBridge_StepFrame(void* runtime_ptr) {
  auto* runtime = AsRuntime(runtime_ptr);
  if (!runtime || !runtime->system) return false;
  const auto status = runtime->system->RunLoop(true);
  runtime->last_error = ToStatusString(status);
  if (runtime->capture->CopyLatestRGBA(runtime->frame_rgba)) {
    runtime->no_frame_counter = 0;
  } else if (runtime->top_surface == nullptr) {
    runtime->no_frame_counter++;
    if (runtime->no_frame_counter > 120) {
      runtime->last_error =
          "no video frame captured (bridge path is incomplete; integrate Cytrus surface rendering path)";
    }
  }
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

bool Aurora3DS_ProbeROMFromPath(const char* rom_path, Aurora3DSROMProbeInfo* out_info) {
  return Aurora3DSBridge_ProbeROMFromPath(rom_path, out_info);
}

bool Aurora3DS_LoadROMFromMemory(void* runtime, const void* rom_data, size_t rom_size) {
  return Aurora3DSBridge_LoadROMFromMemory(runtime, rom_data, rom_size);
}

bool Aurora3DS_StepFrame(void* runtime) {
  return Aurora3DSBridge_StepFrame(runtime);
}

bool Aurora3DS_SetRenderSurfaces(
    void* runtime,
    void* top_surface,
    void* bottom_surface,
    uint32_t top_width,
    uint32_t top_height,
    uint32_t bottom_width,
    uint32_t bottom_height,
    float render_surface_scale) {
  return Aurora3DSBridge_SetRenderSurfaces(
      runtime,
      top_surface,
      bottom_surface,
      top_width,
      top_height,
      bottom_width,
      bottom_height,
      render_surface_scale);
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

bool Aurora3DSBridge_ProbeROMFromPath(const char*, Aurora3DSROMProbeInfo*) { return false; }
void* Aurora3DS_Create(void) { return nullptr; }
void Aurora3DS_Destroy(void*) {}
bool Aurora3DS_LoadBIOSFromPath(void*, const char*) { return false; }
bool Aurora3DS_LoadROMFromPath(void*, const char*) { return false; }
bool Aurora3DS_ProbeROMFromPath(const char*, Aurora3DSROMProbeInfo*) { return false; }
bool Aurora3DS_LoadROMFromMemory(void*, const void*, size_t) { return false; }
bool Aurora3DS_StepFrame(void*) { return false; }
bool Aurora3DS_SetRenderSurfaces(void*, void*, void*, uint32_t, uint32_t, uint32_t, uint32_t, float) { return false; }
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
  return "aurora3ds backend bridge is not linked";
#else
  return "aurora3ds is only available on Apple targets";
#endif
}

#endif

}  // extern "C"

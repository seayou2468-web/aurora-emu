#include "emulator_core_c_api.h"
#include "core_adapter.hpp"
#include <string>

struct EmulatorCoreHandle {
    const core::CoreAdapter* adapter = nullptr;
    void* runtime = nullptr;
    std::string last_error;
};

extern "C" {

const char* EmulatorCoreTypeName(EmulatorCoreType core_type) {
    const core::CoreAdapter* adapter = core::FindCoreAdapter(core_type);
    return adapter ? adapter->name : nullptr;
}

EmulatorCoreHandle* EmulatorCore_Create(EmulatorCoreType core_type) {
    const core::CoreAdapter* adapter = core::FindCoreAdapter(core_type);
    if (!adapter) return nullptr;
    try {
        auto* handle = new EmulatorCoreHandle();
        handle->adapter = adapter;
        handle->runtime = adapter->create_runtime ? adapter->create_runtime() : nullptr;
        if (!handle->runtime) {
            delete handle;
            return nullptr;
        }
        return handle;
    } catch (...) {
        return nullptr;
    }
}

void EmulatorCore_Destroy(EmulatorCoreHandle* handle) {
    if (!handle) return;
    if (handle->adapter && handle->adapter->destroy_runtime) {
        handle->adapter->destroy_runtime(handle->runtime);
    }
    delete handle;
}

bool EmulatorCore_LoadBIOSFromPath(EmulatorCoreHandle* handle, const char* bios_path) {
    if (!handle || !handle->adapter || !handle->adapter->load_bios_from_path) return false;
    return handle->adapter->load_bios_from_path(handle->runtime, bios_path, handle->last_error);
}

bool EmulatorCore_LoadROMFromPath(EmulatorCoreHandle* handle, const char* rom_path) {
    if (!handle || !handle->adapter || !handle->adapter->load_rom_from_path) return false;
    return handle->adapter->load_rom_from_path(handle->runtime, rom_path, handle->last_error);
}

bool EmulatorCore_LoadROMFromMemory(EmulatorCoreHandle* handle, const void* rom_data, size_t rom_size) {
    if (!handle || !handle->adapter || !handle->adapter->load_rom_from_memory) return false;
    return handle->adapter->load_rom_from_memory(handle->runtime, rom_data, rom_size, handle->last_error);
}

void EmulatorCore_StepFrame(EmulatorCoreHandle* handle) {
    if (!handle || !handle->adapter || !handle->adapter->step_frame) return;
    handle->adapter->step_frame(handle->runtime, handle->last_error);
}

void EmulatorCore_SetKeyStatus(EmulatorCoreHandle* handle, EmulatorKey key, bool pressed) {
    if (!handle || !handle->adapter || !handle->adapter->set_key_status) return;
    handle->adapter->set_key_status(handle->runtime, (int)key, pressed);
}

bool EmulatorCore_GetVideoSpec(const EmulatorCoreHandle* handle, EmulatorVideoSpec* out_spec) {
    if (!handle || !handle->adapter || !handle->adapter->get_video_spec) return false;
    return handle->adapter->get_video_spec(out_spec);
}

const uint32_t* EmulatorCore_GetFrameBufferRGBA(EmulatorCoreHandle* handle, size_t* pixel_count) {
    if (!handle || !handle->adapter || !handle->adapter->get_framebuffer_rgba) {
        if (pixel_count) *pixel_count = 0;
        return nullptr;
    }
    return handle->adapter->get_framebuffer_rgba(handle->runtime, pixel_count);
}

const char* EmulatorCore_GetLastError(EmulatorCoreHandle* handle) {
    if (!handle || handle->last_error.empty()) return nullptr;
    return handle->last_error.c_str();
}

bool EmulatorCore_SaveStateToBuffer(EmulatorCoreHandle* handle, void* out_buffer, size_t buffer_size, size_t* out_size) {
    if (!handle || !handle->adapter || !handle->adapter->save_state_to_buffer) return false;
    return handle->adapter->save_state_to_buffer(handle->runtime, out_buffer, buffer_size, out_size, handle->last_error);
}

bool EmulatorCore_LoadStateFromBuffer(EmulatorCoreHandle* handle, const void* state_buffer, size_t state_size) {
    if (!handle || !handle->adapter || !handle->adapter->load_state_from_buffer) return false;
    return handle->adapter->load_state_from_buffer(handle->runtime, state_buffer, state_size, handle->last_error);
}

bool EmulatorCore_ApplyCheatCode(EmulatorCoreHandle* handle, const char* cheat_code) {
    if (!handle || !handle->adapter || !handle->adapter->apply_cheat_code) return false;
    return handle->adapter->apply_cheat_code(handle->runtime, cheat_code, handle->last_error);
}

}

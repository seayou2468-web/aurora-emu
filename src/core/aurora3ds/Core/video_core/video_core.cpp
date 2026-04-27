// Copyright 2014 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include "common/logging/log.h"
#include "common/settings.h"
#include "video_core/gpu.h"
#include "video_core/renderer_software/renderer_software.h"
#include "video_core/video_core.h"

namespace VideoCore {

std::unique_ptr<RendererBase> CreateRenderer(Frontend::EmuWindow& emu_window,
                                             Frontend::EmuWindow* secondary_window,
                                             Pica::PicaCore& pica, Core::System& system) {
    const Settings::GraphicsAPI graphics_api = Settings::values.graphics_api.GetValue();
    if (graphics_api != Settings::GraphicsAPI::Software) {
        LOG_WARNING(Render, "Non-software graphics API {} requested. Forcing software renderer.",
                    graphics_api);
    }
    return std::make_unique<SwRenderer::RendererSoftware>(system, pica, emu_window);
}

} // namespace VideoCore

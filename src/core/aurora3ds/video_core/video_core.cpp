// Copyright Citra Emulator Project / Azahar Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include "common/logging/log.h"
#include "video_core/gpu.h"
#ifdef ENABLE_SOFTWARE_RENDERER
#include "video_core/renderer_software/renderer_software.h"
#endif
#include "video_core/video_core.h"

namespace VideoCore {

std::unique_ptr<RendererBase> CreateRenderer(Pica::PicaCore& pica, Core::System& system) {
#ifdef ENABLE_SOFTWARE_RENDERER
    return std::make_unique<SwRenderer::RendererSoftware>(system, pica);
#else
    LOG_CRITICAL(Render, "Software renderer is required but not enabled in this build");
// TODO: Add a null renderer backend for this, perhaps.
#error "At least one renderer must be enabled."
#endif
}

} // namespace VideoCore

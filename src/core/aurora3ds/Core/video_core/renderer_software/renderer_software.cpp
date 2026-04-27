// Copyright 2026 Aurora Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include "video_core/renderer_software/renderer_software.h"
#include "common/microprofile.h"
#include "video_core/pica/pica_core.h"

namespace SwRenderer {

MICROPROFILE_DEFINE(GPU_SoftwareFrame, "GPU", "Software Frame", MP_RGB(80, 200, 80));

void SoftwareRasterizer::AddTriangle(const Pica::OutputVertex&, const Pica::OutputVertex&,
                                     const Pica::OutputVertex&) {}

void SoftwareRasterizer::DrawTriangles() {}

void SoftwareRasterizer::NotifyPicaRegisterChanged(u32) {}

void SoftwareRasterizer::FlushAll() {}

void SoftwareRasterizer::FlushRegion(PAddr, u32) {}

void SoftwareRasterizer::InvalidateRegion(PAddr, u32) {}

void SoftwareRasterizer::FlushAndInvalidateRegion(PAddr, u32) {}

void SoftwareRasterizer::ClearAll(bool) {}

RendererSoftware::RendererSoftware(Core::System& system, Pica::PicaCore& pica,
                                   Frontend::EmuWindow& window,
                                   Frontend::EmuWindow* secondary_window)
    : RendererBase(system, window, secondary_window),
      rasterizer{std::make_unique<SoftwareRasterizer>()} {
    (void)pica;
}

RendererSoftware::~RendererSoftware() = default;

VideoCore::RasterizerInterface* RendererSoftware::Rasterizer() {
    return rasterizer.get();
}

void RendererSoftware::SwapBuffers() {
    MICROPROFILE_SCOPE(GPU_SoftwareFrame);
    current_frame++;
}

void RendererSoftware::TryPresent(int, bool) {}

} // namespace SwRenderer

// Copyright 2026 Aurora Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <memory>
#include "video_core/renderer_base.h"

namespace Core {
class System;
}

namespace Frontend {
class EmuWindow;
}

namespace Pica {
class PicaCore;
}

namespace SwRenderer {

class SoftwareRasterizer final : public VideoCore::RasterizerInterface {
public:
    ~SoftwareRasterizer() override = default;

    void AddTriangle(const Pica::OutputVertex& v0, const Pica::OutputVertex& v1,
                     const Pica::OutputVertex& v2) override;
    void DrawTriangles() override;
    void NotifyPicaRegisterChanged(u32 id) override;
    void FlushAll() override;
    void FlushRegion(PAddr addr, u32 size) override;
    void InvalidateRegion(PAddr addr, u32 size) override;
    void FlushAndInvalidateRegion(PAddr addr, u32 size) override;
    void ClearAll(bool flush) override;
};

class RendererSoftware final : public VideoCore::RendererBase {
public:
    explicit RendererSoftware(Core::System& system, Pica::PicaCore& pica,
                              Frontend::EmuWindow& window,
                              Frontend::EmuWindow* secondary_window = nullptr);
    ~RendererSoftware() override;

    VideoCore::RasterizerInterface* Rasterizer() override;
    void SwapBuffers() override;
    void TryPresent(int timeout_ms, bool is_secondary) override;

private:
    std::unique_ptr<SoftwareRasterizer> rasterizer;
};

} // namespace SwRenderer

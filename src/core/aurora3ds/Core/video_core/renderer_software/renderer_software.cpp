// Copyright Citra Emulator Project / Azahar Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include "common/color.h"
#include "common/logging/log.h"
#include "core/core.h"
#include "video_core/gpu.h"
#include "video_core/pica/pica_core.h"
#include "video_core/renderer_software/renderer_software.h"

namespace SwRenderer {

RendererSoftware::RendererSoftware(Core::System& system, Pica::PicaCore& pica_,
                                   Frontend::EmuWindow& window)
    : VideoCore::RendererBase{system, window, nullptr}, memory{system.Memory()}, pica{pica_},
      rasterizer{memory, pica} {}

RendererSoftware::~RendererSoftware() = default;

void RendererSoftware::SwapBuffers() {
    PrepareRenderTarget();
    EndFrame();
}

void RendererSoftware::PrepareRenderTarget() {
    const auto& regs_lcd = pica.regs_lcd;
    for (u32 i = 0; i < 3; i++) {
        const u32 fb_id = i == 2 ? 1 : 0;

        const auto color_fill = fb_id == 0 ? regs_lcd.color_fill_top : regs_lcd.color_fill_bottom;
        LoadFBToScreenInfo(i, color_fill);
    }
}

void RendererSoftware::LoadFBToScreenInfo(int i, const Pica::ColorFill& color_fill) {
    const u32 fb_id = i == 2 ? 1 : 0;
    const auto& framebuffer = pica.regs.framebuffer_config[fb_id];
    auto& info = screen_infos[i];

    const PAddr framebuffer_addr =
        framebuffer.active_fb == 0 ? framebuffer.address_left1 : framebuffer.address_left2;
    const s32 bpp = Pica::BytesPerPixel(framebuffer.color_format);

    if (framebuffer.height == 0 || framebuffer.stride == 0 || bpp <= 0) {
        info.width = 0;
        info.height = 0;
        info.pixels.clear();
        return;
    }

    if (!memory.IsValidPhysicalAddress(framebuffer_addr)) {
        LOG_WARNING(Render_Software, "Skipping invalid framebuffer address {:#010X}",
                    framebuffer_addr);
        info.width = 0;
        info.height = 0;
        info.pixels.clear();
        return;
    }

    const u8* framebuffer_data = memory.GetPhysicalPointer(framebuffer_addr);
    if (!framebuffer_data) {
        info.width = 0;
        info.height = 0;
        info.pixels.clear();
        return;
    }

    const s32 pixel_stride = framebuffer.stride / bpp;
    if (pixel_stride <= 0) {
        info.width = 0;
        info.height = 0;
        info.pixels.clear();
        return;
    }

    info.height = framebuffer.height;
    info.width = static_cast<u32>(pixel_stride);
    info.pixels.resize(info.width * info.height * 4);

    for (u32 y = 0; y < info.height; y++) {
        for (u32 x = 0; x < info.width; x++) {
            const u8* pixel = framebuffer_data + (y * pixel_stride + pixel_stride - x) * bpp;
            Common::Vec4<u8> color;

            if (color_fill.is_enabled) {
                color = Common::Vec4<u8>(color_fill.color_r, color_fill.color_g, color_fill.color_b,
                                         255);
            } else {
                switch (framebuffer.color_format) {
                case Pica::PixelFormat::RGBA8:
                    color = Common::Color::DecodeRGBA8(pixel);
                    break;
                case Pica::PixelFormat::RGB8:
                    color = Common::Color::DecodeRGB8(pixel);
                    break;
                case Pica::PixelFormat::RGB565:
                    color = Common::Color::DecodeRGB565(pixel);
                    break;
                case Pica::PixelFormat::RGB5A1:
                    color = Common::Color::DecodeRGB5A1(pixel);
                    break;
                case Pica::PixelFormat::RGBA4:
                    color = Common::Color::DecodeRGBA4(pixel);
                    break;
                default:
                    color = Common::Vec4<u8>(0, 0, 0, 255);
                    break;
                }
            }

            const u32 output_offset = (x * info.height + y) * 4;
            u8* dest = info.pixels.data() + output_offset;
            std::memcpy(dest, color.AsArray(), sizeof(color));
        }
    }
}

} // namespace SwRenderer

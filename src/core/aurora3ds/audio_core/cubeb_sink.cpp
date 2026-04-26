// iOS fallback sink implementation that removes cubeb dependency.

#include "audio_core/cubeb_sink.h"
#include "common/logging/log.h"

namespace AudioCore {

struct CubebSink::Impl {
    std::function<void(s16*, std::size_t)> cb;
};

CubebSink::CubebSink(std::string_view target_device_name) : impl(std::make_unique<Impl>()) {
    LOG_INFO(Audio_Sink, "Using iOS SDK fallback sink (cubeb removed), device={}",
             target_device_name);
}

CubebSink::~CubebSink() = default;

unsigned int CubebSink::GetNativeSampleRate() const {
    return native_sample_rate;
}

void CubebSink::SetCallback(std::function<void(s16*, std::size_t)> cb) {
    impl->cb = std::move(cb);
}

std::vector<std::string> ListCubebSinkDevices() {
    return {auto_device_name};
}

} // namespace AudioCore

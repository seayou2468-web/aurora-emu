// iOS fallback input implementation that removes cubeb dependency.

#include <utility>
#include <vector>
#include "audio_core/cubeb_input.h"
#include "common/logging/log.h"

namespace AudioCore {

struct CubebInput::Impl {
    bool sampling = false;
};

CubebInput::CubebInput(std::string device_id)
    : impl(std::make_unique<Impl>()), device_id(std::move(device_id)) {}

CubebInput::~CubebInput() {
    StopSampling();
}

void CubebInput::StartSampling(const InputParameters& params) {
    parameters = params;
    impl->sampling = true;
    LOG_INFO(Audio, "Using iOS SDK fallback input (cubeb removed), device={}", device_id);
}

void CubebInput::StopSampling() {
    impl->sampling = false;
}

bool CubebInput::IsSampling() {
    return impl->sampling;
}

void CubebInput::AdjustSampleRate(u32 sample_rate) {
    parameters.sample_rate = sample_rate;
}

Samples CubebInput::Read() {
    return {};
}

std::vector<std::string> ListCubebInputDevices() {
    return {auto_device_name};
}

} // namespace AudioCore

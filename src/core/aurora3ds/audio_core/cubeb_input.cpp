// iOS SDK microphone input (AudioQueue) replacing cubeb.

#include <array>
#include <algorithm>
#include <cstring>
#include <utility>
#include <vector>
#include <AudioToolbox/AudioToolbox.h>
#include "audio_core/cubeb_input.h"
#include "audio_core/input.h"
#include "audio_core/sink.h"
#include "common/logging/log.h"
#include "common/threadsafe_queue.h"

namespace AudioCore {

using SampleQueue = Common::SPSCQueue<Samples>;

namespace {
constexpr u32 kBufferFrames = 512;
constexpr u32 kBufferCount = 3;
}

struct CubebInput::Impl {
    AudioQueueRef queue = nullptr;
    std::array<AudioQueueBufferRef, kBufferCount> buffers{};

    SampleQueue sample_queue{};
    u8 sample_size_in_bytes = 0;
    bool started = false;

    static void InputCallback(void* user_data, AudioQueueRef queue, AudioQueueBufferRef buffer,
                              const AudioTimeStamp*, u32, const AudioStreamPacketDescription*) {
        auto* impl = static_cast<Impl*>(user_data);
        if (!impl || !impl->started) {
            return;
        }

        const auto num_input_samples = buffer->mAudioDataByteSize / sizeof(s16);
        const auto* input = reinterpret_cast<const s16*>(buffer->mAudioData);

        Samples samples{};
        samples.reserve(num_input_samples * impl->sample_size_in_bytes);
        if (impl->sample_size_in_bytes == 1) {
            for (u32 i = 0; i < num_input_samples; i++) {
                samples.push_back(static_cast<u8>(static_cast<u16>(input[i]) >> 8));
            }
        } else {
            const auto* ptr = reinterpret_cast<const u8*>(input);
            samples.insert(samples.end(), ptr, ptr + buffer->mAudioDataByteSize);
        }
        impl->sample_queue.Push(samples);

        AudioQueueEnqueueBuffer(queue, buffer, 0, nullptr);
    }
};

CubebInput::CubebInput(std::string device_id)
    : impl(std::make_unique<Impl>()), device_id(std::move(device_id)) {}

CubebInput::~CubebInput() {
    StopSampling();
}

void CubebInput::StartSampling(const InputParameters& params) {
    if (IsSampling()) {
        return;
    }

    parameters = params;
    impl->sample_size_in_bytes = params.sample_size / 8;

    AudioStreamBasicDescription asbd{};
    asbd.mSampleRate = params.sample_rate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    asbd.mChannelsPerFrame = 1;
    asbd.mBitsPerChannel = 16;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerFrame = (asbd.mBitsPerChannel / 8) * asbd.mChannelsPerFrame;
    asbd.mBytesPerPacket = asbd.mBytesPerFrame * asbd.mFramesPerPacket;

    const OSStatus create = AudioQueueNewInput(&asbd, &Impl::InputCallback, impl.get(), nullptr,
                                               nullptr, 0, &impl->queue);
    if (create != noErr) {
        LOG_CRITICAL(Audio, "AudioQueueNewInput failed: {}", static_cast<int>(create));
        return;
    }

    for (u32 i = 0; i < kBufferCount; i++) {
        const OSStatus alloc = AudioQueueAllocateBuffer(impl->queue, kBufferFrames * asbd.mBytesPerFrame,
                                                        &impl->buffers[i]);
        if (alloc != noErr) {
            LOG_CRITICAL(Audio, "AudioQueueAllocateBuffer failed: {}", static_cast<int>(alloc));
            StopSampling();
            return;
        }
        AudioQueueEnqueueBuffer(impl->queue, impl->buffers[i], 0, nullptr);
    }

    const OSStatus start = AudioQueueStart(impl->queue, nullptr);
    if (start != noErr) {
        LOG_CRITICAL(Audio, "AudioQueueStart failed: {}", static_cast<int>(start));
        StopSampling();
        return;
    }

    impl->started = true;
}

void CubebInput::StopSampling() {
    if (!impl->queue) {
        return;
    }
    impl->started = false;
    AudioQueueStop(impl->queue, true);
    AudioQueueDispose(impl->queue, true);
    impl->queue = nullptr;
}

bool CubebInput::IsSampling() {
    return impl->queue != nullptr && impl->started;
}

void CubebInput::AdjustSampleRate(u32 sample_rate) {
    if (!IsSampling()) {
        return;
    }

    auto new_parameters = parameters;
    new_parameters.sample_rate = sample_rate;
    StopSampling();
    StartSampling(new_parameters);
}

Samples CubebInput::Read() {
    if (!IsSampling()) {
        return {};
    }

    Samples samples{};
    Samples queue;
    while (impl->sample_queue.Pop(queue)) {
        samples.insert(samples.end(), queue.begin(), queue.end());
    }
    return samples;
}

std::vector<std::string> ListCubebInputDevices() {
    return {auto_device_name};
}

} // namespace AudioCore

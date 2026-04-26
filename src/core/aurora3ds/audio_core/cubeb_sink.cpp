// iOS SDK audio sink (AudioQueue) replacing cubeb.

#include <array>
#include <atomic>
#include <cstring>
#include <AudioToolbox/AudioToolbox.h>
#include "audio_core/audio_types.h"
#include "audio_core/cubeb_sink.h"
#include "common/logging/log.h"

namespace AudioCore {

namespace {
constexpr u32 kBufferFrames = 512;
constexpr u32 kBufferCount = 3;
}

struct CubebSink::Impl {
    AudioQueueRef queue = nullptr;
    std::array<AudioQueueBufferRef, kBufferCount> buffers{};
    std::function<void(s16*, std::size_t)> cb;
    std::atomic<bool> started{false};

    static void OutputCallback(void* user_data, AudioQueueRef queue, AudioQueueBufferRef buffer) {
        auto* impl = static_cast<Impl*>(user_data);
        if (!impl) {
            return;
        }

        auto* samples = reinterpret_cast<s16*>(buffer->mAudioData);
        if (impl->cb) {
            impl->cb(samples, kBufferFrames);
        } else {
            std::memset(samples, 0, kBufferFrames * 2 * sizeof(s16));
        }
        buffer->mAudioDataByteSize = kBufferFrames * 2 * sizeof(s16);

        if (impl->started.load(std::memory_order_relaxed)) {
            AudioQueueEnqueueBuffer(queue, buffer, 0, nullptr);
        }
    }
};

CubebSink::CubebSink(std::string_view target_device_name) : impl(std::make_unique<Impl>()) {
    AudioStreamBasicDescription asbd{};
    asbd.mSampleRate = native_sample_rate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    asbd.mChannelsPerFrame = 2;
    asbd.mBitsPerChannel = 16;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerFrame = (asbd.mBitsPerChannel / 8) * asbd.mChannelsPerFrame;
    asbd.mBytesPerPacket = asbd.mBytesPerFrame * asbd.mFramesPerPacket;

    const OSStatus create = AudioQueueNewOutput(&asbd, &Impl::OutputCallback, impl.get(), nullptr,
                                                nullptr, 0, &impl->queue);
    if (create != noErr) {
        LOG_CRITICAL(Audio_Sink, "AudioQueueNewOutput failed: {}", static_cast<int>(create));
        return;
    }

    for (u32 i = 0; i < kBufferCount; i++) {
        const OSStatus alloc = AudioQueueAllocateBuffer(
            impl->queue, kBufferFrames * asbd.mBytesPerFrame, &impl->buffers[i]);
        if (alloc != noErr) {
            LOG_CRITICAL(Audio_Sink, "AudioQueueAllocateBuffer failed: {}", static_cast<int>(alloc));
            return;
        }
        std::memset(impl->buffers[i]->mAudioData, 0, impl->buffers[i]->mAudioDataBytesCapacity);
        impl->buffers[i]->mAudioDataByteSize = kBufferFrames * asbd.mBytesPerFrame;
        AudioQueueEnqueueBuffer(impl->queue, impl->buffers[i], 0, nullptr);
    }

    const OSStatus start = AudioQueueStart(impl->queue, nullptr);
    if (start != noErr) {
        LOG_CRITICAL(Audio_Sink, "AudioQueueStart failed: {}", static_cast<int>(start));
        return;
    }

    impl->started.store(true, std::memory_order_relaxed);
    LOG_INFO(Audio_Sink, "iOS AudioQueue sink started ({})", target_device_name);
}

CubebSink::~CubebSink() {
    if (!impl || !impl->queue) {
        return;
    }

    impl->started.store(false, std::memory_order_relaxed);
    AudioQueueStop(impl->queue, true);
    AudioQueueDispose(impl->queue, true);
    impl->queue = nullptr;
}

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

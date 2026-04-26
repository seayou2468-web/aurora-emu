// iOS Game Controller migration placeholder:
// GC adapter path no longer uses libusb.

#include "input_common/gcadapter/gc_adapter.h"
#include "common/logging/log.h"
#include "common/param_package.h"

namespace GCAdapter {

Adapter::Adapter() {
    LOG_INFO(Input, "GC Adapter is mapped to iOS Game Controller path (libusb removed)");
}

Adapter::~Adapter() = default;

void Adapter::BeginConfiguration() {
    configuring = true;
}

void Adapter::EndConfiguration() {
    configuring = false;
}

Common::SPSCQueue<GCPadStatus>& Adapter::GetPadQueue() {
    return pad_queue;
}

const Common::SPSCQueue<GCPadStatus>& Adapter::GetPadQueue() const {
    return pad_queue;
}

GCController& Adapter::GetPadState(std::size_t port) {
    return pads.at(port);
}

const GCController& Adapter::GetPadState(std::size_t port) const {
    return pads.at(port);
}

bool Adapter::DeviceConnected(std::size_t port) const {
    if (port >= pads.size()) {
        return false;
    }
    return pads[port].type != ControllerTypes::None;
}

std::vector<Common::ParamPackage> Adapter::GetInputDevices() const {
    return {};
}

void Adapter::UpdatePadType(std::size_t, ControllerTypes) {}
void Adapter::UpdateControllers(const AdapterPayload&) {}
void Adapter::UpdateSettings(std::size_t) {}
void Adapter::UpdateStateButtons(std::size_t, u8, u8) {}
void Adapter::UpdateStateAxes(std::size_t, const AdapterPayload&) {}
void Adapter::AdapterInputThread() {}
void Adapter::AdapterScanThread() {}
bool Adapter::IsPayloadCorrect(const AdapterPayload&, s32) { return false; }
void Adapter::Setup() {}
void Adapter::ResetDevices() { for (auto& p : pads) p = {}; }
void Adapter::ResetDevice(std::size_t port) { if (port < pads.size()) pads[port] = {}; }
bool Adapter::CheckDeviceAccess() { return true; }
bool Adapter::GetGCEndpoint(libusb_device*) { return false; }
void Adapter::JoinThreads() {}
void Adapter::ClearLibusbHandle() {}

} // namespace GCAdapter

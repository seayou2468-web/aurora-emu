// iOS Game Controller framework-backed adapter state bridge.

#include <fmt/format.h>
#include "common/param_package.h"
#include "input_common/gcadapter/gc_adapter.h"

namespace GCAdapter {

Adapter::Adapter() {
    for (std::size_t i = 0; i < pads.size(); ++i) {
        ResetDevice(i);
    }
}

Adapter::~Adapter() = default;

void Adapter::ResetDevice(std::size_t port) {
    pads[port].type = ControllerTypes::None;
    pads[port].buttons = 0;
    pads[port].last_button = PadButton::Undefined;
    pads[port].axis_values.fill(0);
    pads[port].axis_origin.fill(255);
}

void Adapter::SetPadConnection(std::size_t port, bool connected, bool wireless) {
    if (port >= pads.size()) {
        return;
    }

    if (!connected) {
        ResetDevice(port);
        return;
    }

    pads[port].type = wireless ? ControllerTypes::Wireless : ControllerTypes::Wired;
}

void Adapter::UpdatePadButtonState(std::size_t port, PadButton button, bool pressed) {
    if (port >= pads.size()) {
        return;
    }

    if (!DeviceConnected(port)) {
        SetPadConnection(port, true, true);
    }

    const auto bit = static_cast<u16>(button);
    if (pressed) {
        pads[port].buttons = static_cast<u16>(pads[port].buttons | bit);
        pads[port].last_button = button;
    } else {
        pads[port].buttons = static_cast<u16>(pads[port].buttons & ~bit);
    }

    if (configuring && pressed && button != PadButton::Undefined) {
        pad_queue.Push(GCPadStatus{.port = port, .button = button});
    }
}

void Adapter::UpdatePadAxisState(std::size_t port, PadAxes axis, s16 value) {
    if (port >= pads.size()) {
        return;
    }

    const auto index = static_cast<std::size_t>(axis);
    if (index >= pads[port].axis_values.size()) {
        return;
    }

    if (!DeviceConnected(port)) {
        SetPadConnection(port, true, true);
    }

    pads[port].axis_values[index] = value;

    if (configuring) {
        constexpr u8 axis_threshold = 50;
        if (value > axis_threshold || value < -axis_threshold) {
            pad_queue.Push(GCPadStatus{.port = port,
                                       .axis = axis,
                                       .axis_value = value,
                                       .axis_threshold = axis_threshold});
        }
    }
}

std::vector<Common::ParamPackage> Adapter::GetInputDevices() const {
    std::vector<Common::ParamPackage> devices;
    for (std::size_t port = 0; port < pads.size(); ++port) {
        if (!DeviceConnected(port)) {
            continue;
        }
        std::string name = fmt::format("Game Controller {}", port + 1);
        devices.emplace_back(Common::ParamPackage{{"class", "gcpad"},
                                                  {"display", std::move(name)},
                                                  {"port", std::to_string(port)}});
    }
    return devices;
}

bool Adapter::DeviceConnected(std::size_t port) const {
    return port < pads.size() && pads[port].type != ControllerTypes::None;
}

void Adapter::BeginConfiguration() {
    pad_queue.Clear();
    configuring = true;
}

void Adapter::EndConfiguration() {
    pad_queue.Clear();
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

} // namespace GCAdapter

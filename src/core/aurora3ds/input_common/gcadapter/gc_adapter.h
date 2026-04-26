// Copyright 2014 Dolphin Emulator Project
// Licensed under GPLv2+
// Refer to the license.txt file included.

#pragma once

#include <array>
#include <vector>
#include "common/common_types.h"
#include "common/threadsafe_queue.h"

namespace Common {
class ParamPackage;
}

namespace GCAdapter {

enum class PadButton {
    Undefined = 0x0000,
    ButtonLeft = 0x0001,
    ButtonRight = 0x0002,
    ButtonDown = 0x0004,
    ButtonUp = 0x0008,
    TriggerZ = 0x0010,
    TriggerR = 0x0020,
    TriggerL = 0x0040,
    ButtonA = 0x0100,
    ButtonB = 0x0200,
    ButtonX = 0x0400,
    ButtonY = 0x0800,
    ButtonStart = 0x1000,
    Stick = 0x2000,
};

enum class PadAxes : u8 {
    StickX,
    StickY,
    SubstickX,
    SubstickY,
    TriggerLeft,
    TriggerRight,
    Undefined,
};

enum class ControllerTypes {
    None,
    Wired,
    Wireless,
};

struct GCPadStatus {
    std::size_t port{};
    PadButton button{PadButton::Undefined};
    PadAxes axis{PadAxes::Undefined};
    s16 axis_value{};
    u8 axis_threshold{50};
};

struct GCController {
    ControllerTypes type{};
    u16 buttons{};
    PadButton last_button{};
    std::array<s16, 6> axis_values{};
    std::array<u8, 6> axis_origin{};
};

class Adapter {
public:
    Adapter();
    ~Adapter();

    void BeginConfiguration();
    void EndConfiguration();

    Common::SPSCQueue<GCPadStatus>& GetPadQueue();
    const Common::SPSCQueue<GCPadStatus>& GetPadQueue() const;

    GCController& GetPadState(std::size_t port);
    const GCController& GetPadState(std::size_t port) const;

    bool DeviceConnected(std::size_t port) const;
    std::vector<Common::ParamPackage> GetInputDevices() const;

    // iOS Game Controller framework bridge entrypoints.
    void SetPadConnection(std::size_t port, bool connected, bool wireless = true);
    void UpdatePadButtonState(std::size_t port, PadButton button, bool pressed);
    void UpdatePadAxisState(std::size_t port, PadAxes axis, s16 value);

private:
    void ResetDevice(std::size_t port);

    std::array<GCController, 4> pads;
    Common::SPSCQueue<GCPadStatus> pad_queue;
    bool configuring{false};
};
} // namespace GCAdapter

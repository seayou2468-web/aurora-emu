#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum AURGCButton {
    AUR_GC_BUTTON_A = 0x0100,
    AUR_GC_BUTTON_B = 0x0200,
    AUR_GC_BUTTON_X = 0x0400,
    AUR_GC_BUTTON_Y = 0x0800,
    AUR_GC_BUTTON_START = 0x1000,
    AUR_GC_BUTTON_Z = 0x0010,
    AUR_GC_BUTTON_R = 0x0020,
    AUR_GC_BUTTON_L = 0x0040,
    AUR_GC_BUTTON_UP = 0x0008,
    AUR_GC_BUTTON_DOWN = 0x0004,
    AUR_GC_BUTTON_LEFT = 0x0001,
    AUR_GC_BUTTON_RIGHT = 0x0002,
} AURGCButton;

typedef enum AURGCAxis {
    AUR_GC_AXIS_STICK_X = 0,
    AUR_GC_AXIS_STICK_Y = 1,
    AUR_GC_AXIS_CSTICK_X = 2,
    AUR_GC_AXIS_CSTICK_Y = 3,
    AUR_GC_AXIS_TRIGGER_L = 4,
    AUR_GC_AXIS_TRIGGER_R = 5,
} AURGCAxis;

void AURGCAdapterSetConnection(size_t port, bool connected, bool wireless);
void AURGCAdapterSetButton(size_t port, AURGCButton button, bool pressed);
void AURGCAdapterSetAxis(size_t port, AURGCAxis axis, int16_t value);

#ifdef __cplusplus
}
#endif

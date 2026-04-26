#import "AURExternalControllerManager.h"

@implementation AURExternalControllerManager

+ (instancetype)sharedManager {
    static AURExternalControllerManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (void)startMonitoring {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controllerDidConnect:) name:GCControllerDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controllerDidDisconnect:) name:GCControllerDidDisconnectNotification object:nil];

    for (GCController *controller in [GCController controllers]) {
        [self setupController:controller];
        AURGCAdapterSetConnection(0, true, controller.isAttachedToDevice == NO);
    }
}

- (void)controllerDidConnect:(NSNotification *)notification {
    GCController *controller = notification.object;
    [self setupController:controller];
    AURGCAdapterSetConnection(0, true, controller.isAttachedToDevice == NO);
}

- (void)controllerDidDisconnect:(NSNotification *)notification {
    AURGCAdapterSetConnection(0, false, true);
}

- (void)setupController:(GCController *)controller {
    GCExtendedGamepad *profile = controller.extendedGamepad;
    if (profile) {
        __weak typeof(self) weakSelf = self;

        profile.buttonA.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            AURGCAdapterSetButton(0, AUR_GC_BUTTON_A, pressed);
            [weakSelf handleKey:EMULATOR_KEY_A pressed:pressed];
        };
        profile.buttonB.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            AURGCAdapterSetButton(0, AUR_GC_BUTTON_B, pressed);
            [weakSelf handleKey:EMULATOR_KEY_B pressed:pressed];
        };
        profile.leftShoulder.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            AURGCAdapterSetButton(0, AUR_GC_BUTTON_L, pressed);
            [weakSelf handleKey:EMULATOR_KEY_L pressed:pressed];
        };
        profile.rightShoulder.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            AURGCAdapterSetButton(0, AUR_GC_BUTTON_R, pressed);
            [weakSelf handleKey:EMULATOR_KEY_R pressed:pressed];
        };
        profile.buttonOptions.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            AURGCAdapterSetButton(0, AUR_GC_BUTTON_Z, pressed);
            [weakSelf handleKey:EMULATOR_KEY_SELECT pressed:pressed];
        };
        profile.buttonMenu.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            AURGCAdapterSetButton(0, AUR_GC_BUTTON_START, pressed);
            [weakSelf handleKey:EMULATOR_KEY_START pressed:pressed];
        };

        profile.dpad.up.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            AURGCAdapterSetButton(0, AUR_GC_BUTTON_UP, pressed);
            [weakSelf handleKey:EMULATOR_KEY_UP pressed:pressed];
        };
        profile.dpad.down.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            AURGCAdapterSetButton(0, AUR_GC_BUTTON_DOWN, pressed);
            [weakSelf handleKey:EMULATOR_KEY_DOWN pressed:pressed];
        };
        profile.dpad.left.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            AURGCAdapterSetButton(0, AUR_GC_BUTTON_LEFT, pressed);
            [weakSelf handleKey:EMULATOR_KEY_LEFT pressed:pressed];
        };
        profile.dpad.right.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            AURGCAdapterSetButton(0, AUR_GC_BUTTON_RIGHT, pressed);
            [weakSelf handleKey:EMULATOR_KEY_RIGHT pressed:pressed];
        };

        profile.leftThumbstick.xAxis.valueChangedHandler = ^(GCControllerAxisInput *axis, float value) {
            AURGCAdapterSetAxis(0, AUR_GC_AXIS_STICK_X, (int16_t)(value * 32767.0f));
        };
        profile.leftThumbstick.yAxis.valueChangedHandler = ^(GCControllerAxisInput *axis, float value) {
            AURGCAdapterSetAxis(0, AUR_GC_AXIS_STICK_Y, (int16_t)(value * 32767.0f));
        };
        profile.rightThumbstick.xAxis.valueChangedHandler = ^(GCControllerAxisInput *axis, float value) {
            AURGCAdapterSetAxis(0, AUR_GC_AXIS_CSTICK_X, (int16_t)(value * 32767.0f));
        };
        profile.rightThumbstick.yAxis.valueChangedHandler = ^(GCControllerAxisInput *axis, float value) {
            AURGCAdapterSetAxis(0, AUR_GC_AXIS_CSTICK_Y, (int16_t)(value * 32767.0f));
        };
        profile.leftTrigger.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            AURGCAdapterSetAxis(0, AUR_GC_AXIS_TRIGGER_L, (int16_t)(value * 32767.0f));
        };
        profile.rightTrigger.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            AURGCAdapterSetAxis(0, AUR_GC_AXIS_TRIGGER_R, (int16_t)(value * 32767.0f));
        };
    }
}

- (void)handleKey:(EmulatorKey)key pressed:(BOOL)pressed {
    if (pressed) {
        [self.delegate externalControllerDidPressKey:key];
    } else {
        [self.delegate externalControllerDidReleaseKey:key];
    }
}

@end

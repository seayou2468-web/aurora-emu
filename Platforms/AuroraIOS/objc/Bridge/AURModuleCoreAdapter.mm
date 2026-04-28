#import "AURModuleCoreAdapter.h"

@interface AURModuleCoreAdapter () {
    EmulatorCoreHandle *_coreHandle;
    EmulatorVideoSpec _videoSpec;
}
@end

@implementation AURModuleCoreAdapter
@synthesize coreType = _coreType;

- (instancetype)initWithCoreType:(EmulatorCoreType)coreType {
    self = [super init];
    if (self) {
        _coreType = coreType;
        _coreHandle = EmulatorCore_Create(coreType);
        _running = NO;
        _videoSpec = (EmulatorVideoSpec){0, 0, EMULATOR_PIXEL_FORMAT_RGBA8888};
    }
    return self;
}

- (void)dealloc {
    if (_coreHandle) {
        EmulatorCore_Destroy(_coreHandle);
        _coreHandle = nullptr;
    }
}

- (AURCoreConnectionKind)connectionKind {
    return AUR_CORE_CONNECTION_MODULE_ADAPTER;
}

- (BOOL)loadBIOSAtPath:(NSString *)biosPath {
    if (!_coreHandle || biosPath.length == 0) {
        return NO;
    }
    return EmulatorCore_LoadBIOSFromPath(_coreHandle, biosPath.fileSystemRepresentation);
}

- (BOOL)loadROMAtURL:(NSURL *)romURL {
    if (!_coreHandle || romURL.path.length == 0) {
        return NO;
    }
    const char *path = romURL.path.fileSystemRepresentation;
    if (!path) {
        return NO;
    }

    const BOOL loaded = EmulatorCore_LoadROMFromPath(_coreHandle, path);
    if (!loaded) {
        return NO;
    }

    _running = EmulatorCore_GetVideoSpec(_coreHandle, &_videoSpec);
    return _running;
}

- (void)stepFrame {
    if (!_coreHandle || !_running) {
        return;
    }
    EmulatorCore_StepFrame(_coreHandle);
}

- (void)setKey:(EmulatorKey)key pressed:(BOOL)pressed {
    if (!_coreHandle || !_running) {
        return;
    }
    EmulatorCore_SetKeyStatus(_coreHandle, key, pressed);
}

- (const uint32_t *)frameBufferWithPixelCount:(size_t *)pixelCount {
    if (!_coreHandle || !_running) {
        return nullptr;
    }
    return EmulatorCore_GetFrameBufferRGBA(_coreHandle, pixelCount);
}

- (NSString *)lastError {
    if (!_coreHandle) {
        return @"Core is not initialized";
    }
    const char *error = EmulatorCore_GetLastError(_coreHandle);
    if (!error || error[0] == '\0') {
        return nil;
    }
    return [NSString stringWithUTF8String:error];
}

@end

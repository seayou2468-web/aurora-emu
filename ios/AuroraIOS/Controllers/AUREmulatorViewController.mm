#import "AUREmulatorViewController.h"
#import "AURInGameMenuViewController.h"
#import "../Views/AURControllerView.h"
#import "../Managers/AURSkinManager.h"
#import "../Managers/AURDatabaseManager.h"
#import "../Managers/AURExternalControllerManager.h"
#import "../Metal.h"
#import <QuartzCore/QuartzCore.h>
#include <algorithm>
#include <array>
#include <cstring>

@interface AUREmulatorViewController () <AURControllerViewDelegate, AURExternalControllerDelegate, AURInGameMenuDelegate> {
    EmulatorCoreHandle* _core;
    EmulatorCoreType    _coreType;
    EmulatorVideoSpec   _videoSpec;
    BOOL                _running;
    BOOL                _didShowRuntimeError;
}
@property (nonatomic, strong) AURMetalView *imageView;
@property (nonatomic, strong) AURMetalView *ndsBottomImageView;
@property (nonatomic, strong) UIView *ndsContainerView;
@property (nonatomic, strong) AURControllerView *controllerView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) NSURL *romURL;
@end

@implementation AUREmulatorViewController

- (instancetype)initWithROMURL:(NSURL *)romURL coreType:(EmulatorCoreType)coreType {
    self = [super init];
    if (self) {
        _romURL = romURL;
        _coreType = coreType;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    // Setup Metal View(s)
    self.imageView = [[AURMetalView alloc] initWithFrame:CGRectZero];
    if (_coreType == EMULATOR_CORE_TYPE_NDS || _coreType == EMULATOR_CORE_TYPE_3DS) {
        [self.imageView setFramePixelFormat:AURFramePixelFormatBGRA8888];
        self.ndsContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        self.ndsContainerView.backgroundColor = [UIColor blackColor];
        self.ndsBottomImageView = [[AURMetalView alloc] initWithFrame:CGRectZero];
        [self.ndsBottomImageView setFramePixelFormat:AURFramePixelFormatBGRA8888];
        [self.ndsContainerView addSubview:self.imageView];
        [self.ndsContainerView addSubview:self.ndsBottomImageView];
        [self.view addSubview:self.ndsContainerView];
    } else {
        [self.imageView setFramePixelFormat:AURFramePixelFormatRGBA8888];
        [self.view addSubview:self.imageView];
    }

    // Menu Button (Glassmorphic)
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    blurEffectView.frame = CGRectMake(0, 0, 40, 40);
    blurEffectView.layer.cornerRadius = 20;
    blurEffectView.clipsToBounds = YES;

    UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [menuButton setImage:[UIImage systemImageNamed:@"line.3.horizontal.circle.fill"] forState:UIControlStateNormal];
    menuButton.tintColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.76 alpha:1.0];
    [menuButton addTarget:self action:@selector(menuTapped) forControlEvents:UIControlEventTouchUpInside];
    [blurEffectView.contentView addSubview:menuButton];
    menuButton.frame = blurEffectView.bounds;

    [self.view addSubview:blurEffectView];
    blurEffectView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [blurEffectView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10],
        [blurEffectView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [blurEffectView.widthAnchor constraintEqualToConstant:40],
        [blurEffectView.heightAnchor constraintEqualToConstant:40]
    ]];

    // Setup Controller View
    self.controllerView = [[AURControllerView alloc] initWithFrame:CGRectZero];
    self.controllerView.delegate = self;
    [self.view addSubview:self.controllerView];

    // Layout
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.controllerView.translatesAutoresizingMaskIntoConstraints = NO;

    if (_coreType == EMULATOR_CORE_TYPE_NDS || _coreType == EMULATOR_CORE_TYPE_3DS) {
        self.ndsContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        self.ndsBottomImageView.translatesAutoresizingMaskIntoConstraints = NO;
        CGFloat topAspect = (_coreType == EMULATOR_CORE_TYPE_3DS) ? (240.0 / 400.0) : (192.0 / 256.0);
        [NSLayoutConstraint activateConstraints:@[
            [self.ndsContainerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
            [self.ndsContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12.0],
            [self.ndsContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12.0],

            [self.imageView.topAnchor constraintEqualToAnchor:self.ndsContainerView.topAnchor],
            [self.imageView.leadingAnchor constraintEqualToAnchor:self.ndsContainerView.leadingAnchor],
            [self.imageView.trailingAnchor constraintEqualToAnchor:self.ndsContainerView.trailingAnchor],
            [self.imageView.heightAnchor constraintEqualToAnchor:self.imageView.widthAnchor multiplier:topAspect],

            [self.ndsBottomImageView.topAnchor constraintEqualToAnchor:self.imageView.bottomAnchor constant:12.0],
            [self.ndsBottomImageView.leadingAnchor constraintEqualToAnchor:self.ndsContainerView.leadingAnchor],
            [self.ndsBottomImageView.trailingAnchor constraintEqualToAnchor:self.ndsContainerView.trailingAnchor],
            [self.ndsBottomImageView.heightAnchor constraintEqualToAnchor:self.imageView.heightAnchor],
            [self.ndsBottomImageView.bottomAnchor constraintEqualToAnchor:self.ndsContainerView.bottomAnchor],

            [self.controllerView.topAnchor constraintEqualToAnchor:self.ndsContainerView.bottomAnchor],
            [self.controllerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [self.controllerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [self.controllerView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
        ]];
    } else {
        [NSLayoutConstraint activateConstraints:@[
            [self.imageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20.0],
            [self.imageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
            [self.imageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0],
            [self.imageView.heightAnchor constraintEqualToAnchor:self.imageView.widthAnchor multiplier:(160.0 / 240.0)],

            [self.controllerView.topAnchor constraintEqualToAnchor:self.imageView.bottomAnchor],
            [self.controllerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [self.controllerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [self.controllerView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
        ]];
    }

    [self startEmulator];
}

- (void)startEmulator {
    [self stopEmulator];
    _didShowRuntimeError = NO;
    _core = EmulatorCore_Create(_coreType);
    if (!_core) {
        NSLog(@"[AUR][Emu] Failed to create core: %d", (int)_coreType);
        if (_coreType == EMULATOR_CORE_TYPE_3DS) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Aurora3DS接続エラー"
                                                                           message:@"Aurora3DSの実コアブリッジがリンクされていないため起動できません。"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        return;
    }

    // Load BIOS files from DatabaseManager (persisted in Documents)
    if (_coreType == EMULATOR_CORE_TYPE_NDS) {
        NSString *arm9 = [[AURDatabaseManager sharedManager] BIOSPathForIdentifier:@"nds_arm9"];
        NSString *arm7 = [[AURDatabaseManager sharedManager] BIOSPathForIdentifier:@"nds_arm7"];
        NSString *firm = [[AURDatabaseManager sharedManager] BIOSPathForIdentifier:@"nds_firmware"];
        if (arm9) { if (!EmulatorCore_LoadBIOSFromPath(_core, arm9.UTF8String)) NSLog(@"[AUR][Emu] Failed to load ARM9 BIOS at %@", arm9); }
        if (arm7) EmulatorCore_LoadBIOSFromPath(_core, arm7.UTF8String);
        if (firm) EmulatorCore_LoadBIOSFromPath(_core, firm.UTF8String);
    } else if (_coreType == EMULATOR_CORE_TYPE_GBA) {
        NSString *gba = [[AURDatabaseManager sharedManager] BIOSPathForIdentifier:@"gba"];
        if (gba) EmulatorCore_LoadBIOSFromPath(_core, gba.UTF8String);
    } else if (_coreType == EMULATOR_CORE_TYPE_GB) {
        // SameBoy core handles GB/GBC. Detect mode if needed, but for now just load what's available.
        NSString *gb = [[AURDatabaseManager sharedManager] BIOSPathForIdentifier:@"gb"];
        NSString *gbc = [[AURDatabaseManager sharedManager] BIOSPathForIdentifier:@"gbc"];
        if (gb) EmulatorCore_LoadBIOSFromPath(_core, gb.UTF8String);
        if (gbc) EmulatorCore_LoadBIOSFromPath(_core, gbc.UTF8String);
    }

    const char *path = self.romURL.path.fileSystemRepresentation;
    if (path && EmulatorCore_LoadROMFromPath(_core, path)) {
        EmulatorCore_GetVideoSpec(_core, &_videoSpec);
        if (_coreType != EMULATOR_CORE_TYPE_NDS && _coreType != EMULATOR_CORE_TYPE_3DS) {
            AURFramePixelFormat framePixelFormat = (_videoSpec.pixel_format == EMULATOR_PIXEL_FORMAT_ARGB8888)
                ? AURFramePixelFormatBGRA8888
                : AURFramePixelFormatRGBA8888;
            [self.imageView setFramePixelFormat:framePixelFormat];
        }
        _running = YES;
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(gameLoop)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    } else {
        NSLog(@"[AUR][Emu] ROM load failed (%@): %s", self.romURL.lastPathComponent, EmulatorCore_GetLastError(_core) ?: "unknown error");
        if (_coreType == EMULATOR_CORE_TYPE_3DS) {
            const char *errorText = EmulatorCore_GetLastError(_core) ?: "unknown error";
            NSString *message = [NSString stringWithFormat:@"Aurora3DSブリッジまたはROM初期化に失敗しました。\n%s", errorText];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Aurora3DS起動失敗"
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        [self stopEmulator];
    }
}

- (void)stopEmulator {
    _running = NO;
    [self.displayLink invalidate];
    self.displayLink = nil;
    if (_core) {
        EmulatorCore_Destroy(_core);
        _core = nullptr;
    }
}

- (void)gameLoop {
    if (!_running || !_core) return;
    EmulatorCore_StepFrame(_core);
    const char *stepError = EmulatorCore_GetLastError(_core);
    if (stepError && stepError[0] != '\0' && strcmp(stepError, "success") != 0) {
        NSLog(@"[AUR][Emu] frame step error: %s", stepError);
        if (!_didShowRuntimeError) {
            _didShowRuntimeError = YES;
            NSString *message = [NSString stringWithFormat:@"%s", stepError];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Emulation Stopped"
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        [self stopEmulator];
        return;
    }

    size_t pixelCount = 0;
    const uint32_t* frameRGBA = EmulatorCore_GetFrameBufferRGBA(_core, &pixelCount);
    if (!frameRGBA) return;

    if (_coreType == EMULATOR_CORE_TYPE_NDS) {
        constexpr size_t kScreenWidth = 256U;
        constexpr size_t kScreenHeight = 192U;

        const size_t sourceWidth = (size_t)_videoSpec.width;
        const size_t sourceHeight = (sourceWidth > 0) ? (pixelCount / sourceWidth) : 0;

        if (sourceWidth >= (kScreenWidth * 2U)) {
            // Side-by-side: Left=Top, Right=Bottom
            [self.imageView displayFrameRGBA:frameRGBA width:sourceWidth height:sourceHeight sourceRect:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
            [self.ndsBottomImageView displayFrameRGBA:frameRGBA width:sourceWidth height:sourceHeight sourceRect:CGRectMake(kScreenWidth, 0, kScreenWidth, kScreenHeight)];
            return;
        }

        if (pixelCount >= kScreenWidth * kScreenHeight * 2U) {
            // Top-bottom: Top first, then Bottom
            [self.imageView displayFrameRGBA:frameRGBA width:kScreenWidth height:kScreenHeight * 2 sourceRect:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
            [self.ndsBottomImageView displayFrameRGBA:frameRGBA width:kScreenWidth height:kScreenHeight * 2 sourceRect:CGRectMake(0, kScreenHeight, kScreenWidth, kScreenHeight)];
            return;
        }
        return;
    }

    if (_coreType == EMULATOR_CORE_TYPE_3DS) {
        constexpr size_t kTopWidth = 400U;
        constexpr size_t kTopHeight = 240U;
        constexpr size_t kBottomWidth = 320U;
        constexpr size_t kBottomHeight = 240U;

        size_t sourceWidth = (size_t)_videoSpec.width;
        size_t sourceHeight = (sourceWidth > 0) ? (pixelCount / sourceWidth) : 0;

        // 3DS backend may provide different packing layouts than 400x480.
        // Recover width from common layouts when the advertised spec does not match pixelCount.
        if (sourceWidth == 0 || pixelCount % sourceWidth != 0 || sourceHeight < kTopHeight) {
            const std::array<size_t, 4> candidates = {400U, 720U, 320U, 800U};
            for (size_t w : candidates) {
                if (pixelCount % w != 0) continue;
                const size_t h = pixelCount / w;
                if (h >= kTopHeight && h <= (kTopHeight + kBottomHeight)) {
                    sourceWidth = w;
                    sourceHeight = h;
                    break;
                }
            }
        }

        if (sourceWidth < kTopWidth || sourceHeight < kTopHeight) {
            return;
        }

        // Layout A: stacked (top 400x240, bottom 320x240 centered in the lower half)
        if (sourceHeight >= (kTopHeight + kBottomHeight)) {
            [self.imageView displayFrameRGBA:frameRGBA
                                       width:sourceWidth
                                      height:sourceHeight
                                  sourceRect:CGRectMake(0, 0, kTopWidth, kTopHeight)];

            const CGFloat bottomX = (CGFloat)((kTopWidth - kBottomWidth) / 2U);
            [self.ndsBottomImageView displayFrameRGBA:frameRGBA
                                                width:sourceWidth
                                               height:sourceHeight
                                           sourceRect:CGRectMake(bottomX, kTopHeight, kBottomWidth, kBottomHeight)];
            return;
        }

        // Layout B: side-by-side (top 400x240 on left, bottom 320x240 on right)
        if (sourceWidth >= (kTopWidth + kBottomWidth) && sourceHeight >= kTopHeight) {
            [self.imageView displayFrameRGBA:frameRGBA
                                       width:sourceWidth
                                      height:sourceHeight
                                  sourceRect:CGRectMake(0, 0, kTopWidth, kTopHeight)];
            [self.ndsBottomImageView displayFrameRGBA:frameRGBA
                                                width:sourceWidth
                                               height:sourceHeight
                                           sourceRect:CGRectMake(kTopWidth, 0, kBottomWidth, kBottomHeight)];
            return;
        }

        // Layout C: top-only frame; keep lower screen black instead of dropping all rendering.
        [self.imageView displayFrameRGBA:frameRGBA
                                   width:sourceWidth
                                   height:sourceHeight
                              sourceRect:CGRectMake(0, 0, kTopWidth, kTopHeight)];
        [self.ndsBottomImageView clearFrame];
        return;
    }

    [self.imageView displayFrameRGBA:frameRGBA width:_videoSpec.width height:_videoSpec.height];
}

- (void)dealloc {
    [self stopEmulator];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopEmulator];
}

#pragma mark - AURControllerViewDelegate

- (void)controllerViewDidPressKey:(EmulatorKey)key {
    if (_core) EmulatorCore_SetKeyStatus(_core, key, true);
}

- (void)controllerViewDidReleaseKey:(EmulatorKey)key {
    if (_core) EmulatorCore_SetKeyStatus(_core, key, false);
}

#pragma mark - AURExternalControllerDelegate

- (void)externalControllerDidPressKey:(EmulatorKey)key {
    if (_core) EmulatorCore_SetKeyStatus(_core, key, true);
}

- (void)externalControllerDidReleaseKey:(EmulatorKey)key {
    if (_core) EmulatorCore_SetKeyStatus(_core, key, false);
}

- (void)menuTapped {
    AURInGameMenuViewController *menuVC = [[AURInGameMenuViewController alloc] init];
    menuVC.delegate = self;
    menuVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    menuVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:menuVC animated:YES completion:nil];
}

#pragma mark - AURInGameMenuDelegate

- (void)inGameMenuDidSelectAction:(NSString *)action {
    if ([action isEqualToString:@"Quit Game"]) {
        [self stopEmulator];
        if (self.presentingViewController) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        } else if (self.navigationController) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

@end

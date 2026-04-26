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
#include <vector>

@interface AUREmulatorViewController () <AURControllerViewDelegate, AURExternalControllerDelegate, AURInGameMenuDelegate> {
    EmulatorCoreHandle* _core;
    EmulatorCoreType    _coreType;
    EmulatorVideoSpec   _videoSpec;
    BOOL                _running;
    BOOL                _fastForwardEnabled;
    NSInteger           _framesPerTick;
}
@property (nonatomic, strong) AURMetalView *imageView;
@property (nonatomic, strong) AURMetalView *ndsBottomImageView;
@property (nonatomic, strong) UIView *ndsContainerView;
@property (nonatomic, strong) AURControllerView *controllerView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) NSURL *romURL;
@end

@implementation AUREmulatorViewController

static NSString * const kAURSaveStateDirectoryName = @"SaveStates";

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
        CGFloat topScreenRatio = (_coreType == EMULATOR_CORE_TYPE_3DS) ? (240.0 / 400.0) : (192.0 / 256.0);
        CGFloat bottomScaleRatio = (_coreType == EMULATOR_CORE_TYPE_3DS) ? (320.0 / 400.0) : 1.0;
        self.ndsContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        self.ndsBottomImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [self.ndsContainerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
            [self.ndsContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12.0],
            [self.ndsContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12.0],

            [self.imageView.topAnchor constraintEqualToAnchor:self.ndsContainerView.topAnchor],
            [self.imageView.leadingAnchor constraintEqualToAnchor:self.ndsContainerView.leadingAnchor],
            [self.imageView.trailingAnchor constraintEqualToAnchor:self.ndsContainerView.trailingAnchor],
            [self.imageView.heightAnchor constraintEqualToAnchor:self.imageView.widthAnchor multiplier:topScreenRatio],

            [self.ndsBottomImageView.topAnchor constraintEqualToAnchor:self.imageView.bottomAnchor constant:12.0],
            [self.ndsBottomImageView.centerXAnchor constraintEqualToAnchor:self.ndsContainerView.centerXAnchor],
            [self.ndsBottomImageView.widthAnchor constraintEqualToAnchor:self.imageView.widthAnchor multiplier:bottomScaleRatio],
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
    _framesPerTick = 1;
    _fastForwardEnabled = NO;
    _core = EmulatorCore_Create(_coreType);
    if (!_core) {
        NSLog(@"[AUR][Emu] Failed to create core: %d", (int)_coreType);
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
        if (!EmulatorCore_GetVideoSpec(_core, &_videoSpec)) {
            _videoSpec.width = (_coreType == EMULATOR_CORE_TYPE_3DS) ? 720 : ((_coreType == EMULATOR_CORE_TYPE_NDS) ? 512 : 240);
            _videoSpec.height = (_coreType == EMULATOR_CORE_TYPE_3DS) ? 240 : ((_coreType == EMULATOR_CORE_TYPE_NDS) ? 192 : 160);
            _videoSpec.pixel_format = (_coreType == EMULATOR_CORE_TYPE_NDS || _coreType == EMULATOR_CORE_TYPE_3DS)
                ? EMULATOR_PIXEL_FORMAT_ARGB8888
                : EMULATOR_PIXEL_FORMAT_RGBA8888;
        }

        AURFramePixelFormat framePixelFormat = (_videoSpec.pixel_format == EMULATOR_PIXEL_FORMAT_ARGB8888)
            ? AURFramePixelFormatBGRA8888
            : AURFramePixelFormatRGBA8888;
        [self.imageView setFramePixelFormat:framePixelFormat];
        [self.ndsBottomImageView setFramePixelFormat:framePixelFormat];
        _running = YES;
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(gameLoop)];
        if (@available(iOS 15.0, *)) {
            self.displayLink.preferredFrameRateRange = CAFrameRateRangeMake(60.0, 120.0, 60.0);
        } else {
            self.displayLink.preferredFramesPerSecond = 60;
        }
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [AURExternalControllerManager sharedManager].delegate = self;
        [[AURExternalControllerManager sharedManager] startMonitoring];
    } else {
        NSLog(@"[AUR][Emu] ROM load failed (%@): %s", self.romURL.lastPathComponent, EmulatorCore_GetLastError(_core) ?: "unknown error");
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
    [self.imageView clearFrame];
    [self.ndsBottomImageView clearFrame];
}

- (void)gameLoop {
    if (!_running || !_core) return;
    EmulatorCore_GetVideoSpec(_core, &_videoSpec);
    for (NSInteger index = 0; index < _framesPerTick; index++) {
        EmulatorCore_StepFrame(_core);
        const char *stepError = EmulatorCore_GetLastError(_core);
        if (stepError && stepError[0] != '\0') {
            NSLog(@"[AUR][Emu] frame step warning: %s", stepError);
            break;
        }
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
        constexpr size_t kBottomWidth = 320U;
        constexpr size_t kScreenHeight = 240U;

        const size_t sourceWidth = (size_t)_videoSpec.width;
        const size_t sourceHeight = (sourceWidth > 0) ? (pixelCount / sourceWidth) : 0;

        if (sourceWidth >= (kTopWidth + kBottomWidth)) {
            [self.imageView displayFrameRGBA:frameRGBA width:sourceWidth height:sourceHeight sourceRect:CGRectMake(0, 0, kTopWidth, kScreenHeight)];
            [self.ndsBottomImageView displayFrameRGBA:frameRGBA width:sourceWidth height:sourceHeight sourceRect:CGRectMake(kTopWidth, 0, kBottomWidth, kScreenHeight)];
            return;
        }

        if (sourceWidth >= kTopWidth && pixelCount >= (kTopWidth * kScreenHeight + kBottomWidth * kScreenHeight)) {
            [self.imageView displayFrameRGBA:frameRGBA width:kTopWidth height:kScreenHeight * 2 sourceRect:CGRectMake(0, 0, kTopWidth, kScreenHeight)];
            [self.ndsBottomImageView displayFrameRGBA:frameRGBA width:kTopWidth height:kScreenHeight * 2 sourceRect:CGRectMake(0, kScreenHeight, kBottomWidth, kScreenHeight)];
            return;
        }
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
    if ([action isEqualToString:@"Save State"]) {
        [self saveState];
    } else if ([action isEqualToString:@"Load State"]) {
        [self loadState];
    } else if ([action isEqualToString:@"Cheat Codes"]) {
        [self presentCheatCodePrompt];
    } else if ([action isEqualToString:@"Fast Forward"]) {
        [self setFastForwardEnabled:!_fastForwardEnabled];
    } else if ([action isEqualToString:@"Quit Game"]) {
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

- (NSURL *)saveStateURL {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *saveDirPath = [documentsPath stringByAppendingPathComponent:kAURSaveStateDirectoryName];
    [[NSFileManager defaultManager] createDirectoryAtPath:saveDirPath withIntermediateDirectories:YES attributes:nil error:nil];

    NSString *romFileName = self.romURL.lastPathComponent ?: @"game";
    NSString *stateFileName = [[romFileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"state"];
    return [NSURL fileURLWithPath:[saveDirPath stringByAppendingPathComponent:stateFileName]];
}

- (void)saveState {
    if (!_core) return;

    size_t requiredSize = 0;
    if (!EmulatorCore_SaveStateToBuffer(_core, nullptr, 0, &requiredSize) || requiredSize == 0) {
        [self presentStatusAlertWithTitle:@"Save Failed" message:@"セーブデータのサイズ取得に失敗しました。"];
        return;
    }

    std::vector<uint8_t> stateBuffer(requiredSize);
    size_t writtenSize = 0;
    if (!EmulatorCore_SaveStateToBuffer(_core, stateBuffer.data(), stateBuffer.size(), &writtenSize) || writtenSize == 0) {
        [self presentStatusAlertWithTitle:@"Save Failed" message:@"ステート保存に失敗しました。"];
        return;
    }

    NSURL *saveURL = [self saveStateURL];
    NSData *stateData = [NSData dataWithBytes:stateBuffer.data() length:writtenSize];
    NSError *writeError = nil;
    if (![stateData writeToURL:saveURL options:NSDataWritingAtomic error:&writeError]) {
        NSString *message = [NSString stringWithFormat:@"ファイル書き込みエラー: %@", writeError.localizedDescription ?: @"unknown"];
        [self presentStatusAlertWithTitle:@"Save Failed" message:message];
        return;
    }

    [self presentStatusAlertWithTitle:@"State Saved" message:@"セーブステートを保存しました。"];
}

- (void)loadState {
    if (!_core) return;

    NSURL *saveURL = [self saveStateURL];
    NSData *stateData = [NSData dataWithContentsOfURL:saveURL];
    if (!stateData || stateData.length == 0) {
        [self presentStatusAlertWithTitle:@"Load Failed" message:@"セーブステートが見つかりません。"];
        return;
    }

    if (!EmulatorCore_LoadStateFromBuffer(_core, stateData.bytes, stateData.length)) {
        [self presentStatusAlertWithTitle:@"Load Failed" message:@"ステート読み込みに失敗しました。"];
        return;
    }

    [self presentStatusAlertWithTitle:@"State Loaded" message:@"セーブステートを読み込みました。"];
}

- (void)presentCheatCodePrompt {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cheat Codes"
                                                                   message:@"チートコードを入力してください。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"ram:0200=63";
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Apply" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *code = alert.textFields.firstObject.text ?: @"";
        [weakSelf applyCheatCode:code];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)applyCheatCode:(NSString *)cheatCode {
    if (!_core) return;

    NSString *trimmed = [cheatCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        [self presentStatusAlertWithTitle:@"Cheat Failed" message:@"空のコードは適用できません。"];
        return;
    }

    if (!EmulatorCore_ApplyCheatCode(_core, trimmed.UTF8String)) {
        const char *coreError = EmulatorCore_GetLastError(_core);
        NSString *message = coreError ? [NSString stringWithUTF8String:coreError] : @"チート適用に失敗しました。";
        [self presentStatusAlertWithTitle:@"Cheat Failed" message:message];
        return;
    }

    [self presentStatusAlertWithTitle:@"Cheat Applied" message:@"チートを適用しました。"];
}

- (void)setFastForwardEnabled:(BOOL)enabled {
    _fastForwardEnabled = enabled;
    _framesPerTick = enabled ? 2 : 1;

    if (@available(iOS 15.0, *)) {
        self.displayLink.preferredFrameRateRange = enabled
            ? CAFrameRateRangeMake(60.0, 120.0, 120.0)
            : CAFrameRateRangeMake(60.0, 120.0, 60.0);
    } else {
        self.displayLink.preferredFramesPerSecond = enabled ? 120 : 60;
    }

    NSString *message = enabled ? @"高速化を有効にしました。" : @"高速化を無効にしました。";
    [self presentStatusAlertWithTitle:@"Fast Forward" message:message];
}

- (void)presentStatusAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.9 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (alert.presentingViewController) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }
    });
}

@end

#import "AUR3DSEmulatorViewController.h"
#import <MetalKit/MetalKit.h>
#import "../../../../src/core/bridge_cores/aurora3ds/CytrusEmulator.h"

@interface AUR3DSEmulatorViewController ()
@property (nonatomic, strong) NSURL *romURL;
@property (nonatomic, strong) MTKView *topView;
@property (nonatomic, strong) MTKView *bottomView;
@property (nonatomic, strong) UILabel *loadingLabel;
@property (nonatomic, assign) BOOL didStart;
@end

@implementation AUR3DSEmulatorViewController

- (instancetype)initWithROMURL:(NSURL *)romURL {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _romURL = romURL;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    self.topView = [[MTKView alloc] initWithFrame:CGRectZero];
    self.topView.translatesAutoresizingMaskIntoConstraints = NO;
    self.topView.device = MTLCreateSystemDefaultDevice();
    self.topView.enableSetNeedsDisplay = YES;
    self.topView.paused = YES;
    self.topView.layer.cornerRadius = 12.0;
    self.topView.clipsToBounds = YES;

    self.bottomView = [[MTKView alloc] initWithFrame:CGRectZero];
    self.bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomView.device = self.topView.device;
    self.bottomView.enableSetNeedsDisplay = YES;
    self.bottomView.paused = YES;
    self.bottomView.layer.cornerRadius = 12.0;
    self.bottomView.clipsToBounds = YES;

    self.loadingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.loadingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingLabel.text = @"Aurora3DS 起動中...";
    self.loadingLabel.textColor = [UIColor whiteColor];
    self.loadingLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];

    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [closeButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    closeButton.tintColor = [UIColor whiteColor];
    [closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.topView];
    [self.view addSubview:self.bottomView];
    [self.view addSubview:self.loadingLabel];
    [self.view addSubview:closeButton];

    [NSLayoutConstraint activateConstraints:@[
        [closeButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [closeButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [closeButton.widthAnchor constraintEqualToConstant:32],
        [closeButton.heightAnchor constraintEqualToConstant:32],

        [self.topView.topAnchor constraintEqualToAnchor:closeButton.bottomAnchor constant:12],
        [self.topView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [self.topView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [self.topView.heightAnchor constraintEqualToAnchor:self.topView.widthAnchor multiplier:(240.0/400.0)],

        [self.bottomView.topAnchor constraintEqualToAnchor:self.topView.bottomAnchor constant:12],
        [self.bottomView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
        [self.bottomView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
        [self.bottomView.heightAnchor constraintEqualToAnchor:self.bottomView.widthAnchor multiplier:(240.0/320.0)],

        [self.loadingLabel.topAnchor constraintEqualToAnchor:self.bottomView.bottomAnchor constant:12],
        [self.loadingLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor]
    ]];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bottomTapped:)];
    [self.bottomView addGestureRecognizer:tap];

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!self.didStart && self.topView.bounds.size.width > 0 && self.bottomView.bounds.size.width > 0) {
        self.didStart = YES;
        [self startAurora3DS];
    } else if (self.didStart) {
        CytrusEmulator *emu = [CytrusEmulator shared];
        UIInterfaceOrientation orientation = self.view.window.windowScene.interfaceOrientation;
        [emu orientationChanged:orientation metalView:self.topView secondary:NO];
        [emu orientationChanged:orientation metalView:self.bottomView secondary:YES];
    }
}

- (void)startAurora3DS {
    CytrusEmulator *emu = [CytrusEmulator shared];
    [emu allocate];
    [emu top:(CAMetalLayer *)self.topView.layer size:self.topView.bounds.size];
    [emu bottom:(CAMetalLayer *)self.bottomView.layer size:self.bottomView.bounds.size];

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
        [[CytrusEmulator shared] insert:weakSelf.romURL with:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.loadingLabel.text = @"Aurora3DS 実行中";
            });
        }];
    });
}

- (void)bottomTapped:(UITapGestureRecognizer *)gesture {
    CGPoint p = [gesture locationInView:self.bottomView];
    CytrusEmulator *emu = [CytrusEmulator shared];
    [emu touchBeganAtPoint:p];
    [emu touchEnded];
}

- (void)closeTapped {
    [self stopAurora3DS];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stopAurora3DS {
    if (!self.didStart) {
        return;
    }
    CytrusEmulator *emu = [CytrusEmulator shared];
    if ([emu running]) {
        [emu stop];
    }
    [emu deinitialize];
    [emu deallocate];
    self.didStart = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopAurora3DS];
}

@end

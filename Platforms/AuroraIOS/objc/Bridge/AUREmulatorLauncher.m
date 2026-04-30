#import "AUREmulatorLauncher.h"
#import "../Controllers/AUREmulatorViewController.h"

@implementation AUREmulatorLauncher
+ (UIViewController *)makeEmulatorViewControllerWithROMURL:(NSURL *)romURL
                                                   coreType:(EmulatorCoreType)coreType {
    return [[AUREmulatorViewController alloc] initWithROMURL:romURL coreType:coreType];
}
@end

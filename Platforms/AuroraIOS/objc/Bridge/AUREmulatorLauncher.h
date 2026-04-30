#import <UIKit/UIKit.h>
#import "../../../API/AUREmulatorCoreAPI.h"

NS_ASSUME_NONNULL_BEGIN

@interface AUREmulatorLauncher : NSObject
+ (nullable UIViewController *)makeEmulatorViewControllerWithROMURL:(NSURL *)romURL
                                                           coreType:(EmulatorCoreType)coreType;
@end

NS_ASSUME_NONNULL_END

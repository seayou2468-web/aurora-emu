#import <UIKit/UIKit.h>
#import "../../../API/AUREmulatorCoreAPI.h"

@interface AUREmulatorViewController : UIViewController
- (instancetype)initWithROMURL:(NSURL *)romURL coreType:(EmulatorCoreType)coreType;
@end

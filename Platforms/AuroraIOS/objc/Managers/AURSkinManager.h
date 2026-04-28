#import <Foundation/Foundation.h>
#import "../Models/AURDeltaSkin.h"
#import "../../../API/AUREmulatorCoreAPI.h"

@interface AURSkinManager : NSObject
+ (instancetype)sharedManager;
- (AURControllerSkin *)skinForCoreType:(EmulatorCoreType)coreType isLandscape:(BOOL)isLandscape;
- (void)importSkinAtURL:(NSURL *)url completion:(void(^)(BOOL success))completion;
- (NSArray<AURControllerSkin *> *)allSkins;
@end

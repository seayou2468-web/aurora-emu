#import <Foundation/Foundation.h>
#import "AURCoreSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface AURBridgeCoreAdapter : NSObject <AURCoreSession>
- (instancetype)initWithCoreType:(EmulatorCoreType)coreType;
@end

NS_ASSUME_NONNULL_END

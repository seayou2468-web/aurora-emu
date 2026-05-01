#import <Foundation/Foundation.h>
#import "./AURCoreSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface AURCoreSessionFactory : NSObject
+ (id<AURCoreSession>)sessionWithCoreType:(EmulatorCoreType)coreType;
+ (id<AURCoreSession>)sessionWithCoreType:(EmulatorCoreType)coreType
                           connectionKind:(AURCoreConnectionKind)connectionKind;
@end

NS_ASSUME_NONNULL_END

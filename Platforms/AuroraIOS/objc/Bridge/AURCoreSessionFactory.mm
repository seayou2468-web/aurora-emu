#import "./AURCoreSessionFactory.h"
#import "./AURBridgeCoreAdapter.h"
#import "./AURModuleCoreAdapter.h"

@implementation AURCoreSessionFactory

+ (id<AURCoreSession>)sessionWithCoreType:(EmulatorCoreType)coreType {
    const AURCoreConnectionKind connectionKind = AURCoreConnectionKindForCoreType(coreType);
    return [self sessionWithCoreType:coreType connectionKind:connectionKind];
}

+ (id<AURCoreSession>)sessionWithCoreType:(EmulatorCoreType)coreType
                           connectionKind:(AURCoreConnectionKind)connectionKind {
    switch (connectionKind) {
        case AUR_CORE_CONNECTION_MODULE_ADAPTER:
            return [[AURModuleCoreAdapter alloc] initWithCoreType:coreType];
        case AUR_CORE_CONNECTION_BRIDGE:
            return [[AURBridgeCoreAdapter alloc] initWithCoreType:coreType];
    }

    return [[AURModuleCoreAdapter alloc] initWithCoreType:coreType];
}

@end

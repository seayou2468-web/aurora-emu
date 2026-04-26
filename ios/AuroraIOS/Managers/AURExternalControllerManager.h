#import <Foundation/Foundation.h>
#import <GameController/GameController.h>
#include "../../../src/core/emulator_core_c_api.h"
#include "../../../src/core/aurora3ds/input_common/gcadapter/gc_adapter_bridge.h"

@protocol AURExternalControllerDelegate <NSObject>
- (void)externalControllerDidPressKey:(EmulatorKey)key;
- (void)externalControllerDidReleaseKey:(EmulatorKey)key;
@end

@interface AURExternalControllerManager : NSObject
@property (nonatomic, weak) id<AURExternalControllerDelegate> delegate;
+ (instancetype)sharedManager;
- (void)startMonitoring;
@end

#import <Foundation/Foundation.h>
#import "../../../API/AURCoreConnection.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AURCoreSession <NSObject>
@property (nonatomic, readonly) EmulatorCoreType coreType;
@property (nonatomic, readonly) AURCoreConnectionKind connectionKind;
@property (nonatomic, readonly, getter=isRunning) BOOL running;
@property (nonatomic, readonly) EmulatorVideoSpec videoSpec;

- (BOOL)loadBIOSAtPath:(NSString *)biosPath;
- (BOOL)loadROMAtURL:(NSURL *)romURL;
- (void)stepFrame;
- (void)setKey:(EmulatorKey)key pressed:(BOOL)pressed;

- (nullable const uint32_t *)frameBufferWithPixelCount:(size_t *)pixelCount;
- (nullable NSString *)lastError;
@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AURLogManager : NSObject

+ (void)startLogging;
+ (void)logInfo:(NSString *)message;
+ (void)logError:(NSString *)message;
+ (nullable NSString *)currentLogFilePath;

@end

NS_ASSUME_NONNULL_END

#import "AURLogManager.h"

#include <signal.h>
#include <fcntl.h>
#include <unistd.h>

@interface AURLogManager ()
@end

@implementation AURLogManager

static NSFileHandle *_logFileHandle = nil;
static NSString *_logFilePath = nil;
static dispatch_queue_t _logQueue;

static void AURWriteSignalLog(int signalNumber) {
    NSString *line = [NSString stringWithFormat:@"[FATAL] signal=%d\n", signalNumber];
    NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
    if (_logFileHandle) {
        @try {
            [_logFileHandle seekToEndOfFile];
            [_logFileHandle writeData:data];
            [_logFileHandle synchronizeFile];
        } @catch (__unused NSException *exception) {
        }
    }
}

static void AURSignalHandler(int signalNumber) {
    AURWriteSignalLog(signalNumber);
    signal(signalNumber, SIG_DFL);
    raise(signalNumber);
}

static void AURUncaughtExceptionHandler(NSException *exception) {
    NSMutableString *line = [NSMutableString stringWithFormat:@"[UNCAUGHT] %@\n", exception.reason ?: @"(no reason)"];
    [line appendFormat:@"name=%@\n", exception.name ?: @"(no name)"];
    [line appendFormat:@"stack=%@\n", exception.callStackSymbols ?: @[]];
    [AURLogManager logError:line];
}

+ (NSString *)_timestampString {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    });
    return [formatter stringFromDate:[NSDate date]];
}

+ (NSString *)_logDirectoryPath {
    NSArray<NSURL *> *urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsURL = urls.firstObject;
    NSURL *logDirectoryURL = [documentsURL URLByAppendingPathComponent:@"Logs" isDirectory:YES];
    return logDirectoryURL.path;
}

+ (void)_appendLine:(NSString *)line {
    if (!_logFileHandle || line.length == 0) {
        return;
    }
    NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return;
    }
    dispatch_async(_logQueue, ^{
        @try {
            [_logFileHandle seekToEndOfFile];
            [_logFileHandle writeData:data];
        } @catch (__unused NSException *exception) {
        }
    });
}

+ (void)startLogging {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _logQueue = dispatch_queue_create("com.aurora.log.queue", DISPATCH_QUEUE_SERIAL);

        NSString *logDirectory = [self _logDirectoryPath];
        NSError *dirError = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:logDirectory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&dirError];

        NSString *fileName = [NSString stringWithFormat:@"aurora-%@.log", [[NSUUID UUID] UUIDString]];
        _logFilePath = [logDirectory stringByAppendingPathComponent:fileName];

        if (![[NSFileManager defaultManager] createFileAtPath:_logFilePath contents:nil attributes:nil]) {
            NSLog(@"[AUR][Log] Failed to create log file at %@", _logFilePath);
            return;
        }

        _logFileHandle = [NSFileHandle fileHandleForWritingAtPath:_logFilePath];
        if (!_logFileHandle) {
            NSLog(@"[AUR][Log] Failed to open log file at %@", _logFilePath);
            return;
        }

        int fileDescriptor = open(_logFilePath.UTF8String, O_WRONLY | O_APPEND);
        if (fileDescriptor >= 0) {
            dup2(fileDescriptor, STDERR_FILENO);
            dup2(fileDescriptor, STDOUT_FILENO);
            close(fileDescriptor);
        }

        NSSetUncaughtExceptionHandler(&AURUncaughtExceptionHandler);
        signal(SIGABRT, AURSignalHandler);
        signal(SIGILL, AURSignalHandler);
        signal(SIGSEGV, AURSignalHandler);
        signal(SIGFPE, AURSignalHandler);
        signal(SIGBUS, AURSignalHandler);
        signal(SIGPIPE, AURSignalHandler);

        NSString *startup = [NSString stringWithFormat:@"[%@] [INFO] Aurora log capture started. file=%@\n",
                             [self _timestampString], _logFilePath];
        [self _appendLine:startup];

        if (dirError) {
            NSString *errorLine = [NSString stringWithFormat:@"[%@] [ERROR] Failed to create log directory: %@\n",
                                   [self _timestampString], dirError.localizedDescription ?: @"unknown"]; 
            [self _appendLine:errorLine];
        }
    });
}

+ (void)logInfo:(NSString *)message {
    if (message.length == 0) return;
    NSString *line = [NSString stringWithFormat:@"[%@] [INFO] %@\n", [self _timestampString], message];
    NSLog(@"%@", message);
    [self _appendLine:line];
}

+ (void)logError:(NSString *)message {
    if (message.length == 0) return;
    NSString *line = [NSString stringWithFormat:@"[%@] [ERROR] %@\n", [self _timestampString], message];
    NSLog(@"[ERROR] %@", message);
    [self _appendLine:line];
}

+ (NSString *)currentLogFilePath {
    return _logFilePath;
}

@end

#import <CoreServices/CoreServices.h>
#import "ZEReplayManager.h"
#import "ZEReplay.h"

@interface ZEReplayManager ()
@property (readonly) NSString *accountsPath;
@end

void directoryChanged(ConstFSEventStreamRef streamRef,
                    void *clientCallBackInfo,
                    size_t numEvents,
                    void *eventPaths,
                    const FSEventStreamEventFlags eventFlags[],
                    const FSEventStreamEventId eventIds[]) {
    NSArray *paths = eventPaths;
    for (NSString *s in paths) {
        [[ZEReplayManager sharedManager] addFileWithPath:s];
    }
}

@implementation ZEReplayManager

+ (ZEReplayManager *)sharedManager {
    static ZEReplayManager *sharedManager = nil;
    
    if (!sharedManager) {
        sharedManager = [[self alloc] init];
    }
    
    return sharedManager;
}

- (void)addFileWithPath:(NSString *)path {
    // TODO find hash of replay and do nothing if already processed
    NSString *account = nil;
    for (NSString *s in [path pathComponents]) {
        if ([s isEqualToString:@"Replays"]) {
            break;
        }
        
        account = s;
    }
    [[[ZEReplay alloc] initWithPath:path account:account] autorelease];
}

- (void)parseReplay:(NSString *)replay account:(NSString *)account {
    [[ZEReplay alloc] initWithPath:replay account:account];
}

- (void)parseAllReplayFiles {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *a = [manager contentsOfDirectoryAtPath:[self accountsPath] error:NULL];
    
    for (NSString *file in a) {
        BOOL isDirectory;
        NSString *path = [[self accountsPath] stringByAppendingPathComponent:file];
        if ([manager fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            NSArray *accounts = [manager contentsOfDirectoryAtPath:path error:NULL];
            for (NSString *account in accounts) {
                NSString *replaysPath = [[[path stringByAppendingPathComponent:account]
                                         stringByAppendingPathComponent:@"Replays"] 
                                         stringByAppendingPathComponent:@"Multiplayer"];
                
                
                if ([manager fileExistsAtPath:replaysPath isDirectory:&isDirectory] && isDirectory) {
                    NSArray *replays = [manager contentsOfDirectoryAtPath:replaysPath error:NULL];
                    for (NSString *replay in replays) {
                        [self parseReplay:[replaysPath stringByAppendingPathComponent:replay] 
                                  account:account];
                    }
                }
            }
        }
    }
}

- (void)startMonitoring {
    FSEventStreamRef stream = FSEventStreamCreate(NULL,
                                 &directoryChanged,
                                 NULL,
                                 (CFArrayRef)[NSArray arrayWithObject:self.accountsPath],
                                 kFSEventStreamEventIdSinceNow,
                                 3.0f,
                                 kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes);
    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(stream);
    [self parseAllReplayFiles];
}

- (NSString *)accountsPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    
    if (paths.count == 0) return nil;
    
    NSString *accounts = [[paths lastObject] stringByAppendingPathComponent:@"Blizzard/StarCraft II/Accounts"];

    if ([fileManager fileExistsAtPath:accounts isDirectory:&isDirectory] &&
        isDirectory) {
        return accounts;
    } else {
        return nil;
    }
}

@end

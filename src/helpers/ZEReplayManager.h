void directoryChanged(ConstFSEventStreamRef streamRef,
                    void *clientCallBackInfo,
                    size_t numEvents,
                    void *eventPaths,
                    const FSEventStreamEventFlags eventFlags[],
                    const FSEventStreamEventId eventIds[]);

@interface ZEReplayManager : NSObject
+ (ZEReplayManager *)sharedManager;
- (void)startMonitoring;
- (void)addFileWithPath:(NSString *)path;
@end

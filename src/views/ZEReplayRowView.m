#import "ZEReplayRowView.h"

@implementation ZEReplayRowView
@synthesize teamOne, teamTwo;

- (void)dealloc {
    self.teamOne = nil;
    self.teamTwo = nil;
    [super dealloc];
}

- (id) initWithCoder: (NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        self.teamOne = [coder decodeObjectForKey:@"teamOne"];
        self.teamTwo = [coder decodeObjectForKey:@"teamTwo"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.teamOne forKey:@"teamOne"];
    [coder encodeObject:self.teamTwo forKey:@"teamTwo"];
    [super encodeWithCoder:coder];
}

@end

#import <Cocoa/Cocoa.h>
#import "SRButtonCell.h"

@implementation SRButtonCell
@synthesize selected, mouseOver;

- (void)setState:(NSInteger)a {
    [super setState:a];
    self.selected = a == 1;
}

- (void)mouseEntered:(NSEvent *)theEvent {
    self.mouseOver = YES;
    [super mouseEntered:theEvent];
}
- (void)mouseExited:(NSEvent *)theEvent {
    self.mouseOver = NO;
    [super mouseExited:theEvent];
}


- (NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView {
	if (self.selected || self.mouseOver) {
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        shadow.shadowColor = [NSColor colorWithDeviceWhite:0.2 alpha:1.0f];

        shadow.shadowOffset = CGSizeMake(0, -0.5);
        NSAttributedString *attributedTitle = [[[NSAttributedString alloc] 
                                                initWithString:[title string]
                                                attributes:
                                                [NSDictionary dictionaryWithObjectsAndKeys:
                                                 shadow,
                                                 NSShadowAttributeName,
                                                 [NSColor whiteColor],
                                                 NSForegroundColorAttributeName,
                                                 [NSFont boldSystemFontOfSize:11],
                                                 NSFontAttributeName,
                                                 nil]] 
                                               autorelease];
        
        return [super drawTitle:attributedTitle withFrame:frame inView:controlView];
    } else {
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        shadow.shadowColor = [NSColor whiteColor];
        shadow.shadowOffset = CGSizeMake(0, -1);
        NSAttributedString *attributedTitle = [[[NSAttributedString alloc] 
                                      initWithString:[title string]
                                      attributes:
                                      [NSDictionary dictionaryWithObjectsAndKeys:
                                       shadow,
                                       NSShadowAttributeName,
                                       [NSColor colorWithDeviceWhite:0.25 alpha:1.0f],
                                       NSForegroundColorAttributeName,
                                       [NSFont boldSystemFontOfSize:11],
                                       NSFontAttributeName,
                                       nil]] 
                                               autorelease];
        
        return [super drawTitle:attributedTitle withFrame:frame inView:controlView];
    }
}

@end

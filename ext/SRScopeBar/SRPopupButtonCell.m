#import <Cocoa/Cocoa.h>
#import "SRPopUpButtonCell.h"

@implementation SRPopUpButtonCell

- (NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView {

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
    CGRect r = frame;
    r.origin.y -= 1;
    return [super drawTitle:attributedTitle withFrame:r inView:controlView];
}

@end

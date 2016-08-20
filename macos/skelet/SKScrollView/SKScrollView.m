#import "SKScrollView.h"
#import "SKRullerView.h"


@implementation SKScrollView

#pragma mark Superclass Methods


+ (Class)rulerViewClass
{
    return [SKRullerView class];
}

- (nonnull instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setHasVerticalRuler:YES];
        [self setHasHorizontalRuler:NO];
        [self setRulersVisible:YES];
    }
    return self;
}

- (void)setFont:(NSFont *)font
{
  [(SKRullerView *)[self lineNumberView] setFont:font];
}


- (void)dealloc
{
    if ([[self documentView] isKindOfClass:[NSTextView class]]) {
        [(NSTextView *)[self documentView] removeObserver:self forKeyPath:@"layoutOrientation"];
    }
}


- (void)setDocumentView:(nullable id)documentView
{
    if ([documentView isKindOfClass:[NSTextView class]]) {
        [(NSTextView *)documentView addObserver:self forKeyPath:@"layoutOrientation" options:NSKeyValueObservingOptionNew context:nil];
    }
    [super setDocumentView:documentView];
}


- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *, id> *)change context:(nullable void *)context
{
    if ([keyPath isEqual:@"layoutOrientation"]) {
        switch ([self layoutOrientation]) {
            case NSTextLayoutOrientationHorizontal:
                [self setHasVerticalRuler:YES];
                [self setHasHorizontalRuler:NO];
                break;

            case NSTextLayoutOrientationVertical:
                [self setHasVerticalRuler:NO];
                [self setHasHorizontalRuler:YES];
                break;
        };
    }
}



#pragma mark Public Methods


- (void)invalidateLineNumber
{
    [[self lineNumberView] setNeedsDisplay:YES];
}

#pragma mark Private Methods

- (NSTextLayoutOrientation)layoutOrientation
{
    if (![self documentView] || ![[self documentView] isKindOfClass:[NSTextView class]]) { return NSTextLayoutOrientationHorizontal; }  // documentView is "unsafe"

    return [(NSTextView *)[self documentView] layoutOrientation];
}


- (nullable NSRulerView *)lineNumberView
{
    switch ([self layoutOrientation]) {
        case NSTextLayoutOrientationHorizontal:
            return [self verticalRulerView];

        case NSTextLayoutOrientationVertical:
            return [self horizontalRulerView];

      default:
        return [self verticalRulerView];
    }
}

@end

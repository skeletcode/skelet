#import "Cocoa/Cocoa.h"
#import "SKTextView.h"
#import "RCTText.h"
#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"
#import "NSView+React.h"
#import "SKLayoutManager.h"
#import "SKScrollView.h"

// constant
const NSInteger kNoMenuItem = -1;


@implementation SKTextView
{
  RCTEventDispatcher *_eventDispatcher;
  BOOL _jsRequestingFirstResponder;
  NSInteger _nativeEventCount;
  NSDate *lastUpdate;
  CGFloat _padding;
  SKLayoutManager *_layoutManager;
  NSTextContainer *_container;
  NSUndoManager *_undoManager;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
  RCTAssertParam(eventDispatcher);

  if ((self = [super initWithFrame:CGRectZero])) {

    _eventDispatcher = eventDispatcher;
    _textStorage= [NSTextStorage new];

    _layoutManager = [[SKLayoutManager alloc] init];
    _layoutManager.delegate = self;
    [_textStorage addLayoutManager:_layoutManager];
    [_layoutManager setBackgroundLayoutEnabled:YES];
    [_layoutManager setUsesAntialias:YES];

    _container = [[NSTextContainer alloc] init];
    [_layoutManager addTextContainer:_container];
    [_layoutManager ensureLayoutForTextContainer:_container];

    
    _textView = [[SKInnerTextView alloc] initWithFrame:NSZeroRect textContainer:_container];
    _textView.autoTabExpandEnabled = YES;
    _textView.autoIndent = YES;
    _textView.smartIndent = YES;
    _textView.balanceBrackets = YES;
    [_textView setDelegate:self];
    _undoManager = [[NSUndoManager alloc] init];

    _scrollView = [[SKScrollView alloc] initWithFrame:NSZeroRect];
    [_scrollView setDocumentView:_textView];
    lastUpdate = [NSDate dateWithTimeIntervalSince1970:0];
    _padding = 0;
    [self addSubview:_scrollView];
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

- (NSString *)text
{
  return [_textView string];
}

- (BOOL)isReactRootView
{
  return NO;
}

- (void)setTextStorage:(NSTextStorage *)textStorage
{
  _textStorage = textStorage;
  [_textStorage addLayoutManager:_layoutManager];
}

- (void)setAttributedString:(NSAttributedString *)attributedString
{
  if ([[attributedString string] isEqualToString:_textStorage.string]) {
    return;
  }
  NSArray <NSValue *> *previousRanges = [_textView selectedRanges];
  [_textStorage setAttributedString:attributedString];
  [_textView setSelectedRanges:previousRanges];
  lastUpdate = [NSDate date];
}

- (void)updateFont
{
  [_scrollView setFont:_textView.font];
}

- (void)setColor:(NSColor *)color
{
  _textView.textColor = color;
  [_textView applyTypingAttributes];
}

- (void)setPadding:(CGFloat )padding
{
  if (_padding != padding) {
    NSRect frame = self.frame;
    _padding = padding;
    frame.origin.x = frame.origin.x + padding;
    frame.origin.x = frame.origin.y + padding;
    frame.size.width = frame.size.width - padding;
    frame.size.height = frame.size.height - padding;
    self.frame = frame;
  }
}

- (void)_addAttribute:(NSString *)attribute withValue:(id)attributeValue toAttributedString:(NSMutableAttributedString *)attributedString
{
  [attributedString enumerateAttribute:attribute inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
    if (!value && attributeValue) {
      [attributedString addAttribute:attribute value:attributeValue range:range];
    }
  }];
}

- (void)setText:(NSString *)text
{
  NSInteger eventLag = _nativeEventCount - _mostRecentEventCount;
  if (eventLag == 0 && ![text isEqualToString:[_textView string]]) {
    [_textView setString:text];
    [_scrollView invalidateLineNumber];
  } else if (eventLag > RCTTextUpdateLagWarningThreshold) {
    RCTLogWarn(@"Native TextInput(%@) is %zd events ahead of JS - try to make your JS faster.", self.text, eventLag);
  }
}

- (void)highlightRange:(NSRange)range attributes:(NSDictionary<NSString *, NSValue *> *)attributes {
  if ([attributes count] == 0) { return; }
  for (NSString *attributeName in attributes) {
    for (NSLayoutManager *layoutManager in [_textStorage layoutManagers]) {
      [layoutManager removeTemporaryAttribute:attributeName
                            forCharacterRange:range];

      // TODO: speed up, replacing with Enum and switch statement
      if ([attributeName isEqualToString:NSForegroundColorAttributeName]) {
        [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName
                                       value:[RCTConvert NSColor:attributes[attributeName]] forCharacterRange:range];
      } else {
        [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName
                                       value:[RCTConvert NSColor:attributes[attributeName]] forCharacterRange:range];
      }

    }
  }
}

- (void)textDidChange:(NSNotification *)aNotification
{
  _nativeEventCount++;
  [_eventDispatcher sendTextEventWithType:RCTTextEventTypeChange
                                 reactTag:self.reactTag
                                     text:[_textStorage string]
                                     key:nil
                               eventCount:_nativeEventCount];
}


- (void)textViewDidChangeSelection:(NSNotification *)aNotification
{
  [_scrollView invalidateLineNumber];
  [self highlightCurrentLine];

}

- (void)highlightCurrentLine
// ------------------------------------------------------
{
  if (![[self window] isVisible]) { return; }

  NSLayoutManager *layoutManager = [_textView layoutManager];
  NSRect rect;


  NSRange lineRange = [[_textView string] lineRangeForRange:[_textView selectedRange]];
  lineRange.length -= (lineRange.length > 0) ? 1 : 0;  // remove line ending
  NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:lineRange actualCharacterRange:NULL];

  rect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:[_textView textContainer]];
  rect.size.width = [[_textView textContainer] containerSize].width;


  CGFloat padding = [[_textView textContainer] lineFragmentPadding];
  rect.origin.x = padding;
  rect.size.width -= 2 * padding;
  rect = NSOffsetRect(rect, [_textView textContainerOrigin].x, [_textView textContainerOrigin].y);

  if (!NSEqualRects([_textView highlightLineRect], rect)) {
    // clear previous highlihght
    [_textView setNeedsDisplayInRect:[_textView highlightLineRect] avoidAdditionalLayout:YES];

    // draw highlight
    [_textView setHighlightLineRect:rect];
    [_textView setNeedsDisplayInRect:rect avoidAdditionalLayout:YES];
  }
}

- (void)setFrame:(NSRect)frame
{
  [super setFrame:frame];
  frame.origin.y = 0;
  _scrollView.frame = frame;
  [self setPadding:_padding];
}


- (NSUndoManager *)undoManagerForTextView:(NSTextView *)aTextView {
  return _undoManager;
}

@end


/*
 * Heavily based on https://github.com/coteditor/CotEditor
 * © 2005-2009 nakamuxu, © 2011, 2014 usami-k, © 2013-2016 1024jp.
 **/
@import CoreText;

#import "SKRullerView.h"
#import "SKLayoutManager.h"

static const NSUInteger MIN_NUMBER_OF_DIGITS = 3;
static const CGFloat MIN_HORIZONTAL_THICKNESS = 32.0;
static const CGFloat MIN_VERTICAL_THICKNESS = 32.0;
static const CGFloat LINE_NUMBER_PADDING = 4.0;
static const CGFloat FONT_SIZE_FACTOR = 0.9;

// dragging info keys
static NSString * _Nonnull const DraggingSelectedRangesKey = @"selectedRanges";
static NSString * _Nonnull const DraggingIndexKey = @"index";

@implementation NSString (Counting)

- (NSUInteger)numberOfLinesInRange:(NSRange)range includingLastNewLine:(BOOL)includingLastNewLine
{
  if ([self length] == 0 || range.length == 0) { return 0; }

  __block NSUInteger count = 0;

  [self enumerateSubstringsInRange:range
                           options:NSStringEnumerationByLines | NSStringEnumerationSubstringNotRequired
                        usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop)
   {
     count++;
   }];

  if (includingLastNewLine && [[NSCharacterSet newlineCharacterSet] characterIsMember:[self characterAtIndex:NSMaxRange(range) - 1]]) {
    count++;
  }

  return count;
}


- (NSUInteger)numberOfLines
{
  return [self numberOfLinesInRange:NSMakeRange(0, [self length]) includingLastNewLine:NO];
}


- (NSUInteger)lineNumberAtIndex:(NSUInteger)index
{
  if ([self length] == 0 || index == 0) { return 1; }

  NSUInteger number = [self numberOfLinesInRange:NSMakeRange(0, index) includingLastNewLine:YES];

  return number;
}

@end

@interface SKRullerView ()

@property (nonatomic, nullable, weak) NSTimer *draggingTimer;

@end


#pragma mark -

@implementation SKRullerView

static CGFontRef LineNumberFont;
static CGFontRef BoldLineNumberFont;


#pragma mark Superclass Methods

- (nonnull instancetype)initWithScrollView:(nullable NSScrollView *)scrollView orientation:(NSRulerOrientation)orientation
{
    self = [super initWithScrollView:scrollView orientation:orientation];
    if (self) {
      NSFont *font = [NSFont fontWithName:@"AvenirNextCondensed-Regular" size:0] ? : [NSFont paletteFontOfSize:0];
      [self setFont:font];
    }
    return self;
}

- (void)setFont:(NSFont *)font
{
  NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];

  LineNumberFont = CGFontCreateWithFontName((CFStringRef)[font fontName]);
  BoldLineNumberFont = CGFontCreateWithFontName((CFStringRef)[boldFont fontName]);
}


- (void)viewDidMoveToSuperview
{
    [super viewDidMoveToSuperview];

    CGFloat thickness = [self orientation] == NSHorizontalRuler ? MIN_HORIZONTAL_THICKNESS : MIN_VERTICAL_THICKNESS;
    [self setRuleThickness:thickness];
}


- (void)drawRect:(NSRect)dirtyRect
{
//  NSColor *counterColor = [NSColor blackColor];//[[[self textView] theme] isDarkTheme] ? [NSColor whiteColor] : [NSColor blackColor];
//  NSColor *textColor = [NSColor greenColor];//[[[self textView] theme] weakTextColor];

    // fill background
    //[[[NSColor blackColor] colorWithAlphaComponent:0.02] set];
    //[NSBezierPath fillRect:dirtyRect];

    // draw frame border (1px)
   // [[textColor colorWithAlphaComponent:0.3] set];
//    switch ([self orientation]) {
//        case NSVerticalRuler:
//            [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(dirtyRect) - 0.5, NSMaxY(dirtyRect))
//                                      toPoint:NSMakePoint(NSMaxX(dirtyRect) - 0.5, NSMinY(dirtyRect))];
//            break;
//
//        case NSHorizontalRuler:
//            [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(dirtyRect), NSMaxY(dirtyRect) - 0.5)
//                                      toPoint:NSMakePoint(NSMaxX(dirtyRect), NSMaxY(dirtyRect) - 0.5)];
//            break;
//    }
//
  [self drawHashMarksAndLabelsInRect:dirtyRect];
}


- (void)drawHashMarksAndLabelsInRect:(NSRect)rect
{
  NSString *string = [[self textView] string];

  if ([string length] == 0) { return; }

  SKLayoutManager *layoutManager = (SKLayoutManager *)[[self textView] layoutManager];
  NSColor *textColor = [NSColor lightGrayColor];
  NSColor *boldColor = [NSColor blackColor];

  // set graphics context
  CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  CGContextSaveGState(context);

  // setup font
  CGFloat masterFontSize = [[[self textView] font] pointSize];
  CGFloat fontSize = MIN(round(FONT_SIZE_FACTOR * masterFontSize), masterFontSize);
  CTFontRef font = CTFontCreateWithGraphicsFont(LineNumberFont, fontSize, nil, nil);

  CGFloat tickLength = ceil(fontSize / 3);

  CGContextSetFont(context, LineNumberFont);
  CGContextSetFontSize(context, fontSize);
  CGContextSetFillColorWithColor(context, [textColor CGColor]);

  // prepare glyphs
  CGGlyph wrappedMarkGlyph;
  const unichar dash = '-';
  CTFontGetGlyphsForCharacters(font, &dash, &wrappedMarkGlyph, 1);

  CGGlyph digitGlyphs[10];
  const unichar numbers[10] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};
  CTFontGetGlyphsForCharacters(font, numbers, digitGlyphs, 10);

  // calc character width as monospaced font
  CGSize advance;
  CTFontGetAdvancesForGlyphs(font, kCTFontOrientationHorizontal, &digitGlyphs[8], &advance, 1);  // use '8' to get width
  CGFloat charWidth = advance.width;

  // prepare frame width
  CGFloat ruleThickness = [self ruleThickness];

  // adjust text drawing coordinate
  NSPoint relativePoint = [self convertPoint:NSZeroPoint fromView:[self textView]];
  NSPoint inset = [[self textView] textContainerOrigin];
  CGFloat diff = masterFontSize - fontSize;
  CGFloat ascent = CTFontGetAscent(font);
  CGAffineTransform transform = CGAffineTransformIdentity;
  transform = CGAffineTransformScale(transform, 1.0, -1.0);  // flip
  transform = CGAffineTransformTranslate(transform, -LINE_NUMBER_PADDING, -relativePoint.y - inset.y - diff - ascent);
  CGContextSetTextMatrix(context, transform);
  CFRelease(font);

  // add enough buffer to avoid broken drawing on Mountain Lion (10.8) with scroller (2015-07)
  NSRect visibleRect = [[self scrollView] documentVisibleRect];
  visibleRect.size.height += fontSize;

  // get glyph range which line number should be drawn
  NSRange visibleGlyphRange = [layoutManager glyphRangeForBoundingRect:visibleRect
                                                       inTextContainer:[[self textView] textContainer]];

  BOOL isVerticalText = [self orientation] == NSHorizontalRuler;
  NSUInteger tailGlyphIndex = [layoutManager glyphIndexForCharacterAtIndex:[string length]];

  // get multiple selection
  NSMutableArray<NSValue *> *selectedLineRanges = [NSMutableArray arrayWithCapacity:[[[self textView] selectedRanges] count]];
  for (NSValue *rangeValue in [[self textView] selectedRanges]) {
    NSRange selectedLineRange = [string lineRangeForRange:[rangeValue rangeValue]];
    [selectedLineRanges addObject:[NSValue valueWithRange:selectedLineRange]];
  }

  // draw line number block
  CGGlyph *digitGlyphsPtr = digitGlyphs;
  void (^draw_number)(NSUInteger, NSUInteger, CGFloat, BOOL, BOOL) = ^(NSUInteger lineNumber, NSUInteger lastLineNumber, CGFloat y, BOOL drawsNumber, BOOL isBold)
  {
    if (isVerticalText) {
      // translate y position to horizontal axis
      y += relativePoint.x - masterFontSize / 2 - inset.y;

      // draw ticks on vertical text
      CGFloat x = round(y) - 0.5;
      CGContextMoveToPoint(context, x, ruleThickness);
      CGContextAddLineToPoint(context, x, ruleThickness - tickLength);
    }

    if (!drawsNumber) { return; }

    NSUInteger digit = numberOfDigits(lineNumber);

    // calculate base position
    CGPoint position;
    if (isVerticalText) {
      position = CGPointMake(ceil(y + charWidth * (digit + 1) / 2), ruleThickness + tickLength - 2);
    } else {
      position = CGPointMake(ruleThickness, y);
    }

    // get glyphs and positions
    CGGlyph glyphs[digit];
    CGPoint positions[digit];
    for (NSUInteger i = 0; i < digit; i++) {
      position.x -= charWidth;

      positions[i] = position;
      glyphs[i] = digitGlyphsPtr[numberAt(i, lineNumber)];
    }

    if (isBold) {
      CGContextSetFont(context, BoldLineNumberFont);
      CGContextSetFillColorWithColor(context, [boldColor CGColor]);
    }

    // draw
    CGContextShowGlyphsAtPositions(context, glyphs, positions, digit);

    if (isBold) {
      // back to the regular font
      CGContextSetFont(context, LineNumberFont);
      CGContextSetFillColorWithColor(context, [textColor CGColor]);
    }

  };

  // counters
  NSUInteger glyphCount = visibleGlyphRange.location;
  NSUInteger lineNumber = 1;
  NSUInteger lastLineNumber = 0;

  // count lines until visible
  lineNumber += [string numberOfLinesInRange:NSMakeRange(0, [layoutManager characterIndexForGlyphAtIndex:visibleGlyphRange.location])
                        includingLastNewLine:NO];

  // draw visible line numbers
  for (NSUInteger glyphIndex = visibleGlyphRange.location; glyphIndex < NSMaxRange(visibleGlyphRange); lineNumber++) { // count "real" lines
    NSUInteger charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
    NSRange lineRange = [string lineRangeForRange:NSMakeRange(charIndex, 0)];
    glyphIndex = NSMaxRange([layoutManager glyphRangeForCharacterRange:lineRange actualCharacterRange:NULL]);

    // check if line is selected
    BOOL isSelected = NO;
    for (NSValue *selectedLineValue in selectedLineRanges) {
      if (NSLocationInRange(lineRange.location, [selectedLineValue rangeValue])) {
        isSelected = YES;
        break;
      }
    }

    while (glyphCount < glyphIndex) { // handle wrapped lines
      NSRange range;
      //[layoutManager lineHeight]
      NSRect lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:&range withoutAdditionalLayout:YES];
      CGFloat y = - NSMinY(lineRect) - [self textView].defaultParagraphStyle.lineSpacing;
      if (lastLineNumber == lineNumber) {  // wrapped line
        if (!isVerticalText) {
          CGPoint position = CGPointMake(ruleThickness - charWidth, y);
          CGContextShowGlyphsAtPositions(context, &wrappedMarkGlyph, &position, 1);  // draw wrapped mark
        }

      } else {  // new line
        BOOL drawsNumber = (isSelected || !isVerticalText || lineNumber % 5 == 0 || lineNumber == 1);
        draw_number(lineNumber, lastLineNumber, y, drawsNumber, isSelected);
      }

      glyphCount = NSMaxRange(range);

      // draw last line number on vertical text anyway
      if (isVerticalText &&  // vertical text
          lastLineNumber != lineNumber &&  // new line
          isVerticalText && lineNumber != 1 && lineNumber % 5 != 0 &&  // not yet drawn
          tailGlyphIndex == glyphIndex &&  // last line
          ![layoutManager extraLineFragmentTextContainer])  // no extra number
      {
        draw_number(lineNumber, lastLineNumber, y, YES, isSelected);
      }

      lastLineNumber = lineNumber;
    }
  }

  // draw the last "extra" line number
  if ([layoutManager extraLineFragmentTextContainer]) {
    NSRect lineRect = [layoutManager extraLineFragmentUsedRect];
    NSRange lastSelectedRange = [[selectedLineRanges lastObject] rangeValue];
    BOOL isSelected = (lastSelectedRange.length == 0) && ([string length] == NSMaxRange(lastSelectedRange));
    CGFloat y = -NSMinY(lineRect);

    draw_number(lineNumber, lastLineNumber, y, YES, isSelected);
  }

  // draw vertical text tics
  if (isVerticalText) {
    CGContextSetStrokeColorWithColor(context, [[textColor colorWithAlphaComponent:0.6] CGColor]);
    CGContextStrokePath(context);
  }

  CGContextRestoreGState(context);

  // adjust thickness
  CGFloat requiredThickness;
  if (isVerticalText) {
    requiredThickness = MAX(fontSize + tickLength + 2 * LINE_NUMBER_PADDING, MIN_HORIZONTAL_THICKNESS);
  } else {
    // count rest invisible lines
    // -> The view width depends on the number of digits of the total line numbers.
    //    As it's quite dengerous to change width of line number view on scrolling dynamically.
    NSUInteger charIndex = [layoutManager characterIndexForGlyphAtIndex:NSMaxRange(visibleGlyphRange)];
    if ([string length] > charIndex) {
      lineNumber += [string numberOfLinesInRange:NSMakeRange(charIndex, [string length] - charIndex)
                            includingLastNewLine:NO];
    }

    NSUInteger length = MAX(numberOfDigits(lineNumber), MIN_NUMBER_OF_DIGITS);
    requiredThickness = MAX(length * charWidth + 3 * LINE_NUMBER_PADDING, MIN_VERTICAL_THICKNESS);
  }
  [self setRuleThickness:ceil(requiredThickness)];
}

- (BOOL)isOpaque
{
    return NO;
}


/// remove extra thickness
- (CGFloat)requiredThickness
{
    if ([self orientation] == NSHorizontalRuler) {
        return [self ruleThickness];
    }
    return MAX(MIN_VERTICAL_THICKNESS, [self ruleThickness]);
}



#pragma mark Private Methods

- (nullable NSTextView *)textView
{
    return (NSTextView *)[[self scrollView] documentView];
}



#pragma mark Private C Functions

/// digits of input number
NSUInteger numberOfDigits(NSUInteger number) { return (NSUInteger)log10(number) + 1; }

/// number at the desired place of input number
NSUInteger numberAt(NSUInteger place, NSUInteger number) { return (number % (NSUInteger)pow(10, place + 1)) / pow(10, place); }

@end




#pragma mark -

@implementation SKRullerView (LineSelecting)

#pragma mark Superclass Methods

// ------------------------------------------------------
/// start selecting correspondent lines in text view with drag / click event
- (void)mouseDown:(nonnull NSEvent *)theEvent
// ------------------------------------------------------
{
    // get start point
//    NSPoint point = [[self window] convertRectToScreen:NSMakeRect([theEvent locationInWindow].x,
//                                                                  [theEvent locationInWindow].y, 0, 0)].origin;
//    NSUInteger index = [[self textView] characterIndexForPoint:point];
//
//    // repeat while dragging
//    [self setDraggingTimer:[NSTimer scheduledTimerWithTimeInterval:0.05
//                                                            target:self
//                                                          selector:@selector(selectLines:)
//                                                          userInfo:@{DraggingIndexKey: @(index),
//                                                                     DraggingSelectedRangesKey: [[self textView] selectedRanges]}
//                                                           repeats:YES]];
//
//    [self selectLines:nil];  // for single click event
}


// ------------------------------------------------------
/// end selecting correspondent lines in text view with drag event
- (void)mouseUp:(nonnull NSEvent *)theEvent
// ------------------------------------------------------
{
    [[self draggingTimer] invalidate];
    [self setDraggingTimer:nil];

    // settle selection
    //   -> in `selectLines:`, `stillSelecting` flag is always YES
    [[self textView] setSelectedRanges:[[self textView] selectedRanges]];
}



#pragma mark Private Methods

- (void)selectLines:(nullable NSTimer *)timer
{
    NSTextView *textView = [self textView];
    NSPoint point = [NSEvent mouseLocation];  // screen based point

    // scroll text view if needed
    CGFloat y = [self convertPoint:[[self window] convertRectFromScreen:NSMakeRect(point.x, point.y, 0, 0)].origin
                          fromView:nil].y;
    if (y < 0) {
        [textView scrollLineUp:nil];
    } else if (y > NSHeight([self bounds])) {
        [textView scrollLineDown:nil];
    }

    // select lines
    NSUInteger currentIndex = [textView characterIndexForPoint:point];
    NSUInteger clickedIndex = timer ? [[timer userInfo][DraggingIndexKey] unsignedIntegerValue] : currentIndex;
    NSRange currentLineRange = [[textView string] lineRangeForRange:NSMakeRange(currentIndex, 0)];
    NSRange clickedLineRange = [[textView string] lineRangeForRange:NSMakeRange(clickedIndex, 0)];
    NSRange range = NSUnionRange(currentLineRange, clickedLineRange);

    NSSelectionAffinity affinity = (currentIndex < clickedIndex) ? NSSelectionAffinityUpstream : NSSelectionAffinityDownstream;

    // with Command key (add selection)
    if ([NSEvent modifierFlags] & NSCommandKeyMask) {
        NSArray<NSValue *> *originalSelectedRanges = [timer userInfo][DraggingSelectedRangesKey] ?: [textView selectedRanges];
        NSMutableArray<NSValue *> *selectedRanges = [NSMutableArray array];
        BOOL intersects = NO;

        for (NSValue *selectedRangeValue in originalSelectedRanges) {
            NSRange selectedRange = [selectedRangeValue rangeValue];

            if (selectedRange.location <= range.location && NSMaxRange(range) <= NSMaxRange(selectedRange)) {  // exclude
                NSRange range1 = NSMakeRange(selectedRange.location, range.location - selectedRange.location);
                NSRange range2 = NSMakeRange(NSMaxRange(range), NSMaxRange(selectedRange) - NSMaxRange(range));

                if (range1.length > 0) {
                    [selectedRanges addObject:[NSValue valueWithRange:range1]];
                }
                if (range2.length > 0) {
                    [selectedRanges addObject:[NSValue valueWithRange:range2]];
                }

                intersects = YES;
                continue;
            }

            // add
            [selectedRanges addObject:selectedRangeValue];
        }

        if (!intersects) {  // add current dragging selection
            [selectedRanges addObject:[NSValue valueWithRange:range]];
        }

        [textView setSelectedRanges:selectedRanges affinity:affinity stillSelecting:YES];

        // redraw line number
        [self setNeedsDisplay:YES];

        return;
    }

    // with Shift key (expand selection)
    if ([NSEvent modifierFlags] & NSShiftKeyMask) {
        NSRange selectedRange = [textView selectedRange];
        if (NSLocationInRange(currentIndex, selectedRange)) {  // reduce
            BOOL inUpperSection = (currentIndex - selectedRange.location) < selectedRange.length / 2;
            if (inUpperSection) {  // clicked upper half section of selected range
                range = NSMakeRange(currentIndex, NSMaxRange(selectedRange) - currentIndex);

            } else {
                range = selectedRange;
                range.length -= NSMaxRange(selectedRange) - NSMaxRange(currentLineRange);
            }

        } else {  // expand
            range = NSUnionRange(range, selectedRange);
        }
    }

    [textView setSelectedRange:range affinity:affinity stillSelecting:YES];

    // redraw line number
    [self setNeedsDisplay:YES];
}

@end

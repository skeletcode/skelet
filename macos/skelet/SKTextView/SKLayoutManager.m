/*
 * Heavily based on https://github.com/coteditor/CotEditor
 * © 2005-2009 nakamuxu, © 2011, 2014 usami-k, © 2013-2016 1024jp.
 **/

@import CoreText;

#import "SKLayoutManager.h"

@interface SKLayoutManager ()

@property (nonatomic) BOOL showsSpace;
@property (nonatomic) BOOL showsTab;
@property (nonatomic) BOOL showsNewLine;
@property (nonatomic) BOOL showsFullwidthSpace;
@property (nonatomic) BOOL showsOtherInvisibles;

@property (nonatomic) unichar spaceChar;
@property (nonatomic) unichar tabChar;
@property (nonatomic) unichar newLineChar;
@property (nonatomic) unichar fullwidthSpaceChar;

@property (nonatomic) CGFloat spaceWidth;

// readonly properties
@property (readwrite, nonatomic) CGFloat defaultLineHeightForTextFont;

@end




#pragma mark -

@implementation SKLayoutManager

static CGGlyph ReplacementGlyph;
static BOOL usesTextFontForInvisibles;


#pragma mark Superclass Methods

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSFont *lucidaGrande = [NSFont fontWithName:@"Lucida Grande" size:0];
        ReplacementGlyph = [lucidaGrande glyphWithName:@"replacement"];  // U+FFFD

        usesTextFontForInvisibles = NO;
    });
}


// ------------------------------------------------------
/// initialize
- (nonnull instancetype)init
// ------------------------------------------------------
{
    if (self = [super init]) {
        [self setShowsControlCharacters:_showsOtherInvisibles];
        [self setTypesetter:[[NSATSTypesetter alloc] init]];
    }
    return self;
}


- (void)setLineFragmentRect:(NSRect)fragmentRect forGlyphRange:(NSRange)glyphRange usedRect:(NSRect)usedRect
{
    if (![self isPrinting] && [self fixesLineHeight]) {
        fragmentRect.size.height = [self lineHeight];
        usedRect.size.height = [self lineHeight];
    }

    [super setLineFragmentRect:fragmentRect forGlyphRange:glyphRange usedRect:usedRect];
}


// ------------------------------------------------------
/// 最終行描画矩形をセット
- (void)setExtraLineFragmentRect:(NSRect)aRect usedRect:(NSRect)usedRect textContainer:(nonnull NSTextContainer *)aTextContainer
// ------------------------------------------------------
{
    // 複合フォントで行の高さがばらつくのを防止するために一般の行の高さを変更しているので、それにあわせる
    aRect.size.height = [self lineHeight];

    [super setExtraLineFragmentRect:aRect usedRect:usedRect textContainer:aTextContainer];
}


// ------------------------------------------------------
/// 不可視文字の表示
- (void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow atPoint:(NSPoint)origin
// ------------------------------------------------------
{
    // スクリーン描画の時、アンチエイリアス制御
    if (![self isPrinting]) {
        [[NSGraphicsContext currentContext] setShouldAntialias:[self usesAntialias]];
    }


    [super drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
}


- (void)showCGGlyphs:(const CGGlyph *)glyphs positions:(const NSPoint *)positions count:(NSUInteger)glyphCount font:(NSFont *)font matrix:(NSAffineTransform *)textMatrix attributes:(NSDictionary<NSString *,id> *)attributes inContext:(NSGraphicsContext *)graphicsContext
{
    // overcort control glyphs
    //   -> Control color will occasionally be colored in sytnax style color after `drawGlyphsForGlyphRange:atPoint:`.
    //      So, it shoud be re-colored here.
    BOOL isControlGlyph = (attributes[NSGlyphInfoAttributeName]);
    if (isControlGlyph && [self showsControlCharacters]) {
        //NSColor *invisibleColor = [[self theme] invisiblesColor];
        [graphicsContext saveGraphicsState];
        //[invisibleColor set];

        // remove existing coloring attribute for safe
        NSMutableDictionary *mutableAttributes = [attributes mutableCopy];
        [mutableAttributes removeObjectForKey:NSForegroundColorAttributeName];
        attributes = [mutableAttributes copy];
    }

    [super showCGGlyphs:glyphs positions:positions count:glyphCount font:font matrix:textMatrix attributes:attributes inContext:graphicsContext];

    // restore context
    if (isControlGlyph) {
        [graphicsContext restoreGraphicsState];
    }
}

//
//// ------------------------------------------------------
///// textStorage did update
//- (void)textStorage:(NSTextStorage *)str edited:(NSTextStorageEditedOptions)editedMask range:(NSRange)newCharRange changeInLength:(NSInteger)delta invalidatedRange:(NSRange)invalidatedCharRange
//// ------------------------------------------------------
//{
//    // invalidate wrapping line indent in editRange if needed
//    if (editedMask & NSTextStorageEditedCharacters)
//    {
//        // invoke after processEditing so that textStorage can be modified safety
//        __weak typeof(self) weakSelf = self;
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [weakSelf invalidateIndentInRange:newCharRange];
//        });
//    }
//
//    [super textStorage:str edited:editedMask range:newCharRange changeInLength:delta invalidatedRange:invalidatedCharRange];
//}



#pragma mark Public Methods

- (void)setPrinting:(BOOL)printing
{
    _printing = printing;
}


- (void)setShowsInvisibles:(BOOL)showsInvisibles
{
    if (!showsInvisibles) {
        NSRange range = NSMakeRange(0, [[[self textStorage] string] length]);
        [[self textStorage] removeAttribute:NSGlyphInfoAttributeName range:range];
    }
    if ([self showsOtherInvisibles]) {
        [self setShowsControlCharacters:showsInvisibles];
    }
    _showsInvisibles = showsInvisibles;
}


- (void)setShowsOtherInvisibles:(BOOL)showsOtherInvisibles
{
    [self setShowsControlCharacters:showsOtherInvisibles];
    _showsOtherInvisibles = showsOtherInvisibles;
}


- (void)setTextFont:(nullable NSFont *)textFont
{
    _textFont = textFont;
    //[self setValuesForTextFont:textFont];

    // store width of space char for indent width calculation
    NSFont *screenFont = [textFont screenFont] ? : textFont;
    [self setSpaceWidth:[screenFont advancementForGlyph:(NSGlyph)' '].width];
}


- (CGFloat)lineHeight
{
  return 2.0;
}


- (void)invalidateIndentInRange:(NSRange)range
{
    // !!!: quick fix avoiding crash on typing Japanese text (2015-10)
    //  -> text length can be changed while passing run-loop
    if (NSMaxRange(range) > [[self textStorage] length]) {
        NSUInteger overflow = NSMaxRange(range) - [[self textStorage] length];
        if (range.length >= overflow) {
            range.length -= overflow;
        } else {
            // nothing to do about hanging indentation if changed range has already been completely removed
            return;
        }
    }

    CGFloat hangingIndent = [self spaceWidth] * 0U;
    CGFloat linePadding = [[[self firstTextView] textContainer] lineFragmentPadding];
    NSTextStorage *textStorage = [self textStorage];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[ \\t]+(?!$)" options:0 error:nil];

    NSMutableArray<NSDictionary<NSString *, id> *> *newIndents = [NSMutableArray array];

    // invalidate line by line
    NSRange lineRange = [[textStorage string] lineRangeForRange:range];
    __weak typeof(self) weakSelf = self;
    [[textStorage string] enumerateSubstringsInRange:lineRange
                                             options:NSStringEnumerationByLines | NSStringEnumerationSubstringNotRequired
                                          usingBlock:^(NSString *substring,
                                                       NSRange substringRange,
                                                       NSRange enclosingRange,
                                                       BOOL *stop)
     {
         typeof(weakSelf) self = weakSelf;
         if (!self) {
             *stop = YES;
             return;
         }

         CGFloat indent = hangingIndent;

         // add base indent
         NSRange baseIndentRange = [regex rangeOfFirstMatchInString:[textStorage string] options:0 range:substringRange];
         if (baseIndentRange.location != NSNotFound) {
             // getting the start line of the character jsut after the last indent character
             //   -> This is actually better in terms of performance than getting whole bounding rect using `boundingRectForGlyphRange:inTextContainer:`
             NSUInteger firstGlyphIndex = [self glyphIndexForCharacterAtIndex:NSMaxRange(baseIndentRange)];
             NSPoint firstGlyphLocation = [self locationForGlyphAtIndex:firstGlyphIndex];
             indent += firstGlyphLocation.x - linePadding;
         }

         // apply new indent only if needed
         NSParagraphStyle *paragraphStyle = [textStorage attribute:NSParagraphStyleAttributeName
                                                           atIndex:substringRange.location
                                                    effectiveRange:NULL];
         if (indent != [paragraphStyle headIndent]) {
             NSMutableParagraphStyle *mutableParagraphStyle = [paragraphStyle mutableCopy];
             [mutableParagraphStyle setHeadIndent:indent];

             // store the result
             //   -> Don't apply to the textStorage at this moment.
             [newIndents addObject:@{@"paragraphStyle": [mutableParagraphStyle copy],
                                     @"range": [NSValue valueWithRange:substringRange]}];
         }
     }];

    if ([newIndents count] == 0) { return; }

    // apply new paragraph styles at once
    //   -> This avoids letting layoutManager calculate glyph location each time.
    [textStorage beginEditing];
    for (NSDictionary<NSString *, id> *indent in newIndents) {
        NSRange range = [indent[@"range"] rangeValue];
        NSParagraphStyle *paragraphStyle = indent[@"paragraphStyle"];

        [textStorage addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
    }
    [textStorage endEditing];
}



#pragma mark Private Methods

- (NSPoint)pointToDrawGlyphAtIndex:(NSUInteger)glyphIndex verticalOffset:(CGFloat)offset
{
    NSPoint origin = [self lineFragmentRectForGlyphAtIndex:glyphIndex
                                            effectiveRange:NULL
                                   withoutAdditionalLayout:YES].origin;
    NSPoint glyphLocation = [self locationForGlyphAtIndex:glyphIndex];

    origin.x += glyphLocation.x;
    origin.y += offset / 2;
  NSLog(@"offset %f", offset);
    return origin;
}


CGPathRef glyphPathWithCharacter(unichar character, CTFontRef font, bool prefersFullWidth)
{
    CGFloat fontSize = CTFontGetSize(font);
    CGGlyph glyph;

    if (usesTextFontForInvisibles) {
        if (CTFontGetGlyphsForCharacters(font, &character, &glyph, 1)) {
            return CTFontCreatePathForGlyph(font, glyph, NULL);
        }
    }

    // try fallback fonts in cases where user font doesn't support the input charactor
    // - All invisible characters of choices can be covered with the following two fonts.
    // - Monaco for vertical tab
    CGPathRef path = NULL;
    NSArray<NSString *> *fallbackFontNames = prefersFullWidth ? @[@"HiraKakuProN-W3", @"LucidaGrande", @"Monaco"] : @[@"LucidaGrande", @"HiraKakuProN-W3", @"Monaco"];

    for (NSString *fontName in fallbackFontNames) {
        CTFontRef fallbackFont = CTFontCreateWithName((CFStringRef)fontName, fontSize, 0);
        if (CTFontGetGlyphsForCharacters(fallbackFont, &character, &glyph, 1)) {
            path = CTFontCreatePathForGlyph(fallbackFont, glyph, NULL);
            break;
        }
        CFRelease(fallbackFont);
    }

    return path;
}

@end

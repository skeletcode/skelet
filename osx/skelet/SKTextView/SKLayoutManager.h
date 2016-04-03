/*
 * Heavily based on https://github.com/coteditor/CotEditor
 * © 2005-2009 nakamuxu, © 2011, 2014 usami-k, © 2013-2016 1024jp.
 **/
@import Cocoa;


@interface SKLayoutManager : NSLayoutManager

@property (nonatomic) BOOL showsInvisibles;
@property (nonatomic) BOOL fixesLineHeight;
@property (nonatomic) BOOL usesAntialias;
@property (nonatomic, getter=isPrinting) BOOL printing;
@property (nonatomic, nullable) NSFont *textFont;
@property (readonly, nonatomic) CGFloat defaultLineHeightForTextFont;

- (CGFloat)lineHeight;
- (void)invalidateIndentInRange:(NSRange)range;

@end

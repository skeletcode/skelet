/*
 * Heavily based on https://github.com/coteditor/CotEditor
 * © 2005-2009 nakamuxu, © 2011, 2014 usami-k, © 2013-2016 1024jp.
 **/

@import Cocoa;

@interface SKInnerTextView: NSTextView <NSTextInputClient>

@property (nonatomic) BOOL showsPageGuide;
@property (nonatomic) BOOL autoIndent;
@property (nonatomic) BOOL smartIndent;
@property (nonatomic) BOOL balanceBrackets;

@property (nonatomic) BOOL needsUpdateOutlineMenuItemSelection;
@property (nonatomic) CGFloat lineSpacing;
@property (nonatomic) NSUInteger tabWidth;
@property (nonatomic) NSRect highlightLineRect;
@property (nonatomic, getter=isAutoTabExpandEnabled) BOOL autoTabExpandEnabled;
@property (nonatomic, nullable, copy) NSString *inlineCommentDelimiter;
@property (nonatomic, nullable, copy) NSDictionary<NSString *, NSString *> *blockCommentDelimiters;
@property (nonatomic, nullable, copy) NSCharacterSet *firstCompletionCharacterSet;
@property (nonatomic, nullable, copy) NSColor *highlightLineColor;

- (void)applyTypingAttributes;
- (void)insertString:(nonnull NSString *)string;
- (void)insertStringAfterSelection:(nonnull NSString *)string;
- (void)replaceAllStringWithString:(nonnull NSString *)string;
- (void)appendString:(nonnull NSString *)string;

- (void)replaceWithString:(nullable NSString *)string range:(NSRange)range
            selectedRange:(NSRange)selectedRange actionName:(nullable NSString *)actionName;

@end

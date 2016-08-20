@import Cocoa;

#import "RCTView.h"
#import "NSView+React.h"
#import "SKLayoutManager.h"
#import "SKScrollView.h"
#import "SKInnerTextView.h"

@class RCTEventDispatcher;

@interface SKTextView: RCTView<NSTextViewDelegate, NSLayoutManagerDelegate, NSTextDelegate>

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher * _Nonnull)eventDispatcher NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign) NSInteger mostRecentEventCount;
@property (nonatomic, nullable, copy) NSTextStorage *textStorage;
@property (nonatomic, nullable, copy) SKInnerTextView *textView;
@property (nonatomic, nullable, copy) SKScrollView *scrollView;


- (BOOL)isReactRootView;
- (void)highlightRange:(NSRange)range attributes:(NSDictionary<NSString *, NSValue *> * _Nonnull)attributes;
- (void)updateFont;

@end

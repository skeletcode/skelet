#import "SKTextViewManager.h"
#import "SKTextView.h"

#import "RCTBridge.h"
#import "RCTConvert.h"
#import "RCTShadowView.h"

@implementation RCTConvert(SKTextView)

RCT_ENUM_CONVERTER(NSAttributeType, (@{
                                    @"color": @(0),
                                    @"backgroundColor": @(1)
                                    }), 0, intValue)

@end

@implementation SKTextViewManager

RCT_EXPORT_MODULE()

- (NSView *)view
{
  return [[SKTextView alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
}

RCT_EXPORT_VIEW_PROPERTY(autoCorrect, BOOL)
RCT_REMAP_VIEW_PROPERTY(editable, textView.editable, BOOL)
RCT_EXPORT_VIEW_PROPERTY(placeholder, NSString)
RCT_EXPORT_VIEW_PROPERTY(placeholderTextColor, NSColor)
RCT_EXPORT_VIEW_PROPERTY(padding, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(text, NSString)
RCT_EXPORT_VIEW_PROPERTY(maxLength, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(clearTextOnFocus, BOOL)
RCT_EXPORT_VIEW_PROPERTY(selectTextOnFocus, BOOL)
RCT_EXPORT_VIEW_PROPERTY(color, NSColor)
RCT_REMAP_VIEW_PROPERTY(highlightLineColor, textView.highlightLineColor, NSColor)
RCT_REMAP_VIEW_PROPERTY(backgroundColor, textView.backgroundColor, NSColor)
RCT_CUSTOM_VIEW_PROPERTY(fontSize, CGFloat, __unused SKTextView)
{
  view.textView.font = [RCTConvert NSFont:view.textView.font withSize:json ?: @(defaultView.textView.font.pointSize)];
  [view updateFont];
}
RCT_CUSTOM_VIEW_PROPERTY(fontWeight, NSString, __unused SKTextView)
{
  view.textView.font = [RCTConvert NSFont:view.textView.font withWeight:json]; // defaults to normal
  [view updateFont];
}
RCT_CUSTOM_VIEW_PROPERTY(fontStyle, NSString, __unused SKTextView)
{
  view.textView.font = [RCTConvert NSFont:view.textView.font withStyle:json]; // defaults to normal
  [view updateFont];
}
RCT_CUSTOM_VIEW_PROPERTY(fontFamily, NSString, __unused SKTextView)
{
  view.textView.font = [RCTConvert NSFont:view.textView.font withFamily:json ?: defaultView.textView.font.familyName];
  [view updateFont];
}
RCT_CUSTOM_VIEW_PROPERTY(highlights, NSArray, __unused SKTextView)
{
  NSArray *highlightsArray = [RCTConvert NSArray:json];
  
  [highlightsArray enumerateObjectsUsingBlock:^(NSDictionary<NSString*, id>* dict, NSUInteger idx, BOOL * _Nonnull stop){
    NSArray *rangeArray = dict[@"range"];
    NSRange range = NSMakeRange([RCTConvert NSInteger:rangeArray[0]], [RCTConvert NSInteger:rangeArray[1]]);

    [view highlightRange:range attributes:(NSDictionary *)dict[@"attributes"]];
  }];

}
RCT_EXPORT_METHOD(highlight:(NSRange)range) {
  NSLog(@"%lu", (unsigned long)range.length);
}

@end

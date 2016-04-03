/*
 * Heavily based on https://github.com/coteditor/CotEditor
 * © 2005-2009 nakamuxu, © 2011, 2014 usami-k, © 2013-2016 1024jp.
 **/
@import Cocoa;

#import "SKInnerTextView.h"


NSString *_Nonnull const SKSelectedRangesKey = @"selectedRange";
NSString *_Nonnull const SKVisibleRectKey = @"visibleRect";
NSString *_Nonnull const SKAutoBalancedClosingBracketAttributeName = @"SKAutoBalancedClosingBracketAttributeName";

static NSCharacterSet *MATCHING_OPENING_BRACKETS_SET;
static NSCharacterSet *MATCHING_CLOSING_BRACKETS_SET;


@interface SKInnerTextView ()

@property (nonatomic) NSTimer *completionTimer;
@property (nonatomic, copy) NSString *particalCompletionWord;

@end


@implementation SKInnerTextView

static NSPoint kTextContainerOrigin;

+ (void)initialize
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    MATCHING_OPENING_BRACKETS_SET = [NSCharacterSet characterSetWithCharactersInString:@"[{(\""];
    MATCHING_CLOSING_BRACKETS_SET = [NSCharacterSet characterSetWithCharactersInString:@"]})"];  // ignore "
  });
}


- (nonnull instancetype)initWithFrame:(NSRect)frameRect textContainer:(nullable NSTextContainer *)container
{
  self = [super initWithFrame:frameRect textContainer:container];
  if (self) {

    // set class identifier for window restoration
    [self setIdentifier:@"coreTextView"];
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // This method is partly based on Smultron's SMLTextView by Peter Borg. (2006-09-09)
    // Smultron 2 was distributed on <http://smultron.sourceforge.net> under the terms of the BSD license.
    // Copyright (c) 2004-2006 Peter Borg

    // set the width of every tab by first checking the size of the tab in spaces in the current font and then remove all tabs that sets automatically and then set the default tab stop distance
    _tabWidth = 2;
    CGFloat fontSize = 12;
    NSFont *font = [NSFont systemFontOfSize:fontSize];

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setTabStops:@[]];  // clear default tab stops

    const float lineHeightK = 1.5;
    float lineHeight = lineHeightK - ((lineHeightK - 1.0) / 2);
    [paragraphStyle setLineHeightMultiple:lineHeight];
    float lineSpacing = ((lineHeightK - 1.0) / 2)*fontSize;

    [paragraphStyle setLineSpacing:lineSpacing];
    [paragraphStyle setDefaultTabInterval:[self tabIntervalFromFont:font]];
    [self setDefaultParagraphStyle:paragraphStyle];
    // （NSParagraphStyle の lineSpacing を設定すればテキスト描画時の行間は制御できるが、
    // 「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
    // 挿入すると行間がズレる」問題が生じるため、CELayoutManager および CEATSTypesetter で制御している）

    // setup theme
    // [self setTheme:[CETheme themeWithName:[defaults stringForKey:CEDefaultThemeKey]]];

    // set layer drawing policies
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawBeforeViewResize];
    [self setLayerContentsPlacement:NSViewLayerContentsPlacementScaleAxesIndependently];


    [self setSmartInsertDeleteEnabled:NO];
    [self setContinuousSpellCheckingEnabled:NO];
    [self setFont:font];
    [self setMinSize:frameRect.size];
    [self setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    [self setAllowsDocumentBackgroundColorChange:NO];
    [self setAllowsUndo:YES];
    [self setRichText:NO];
    [self setImportsGraphics:NO];
    [self setUsesFindPanel:YES];
    [self setHorizontallyResizable:YES];
    [self setVerticallyResizable:YES];
    [self setAcceptsGlyphInfo:YES];
    [self setAutomaticQuoteSubstitutionEnabled:NO];
    [self setAutomaticDashSubstitutionEnabled:NO];

    //[self setLineSpacing:2.0];
    //        [self setTextContainerInset:NSMakeSize((CGFloat)[defaults doubleForKey:CEDefaultTextContainerInsetWidthKey],
    //                                               (CGFloat)([defaults doubleForKey:CEDefaultTextContainerInsetHeightTopKey] +
    //                                                         [defaults doubleForKey:CEDefaultTextContainerInsetHeightBottomKey]) / 2)];
    //        [self setLineSpacing:(CGFloat)[defaults doubleForKey:CEDefaultLineSpacingKey]];
    //        _needsUpdateOutlineMenuItemSelection = YES;
    //
    [self applyTypingAttributes];
    //
    //        // observe change of defaults
    //        for (NSString *key in [CETextView observedDefaultKeys]) {
    //            [[NSUserDefaults standardUserDefaults] addObserver:self
    //                                                    forKeyPath:key
    //                                                       options:NSKeyValueObservingOptionNew
    //                                                       context:NULL];
    //        }
  }

  return self;
}


// ------------------------------------------------------
/// clean up
//- (void)dealloc
//// ------------------------------------------------------
//{
//    for (NSString *key in [CETextView observedDefaultKeys]) {
//        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:key];
//    }
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [self stopCompletionTimer];
//}

- (void)applyTypingAttributes
// ------------------------------------------------------
{
  if (self.font && self.textColor) {
    [self setTypingAttributes:@{NSParagraphStyleAttributeName: [self defaultParagraphStyle],
                                NSFontAttributeName: [self font],
                                NSForegroundColorAttributeName: [self textColor]}];

    [[self textStorage] setAttributes:[self typingAttributes]
                                range:NSMakeRange(0, [[self textStorage] length])];
  }
  //
  // update current text

}

// ------------------------------------------------------
/// store UI state for the window restoration
- (void)encodeRestorableStateWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
  [super encodeRestorableStateWithCoder:coder];

  [coder encodeObject:[self selectedRanges] forKey:SKSelectedRangesKey];
  [coder encodeRect:[self visibleRect] forKey:SKVisibleRectKey];
}


// ------------------------------------------------------
/// restore UI state on the window restoration
- (void)restoreStateWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
  [super restoreStateWithCoder:coder];

  if ([coder containsValueForKey:SKVisibleRectKey]) {
    NSRect visibleRect = [coder decodeRectForKey:SKVisibleRectKey];
    NSArray<NSValue *> *selectedRanges = [coder decodeObjectForKey:SKSelectedRangesKey];

    // filter to avoid crash if the stored selected range is an invalid range
    if ([selectedRanges count] > 0) {
      NSUInteger length = [[self textStorage] length];
      selectedRanges = [selectedRanges filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        NSRange range = [evaluatedObject rangeValue];

        return NSMaxRange(range) <= length;
      }]];

      if ([selectedRanges count] > 0) {
        [self setSelectedRanges:selectedRanges];
      }
    }

    // perform scroll on the next run-loop
    __unsafe_unretained typeof(self) weakSelf = self;  // NSTextView cannot be weak
    dispatch_async(dispatch_get_main_queue(), ^{
      typeof(self) self = weakSelf;  // strong self
      if (!self) { return; }

      [self scrollRectToVisible:visibleRect];
    });
  }
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)undo {
  if ([[self undoManager] canUndo]) {
    [[self undoManager] undo];
  }
}

- (void)redo {
  if ([[self undoManager] canRedo]) {
    [[self undoManager] redo];
  }
}

- (BOOL)becomeFirstResponder
{
  return [super becomeFirstResponder];
}


- (void)keyDown:(nonnull NSEvent *)theEvent
{
  [super keyDown:theEvent];
}

- (void)insertText:(nonnull id)aString replacementRange:(NSRange)replacementRange
{
  // do not use this method for programmatical insertion.

  // TODO:
  // add COPYRIGHT for a CotEditor implementation
  // rewrite part of this in javascript


  // cast NSAttributedString to NSString in order to make sure input string is plain-text
  NSString *string = [aString isKindOfClass:[NSAttributedString class]] ? [aString string] : aString;

  // balance brackets and quotes
  if ([self balanceBrackets] && (replacementRange.length == 0) &&
      [string length] == 1 && [MATCHING_OPENING_BRACKETS_SET characterIsMember:[string characterAtIndex:0]])
  {
    // wrap selection with brackets if some text is selected
    if ([self selectedRange].length > 0) {
      NSString *wrappingFormat = nil;
      switch ([string characterAtIndex:0]) {
        case '[':
          wrappingFormat = @"[%@]";
          break;
        case '{':
          wrappingFormat = @"{%@}";
          break;
        case '(':
          wrappingFormat = @"(%@)";
          break;
        case '"':
          wrappingFormat = @"\"%@\"";
          break;
      }

      NSString *selectedString = [[self string] substringWithRange:[self selectedRange]];
      NSString *replacementString = [NSString stringWithFormat:wrappingFormat, selectedString];
      if ([self shouldChangeTextInRange:[self selectedRange] replacementString:replacementString]) {
        [[self textStorage] replaceCharactersInRange:[self selectedRange] withString:replacementString];
        [self didChangeText];
        return;
      }

      // check if insertion point is in a word
    } else if (![[NSCharacterSet alphanumericCharacterSet] characterIsMember:[self characterAfterInsertion]]) {
      switch ([string characterAtIndex:0]) {
        case '[':
          string = @"[]";
          break;
        case '{':
          string = @"{}";
          break;
        case '(':
          string = @"()";
          break;
        case '"':
          string = @"\"\"";
          break;
      }

      [super insertText:string replacementRange:replacementRange];
      [self setSelectedRange:NSMakeRange([self selectedRange].location - 1, 0)];

      // set flagCEAutoBalancedClosingBracketAttributeName
      [[self textStorage] addAttribute:SKAutoBalancedClosingBracketAttributeName value:@YES
                                 range:NSMakeRange([self selectedRange].location, 1)];
      return;
    }
  }

  // just move cursor if closed bracket is already typed
  if ([self balanceBrackets] && (replacementRange.length == 0) &&
      [MATCHING_CLOSING_BRACKETS_SET characterIsMember:[string characterAtIndex:0]] &&
      ([string characterAtIndex:0] == [self characterAfterInsertion]))
  {
    if ([[[self textStorage] attribute:SKAutoBalancedClosingBracketAttributeName
                               atIndex:[self selectedRange].location effectiveRange:NULL] boolValue])
    {
      [self setSelectedRange:NSMakeRange([self selectedRange].location + 1, 0)];
      return;
    }
  }


  // smart outdent with '}' charcter
  if ([self autoIndent] && [self smartIndent] && (replacementRange.length == 0) && [string isEqualToString:@"}"])
  {
      NSString *wholeString = [self string];
      NSUInteger insretionLocation = NSMaxRange([self selectedRange]);
      NSRange lineRange = [wholeString lineRangeForRange:NSMakeRange(insretionLocation, 0)];
      NSString *lineStr = [wholeString substringWithRange:lineRange];

      // decrease indent level if the line is consists of only whitespaces
      if ([lineStr rangeOfString:@"^[ \\t　]+\\n?$"
                         options:NSRegularExpressionSearch
                           range:NSMakeRange(0, [lineStr length])].location != NSNotFound)
      {
          // find correspondent opening-brace
          NSInteger precedingLocation = insretionLocation - 1;
          NSUInteger skipMatchingBrace = 0;

          while (precedingLocation--) {
              unichar characterToCheck = [wholeString characterAtIndex:precedingLocation];
              if (characterToCheck == '{') {
                  if (skipMatchingBrace) {
                      skipMatchingBrace--;
                  } else {
                      break;  // found
                  }
              } else if (characterToCheck == '}') {
                  skipMatchingBrace++;
              }
          }

          // outdent
          if (precedingLocation >= 0) {
              NSRange precedingLineRange = [wholeString lineRangeForRange:NSMakeRange(precedingLocation, 0)];
              NSString *precedingLineStr = [wholeString substringWithRange:precedingLineRange];
              NSUInteger desiredLevel = [self indentLevelOfString:precedingLineStr];
              NSUInteger currentLevel = [self indentLevelOfString:lineStr];
              NSUInteger levelToReduce = currentLevel - desiredLevel;

              while (levelToReduce--) {
                  [self deleteBackward:self];
              }
          }
      }
  }

  [super insertText:string replacementRange:replacementRange];
  //[self applyTypingAttributes];

  // auto completion
  //    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultAutoCompleteKey]) {
  //        [self completeAfterDelay:[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultAutoCompletionDelayKey]];
  //    }
}


- (void)insertTab:(nullable id)sender
{
  if ([self isAutoTabExpandEnabled]) {
    NSInteger tabWidth = [self tabWidth];
    NSInteger column = [self columnOfLocation:[self selectedRange].location expandsTab:YES];
    NSInteger length = tabWidth - ((column + tabWidth) % tabWidth);
    NSMutableString *spaces = [NSMutableString string];

    while (length--) {
      [spaces appendString:@" "];
    }
    [super insertText:spaces replacementRange:[self selectedRange]];

  } else {
    [super insertTab:sender];
  }
}

- (void)insertNewline:(nullable id)sender
{
  if (![self autoIndent]) {
    return [super insertNewline:sender];
  }

  NSRange selectedRange = [self selectedRange];
  NSRange lineRange = [[self string] lineRangeForRange:selectedRange];
  NSString *lineStr = [[self string] substringWithRange:NSMakeRange(lineRange.location,
                                                                    NSMaxRange(selectedRange) - lineRange.location)];
  NSRange indentRange = [lineStr rangeOfString:@"^[ \\t　]+" options:NSRegularExpressionSearch];

  if (NSMaxRange(selectedRange) >= (selectedRange.location + NSMaxRange(indentRange))) {
    return [super insertNewline:sender];
  }

  NSString *indent = @"";
  BOOL shouldIncreaseIndentLevel = NO;
  BOOL shouldExpandBlock = NO;

  if (indentRange.location != NSNotFound) {
    indent = [lineStr substringWithRange:indentRange];
  }

  // calculation for smart indent
  if ([self smartIndent]) {
    unichar lastChar = [self characterBeforeInsertion];
    unichar nextChar = [self characterAfterInsertion];

    shouldExpandBlock = ((lastChar == '{') && (nextChar == '}'));
    shouldIncreaseIndentLevel = ((lastChar == ':') || (lastChar == '{'));
  }

  [super insertNewline:sender];

  // auto indent
  if ([indent length] > 0) {
    [super insertText:indent replacementRange:[self selectedRange]];
  }

  // smart indent
  if (shouldExpandBlock) {
    [self insertTab:sender];
    NSRange selection = [self selectedRange];
    [super insertNewline:sender];
    [super insertText:indent replacementRange:[self selectedRange]];
    [self setSelectedRange:selection];

  } else if (shouldIncreaseIndentLevel) {
    [self insertTab:sender];
  }
}


- (void)deleteBackward:(nullable id)sender
{
  NSRange selectedRange = [self selectedRange];
  if (selectedRange.length == 0 && [self isAutoTabExpandEnabled]) {
    NSUInteger tabWidth = [self tabWidth];
    NSInteger column = [self columnOfLocation:selectedRange.location expandsTab:YES];
    NSInteger length = tabWidth - ((column + tabWidth) % tabWidth);
    NSInteger targetWidth = (length == 0) ? tabWidth : length;

    if (selectedRange.location >= targetWidth) {
      NSRange targetRange = NSMakeRange(selectedRange.location - targetWidth, targetWidth);
      NSString *target = [[self string] substringWithRange:targetRange];
      BOOL shouldDelete = NO;
      for (NSUInteger i = 0; i < targetWidth; i++) {
        shouldDelete = ([target characterAtIndex:i] == ' ');
        if (!shouldDelete) {
          break;
        }
      }
      if (shouldDelete) {
        [self setSelectedRange:targetRange];
      }
    }
  }
  [super deleteBackward:sender];
}


//// ------------------------------------------------------
///// コンテキストメニューを返す
//- (nullable NSMenu *)menuForEvent:(nonnull NSEvent *)theEvent
//// ------------------------------------------------------
//{
//    NSMenu *menu = [super menuForEvent:theEvent];
//
//    // remove unwanted "Font" menu and its submenus
//    [menu removeItem:[menu itemWithTitle:NSLocalizedString(@"Font", nil)]];
//
//    // add "Inspect Character" menu item if single character is selected
//    if ([[[self string] substringWithRange:[self selectedRange]] numberOfComposedCharacters] == 1) {
//        [menu insertItemWithTitle:NSLocalizedString(@"Inspect Character", nil)
//                              action:@selector(showSelectionInfo:)
//                       keyEquivalent:@""
//                             atIndex:1];
//    }
//
//    // add "Select All" menu item
//    NSInteger pasteIndex = [menu indexOfItemWithTarget:nil andAction:@selector(paste:)];
//    if (pasteIndex != kNoMenuItem) {
//        [menu insertItemWithTitle:NSLocalizedString(@"Select All", nil)
//                           action:@selector(selectAll:) keyEquivalent:@""
//                          atIndex:(pasteIndex + 1)];
//    }
//
//    // append a separator
//    [menu addItem:[NSMenuItem separatorItem]];
//
//    // append Script menu
//    NSMenu *scriptMenu = [[CEScriptManager sharedManager] contexualMenu];
//    if (scriptMenu) {
//        if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultInlineContextualScriptMenuKey]) {
//            [menu addItem:[NSMenuItem separatorItem]];
//            [[[menu itemArray] lastObject] setTag:CEScriptMenuItemTag];
//
//            for (NSMenuItem *item in [scriptMenu itemArray]) {
//                NSMenuItem *addItem = [item copy];
//                [addItem setTag:CEScriptMenuItemTag];
//                [menu addItem:addItem];
//            }
//            [menu addItem:[NSMenuItem separatorItem]];
//
//        } else {
//            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
//            [item setImage:[NSImage imageNamed:@"ScriptTemplate"]];
//            [item setTag:CEScriptMenuItemTag];
//            [item setSubmenu:scriptMenu];
//            [menu addItem:item];
//        }
//    }
//
//    return menu;
//}

- (void)setFont:(nullable NSFont *)font
{
  [super setFont:font];

  NSMutableParagraphStyle *paragraphStyle = [[self defaultParagraphStyle] mutableCopy];
  [paragraphStyle setDefaultTabInterval:[self tabIntervalFromFont:font]];
  [self setDefaultParagraphStyle:paragraphStyle];

  //[self applyTypingAttributes];
}


- (void)setTabWidth:(NSUInteger)tabWidth
{
  _tabWidth = tabWidth;
  [self setFont:[self font]];  // force re-layout with new width
}


- (NSPoint)textContainerOrigin
{
  return kTextContainerOrigin;
}


- (void)drawViewBackgroundInRect:(NSRect)rect
{
  [super drawViewBackgroundInRect:rect];

  // draw current line highlight
  if (NSIntersectsRect(rect, [self highlightLineRect])) {
    [[self highlightLineColor] set];
    [NSBezierPath fillRect:[self highlightLineRect]];
  }

}


- (void)setLayoutOrientation:(NSTextLayoutOrientation)theOrientation
{
  if (theOrientation != [self layoutOrientation]) {
    if ([[self textContainer] containerSize].width != CGFLOAT_MAX) {
      [[self textContainer] setContainerSize:NSMakeSize(0, CGFLOAT_MAX)];
    }
  }

  [super setLayoutOrientation:theOrientation];
}


#pragma mark Public Methods

- (void)insertString:(nonnull NSString *)string
{
  NSRange replacementRange = [self selectedRange];

  if ([self shouldChangeTextInRange:replacementRange replacementString:string]) {
    [self replaceCharactersInRange:replacementRange withString:string];
    [self setSelectedRange:NSMakeRange(replacementRange.location, [string length])];

    NSString *actionName = (replacementRange.length > 0) ? @"Replace Text" : @"Insert Text";
    [[self undoManager] setActionName:NSLocalizedString(actionName, nil)];

    [self didChangeText];
  }
}


// ------------------------------------------------------
/// insert given string just after current selection and select inserted range
- (void)insertStringAfterSelection:(nonnull NSString *)string
// ------------------------------------------------------
{
  NSRange replacementRange = NSMakeRange(NSMaxRange([self selectedRange]), 0);

  if ([self shouldChangeTextInRange:replacementRange replacementString:string]) {
    [self replaceCharactersInRange:replacementRange withString:string];
    [self setSelectedRange:NSMakeRange(replacementRange.location, [string length])];

    [[self undoManager] setActionName:NSLocalizedString(@"Insert Text", nil)];

    [self didChangeText];
  }
}


// ------------------------------------------------------
/// swap whole current string with given string and select inserted range
- (void)replaceAllStringWithString:(nonnull NSString *)string
// ------------------------------------------------------
{
  NSRange replacementRange = NSMakeRange(0, [[self string] length]);

  if ([self shouldChangeTextInRange:replacementRange replacementString:string]) {
    [self replaceCharactersInRange:replacementRange withString:string];
    [self setSelectedRange:NSMakeRange(replacementRange.location, [string length])];

    [[self undoManager] setActionName:NSLocalizedString(@"Replace Text", nil)];

    [self didChangeText];
  }
}


// ------------------------------------------------------
/// append string at the end of the whole string and select inserted range
- (void)appendString:(nonnull NSString *)string
// ------------------------------------------------------
{
  NSRange replacementRange = NSMakeRange([[self string] length], 0);

  if ([self shouldChangeTextInRange:replacementRange replacementString:string]) {
    [self replaceCharactersInRange:replacementRange withString:string];
    [self setSelectedRange:NSMakeRange(replacementRange.location, [string length])];

    [[self undoManager] setActionName:NSLocalizedString(@"Insert Text", nil)];

    [self didChangeText];
  }
}


- (void)replaceWithString:(nullable NSString *)string range:(NSRange)range selectedRange:(NSRange)selectedRange actionName:(nullable NSString *)actionName
{
  if (!string) { return; }

  [self replaceWithStrings:@[string]
                    ranges:@[[NSValue valueWithRange:range]]
            selectedRanges:@[[NSValue valueWithRange:selectedRange]]
                actionName:actionName];
}


/// increase indent level
- (IBAction)shiftRight:(nullable id)sender
{
  if ([self tabWidth] < 1) { return; }

  // get range to process
  NSRange selectedRange = [self selectedRange];
  NSRange lineRange = [[self string] lineRangeForRange:selectedRange];

  // remove the last line ending
  if (lineRange.length > 0) {
    lineRange.length--;
  }

  // create indent string to prepend
  NSMutableString *indent = [NSMutableString string];
  if ([self isAutoTabExpandEnabled]) {
    NSUInteger tabWidth = [self tabWidth];
    while (tabWidth--) {
      [indent appendString:@" "];
    }
  } else {
    [indent setString:@"\t"];
  }

  // create shifted string
  NSMutableString *newString = [NSMutableString stringWithString:[[self string] substringWithRange:lineRange]];
  NSUInteger numberOfLines = [newString replaceOccurrencesOfString:@"\n"
                                                        withString:[NSString stringWithFormat:@"\n%@", indent]
                                                           options:0
                                                             range:NSMakeRange(0, [newString length])];
  [newString insertString:indent atIndex:0];

  // calculate new selection range
  NSRange newSelectedRange = NSMakeRange(selectedRange.location,
                                         selectedRange.length + [indent length] * numberOfLines);
  if ((lineRange.location == selectedRange.location) && (selectedRange.length > 0) &&
      ([[[self string] substringWithRange:selectedRange] hasSuffix:@"\n"]))
  {
    newSelectedRange.length += [indent length];
  } else {
    newSelectedRange.location += [indent length];
  }

  // perform replace and register to undo manager
  [self replaceWithString:newString range:lineRange selectedRange:newSelectedRange
               actionName:NSLocalizedString(@"Shift Right", nil)];
}


- (IBAction)selectLines:(nullable id)sender
{
  [self setSelectedRange:[[self string] lineRangeForRange:[self selectedRange]]];
}


- (IBAction)inputBackSlash:(nullable id)sender
{
  [super insertText:@"\\" replacementRange:[self selectedRange]];
}


- (IBAction)setSelectedRangeWithNSValue:(nullable id)sender
{
  NSValue *value = [sender representedObject];

  if (!value) { return; }

  NSRange range = [value rangeValue];

  [self setNeedsUpdateOutlineMenuItemSelection:NO];
  [self setSelectedRange:range];
  [self centerSelectionInVisibleArea:self];
  [[self window] makeFirstResponder:self];
}

// ------------------------------------------------------
/// window's opacity did change
- (void)didWindowOpacityChange:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
  BOOL isOpaque = [[self window] isOpaque];

  // let text view have own background if possible
  [self setDrawsBackground:isOpaque];

  // By opaque window, turn `copiesOnScroll` on to enable Responsive Scrolling with traditional drawing.
  // -> Better not using layer-backed view to avoid ugly text rendering and performance issue (1024jp on 2015-01)
  //    cf. Responsive Scrolling section in the Release Notes for OS X 10.9
  [[[self enclosingScrollView] contentView] setCopiesOnScroll:isOpaque];

  // Make view layer-backed in order to disable dropshadow from letters on Mavericks (1024jp on 2015-02)
  // -> This makes scrolling laggy on huge file.
  if (floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_9) {
    [[self enclosingScrollView] setWantsLayer:!isOpaque];
  }

  // redraw visible area
  [self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:YES];
}



// ------------------------------------------------------
/// perform multiple replacements
- (void)replaceWithStrings:(nonnull NSArray<NSString *> *)strings ranges:(nonnull NSArray<NSValue *> *)ranges selectedRanges:(nonnull NSArray<NSValue *> *)selectedRanges actionName:(nullable NSString *)actionName
// ------------------------------------------------------
{
  // register redo for text selection
  [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRangesWithUndo:[self selectedRanges]];

  // tell textEditor about beginning of the text processing
  if (![self shouldChangeTextInRanges:ranges replacementStrings:strings]) { return; }

  // set action name
  if (actionName) {
    [[self undoManager] setActionName:actionName];
  }

  // process text
  NSTextStorage *textStorage = [self textStorage];
  NSDictionary<NSString *, id> *attributes = [self typingAttributes];

  [textStorage beginEditing];
  // use backwards enumeration to skip adjustment of applying location
  [ranges enumerateObjectsWithOptions:NSEnumerationReverse
                           usingBlock:^(id obj, NSUInteger idx, BOOL *stop)
   {
     NSRange range = [obj rangeValue];
     NSString *string = strings[idx];
     NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string attributes:attributes];

     [textStorage replaceCharactersInRange:range withAttributedString:attrString];
   }];
  [textStorage endEditing];

  // post didEdit notification (It's not posted automatically, since here NSTextStorage is directly edited.)
  [self didChangeText];

  // apply new selection ranges
  [self setSelectedRangesWithUndo:selectedRanges];
}


// ------------------------------------------------------
/// undoable selection change
- (void)setSelectedRangesWithUndo:(nonnull NSArray<NSValue *> *)ranges;
// ------------------------------------------------------
{
  [self setSelectedRanges:ranges];
  [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRangesWithUndo:ranges];
}

// ------------------------------------------------------
/// フォントからタブ幅を計算して返す
- (CGFloat)tabIntervalFromFont:(NSFont *)font
// ------------------------------------------------------
{
  NSFont *screenFont = [font screenFont] ? : font;
  CGFloat spaceWidth = [screenFont advancementForGlyph:(NSGlyph)' '].width;

  return [self tabWidth] * spaceWidth;
}


// ------------------------------------------------------
/// calculate column number at location in the line
- (NSUInteger)columnOfLocation:(NSUInteger)location expandsTab:(BOOL)expandsTab
// ------------------------------------------------------
{
  NSRange lineRange = [[self string] lineRangeForRange:NSMakeRange(location, 0)];
  NSInteger column = location - lineRange.location;

  // count tab width
  if (expandsTab) {
    NSString *beforeInsertion = [[self string] substringWithRange:NSMakeRange(lineRange.location, column)];
    NSUInteger numberOfTabChars = [[beforeInsertion componentsSeparatedByString:@"\t"] count] - 1;
    column += numberOfTabChars * ([self tabWidth] - 1);
  }

  return column;
}


// ------------------------------------------------------
/// インデントレベルを算出
- (NSUInteger)indentLevelOfString:(NSString *)string
// ------------------------------------------------------
{
  NSRange indentRange = [string rangeOfString:@"^[ \\t　]+" options:NSRegularExpressionSearch];

  if (indentRange.location == NSNotFound) { return 0; }

  NSString *indent = [string substringWithRange:indentRange];
  NSUInteger numberOfTabChars = [[indent componentsSeparatedByString:@"\t"] count] - 1;

  return numberOfTabChars + (([indent length] - numberOfTabChars) / [self tabWidth]);
}


- (NSRect)overlayRectForRange:(NSRange)range
{
  NSRange glyphRange = [[self layoutManager] glyphRangeForCharacterRange:range actualCharacterRange:NULL];
  NSRect rect = [[self layoutManager] boundingRectForGlyphRange:glyphRange inTextContainer:[self textContainer]];
  NSPoint containerOrigin = [self textContainerOrigin];

  rect.origin.x += containerOrigin.x;
  rect.origin.y += containerOrigin.y;

  return [self convertRectToLayer:rect];
}

- (unichar)characterBeforeInsertion
{
  NSUInteger location = [self selectedRange].location;
  if (location > 0) {
    return [[self string] characterAtIndex:location - 1];
  }
  return 0;
}

- (unichar)characterAfterInsertion
{
  NSUInteger location = NSMaxRange([self selectedRange]);
  if (location < [[self string] length]) {
    return [[self string] characterAtIndex:location];
  }
  return 0;
}

@end

#include "DialogManager.h"
#include "AppKit/AppKit.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"

@implementation DialogManager
{
  NSFileHandle *_fileHandle;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

- (instancetype)init
{
  if (self = [super init]) {

  }
  return self;
}

- (void)setBridge:(RCTBridge *)bridge
{
  _bridge = bridge;
}

RCT_EXPORT_METHOD(chooseDirectory:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
   dispatch_async(dispatch_get_main_queue(), ^{
     NSOpenPanel *panel = [NSOpenPanel openPanel];
     [panel setAllowsMultipleSelection:NO];
     [panel setCanChooseDirectories:YES];
     [panel setCanChooseFiles:NO];
     [panel setFloatingPanel:YES];
     [panel setPrompt:@"Open Directory"];
     [panel beginWithCompletionHandler:^(NSInteger result){
       if (result == NSFileHandlingPanelOKButton) {
         resolve([[[panel URLs] firstObject] absoluteString]);
       } else {
         reject(@"Canceled", @"OpenPanel has been canceled", nil);
       }
     }];
   });

//  NSInteger result = [panel runModalForDirectory:NSHomeDirectory() file:nil
//                                           types:nil];
//  if(result == NSOKButton)
//  {
//    return [panel URLs];
//  }
}


@end

#include "FilesystemManager.h"
#include "AppKit/AppKit.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"

@implementation FilesystemManager
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

-(void)save
{
  [_bridge.eventDispatcher sendDeviceEventWithName:@"onFileSavePressed"
                                              body:@{}];
}

RCT_EXPORT_METHOD(openFile:(NSString *)path
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  _fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:path];
  if (_fileHandle == nil) {
    reject(@"File Not Found", nil, nil);
  } else {
    NSData * buffer = nil;
    // read first 10 kb
    buffer = [_fileHandle readDataOfLength:1024*10];
    NSString *stringRepresentation = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
    resolve(stringRepresentation);
  }

  // TODO: store filehandler somewhere
  // TODO: check length
}

RCT_EXPORT_METHOD(saveFile:(NSString *)path
                  content:(NSString *)content
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  if (_fileHandle == nil) {
    reject(@"File Not Found", nil, nil);
  } else {
    [_fileHandle seekToFileOffset:0];
    @try{
      [_fileHandle writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    }
    @catch(NSException *exception) {
      NSLog(@"exception");

    }
    [_fileHandle closeFile];
    _fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:path];
    resolve(@"closed");
  }
}

//- (void)scanPath:(NSString *)sourcePath tree {
//
//  BOOL isDir;
//
//  [[NSFileManager defaultManager] fileExistsAtPath:sourcePath isDirectory:&isDir];
//
//  if(isDir)
//  {
//    NSArray *contentOfDirectory=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:sPath error:NULL];
//
//    NSUInteger contentcount = [contentOfDirectory count];
//    NSUInteger i;
//    for(i=0; i < contentcount;i++)
//    {
//      NSString *fileName = [contentOfDirectory objectAtIndex:i];
//      NSString *path = [sourcePath stringByAppendingFormat:@"%@%@",@"/",fileName];
//
//
//      if([[NSFileManager defaultManager] isDeletableFileAtPath:path])
//      {
//        NSLog(@"directory %@", path);
//        [self scanPath:path];
//      }
//    }
//
//  }
//  else
//  {
//    NSDictionary *dict
//    NSLog(@"file");
//  }
//}

RCT_EXPORT_METHOD(readDir:(NSString *)sourcePath
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{

  NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sourcePath

                                                                      error:NULL];
  NSMutableArray* result = [[NSMutableArray alloc] init];
  for(NSUInteger i=0; i < dirs.count; i++)
  {
    NSString *fileName = [dirs objectAtIndex:i];
    NSString *path = [sourcePath stringByAppendingFormat:@"%@%@",@"/", fileName];

    BOOL isDir;
    
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    [result addObject:@{@"path" : path,
                        @"filename": fileName,
                        @"isDir": @(isDir)
                        }];
  }

  resolve(result);
}

@end

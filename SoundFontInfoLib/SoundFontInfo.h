// Copyright © 2019 Brad Howes. All rights reserved.

#pragma once

#import <Foundation/Foundation.h>

@interface SoundFontInfoPreset : NSObject

@property (nonatomic, retain) NSString* name;
@property (nonatomic, assign) int bank;
@property (nonatomic, assign) int preset;

@end

@interface SoundFontInfo : NSObject {
}

@property (nonatomic, retain) NSURL* path;
@property (nonatomic, retain) NSString* embeddedName;
@property (nonatomic, retain) NSArray<SoundFontInfoPreset*>* patches;

+ (SoundFontInfo*)load:(NSURL*)url;

/// NOTE: Only used for testing
+ (SoundFontInfo*)parse:(NSURL*)url fileDescriptor:(int)fd fileSize:(uint64_t)fileSize;

- (void)dump:(NSString*)path;

@end

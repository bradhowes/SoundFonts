// Copyright © 2019 Brad Howes. All rights reserved.

#pragma once

#import <Foundation/Foundation.h>

@interface SoundFontInfoPreset : NSObject

@property (nonatomic, retain) NSString* name;
@property (nonatomic, assign) int bank;
@property (nonatomic, assign) int preset;

- (id) init:(NSString*)name bank:(int)bank preset:(int)preset;

@end

@interface SoundFontInfo : NSObject

@property (nonatomic, retain) NSURL* path;
@property (nonatomic, retain) NSString* embeddedName;
@property (nonatomic, retain) NSArray<SoundFontInfoPreset*>* presets;

+ (SoundFontInfo*)load:(NSURL*)url;

+ (id) parse:(NSURL*)url fileDescriptor:(int)fd fileSize:(uint64_t)fileSize;

- (id) init:(NSString*)name url:(NSURL*)url presets:(NSArray<SoundFontInfoPreset*>*)presets;

- (void)dump:(NSString*)path;

@end

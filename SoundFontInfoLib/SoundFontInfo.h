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

@property (nonatomic, retain) NSURL* url;
@property (nonatomic, retain) NSString* embeddedName;
@property (nonatomic, retain) NSString* embeddedAuthor;
@property (nonatomic, retain) NSString* embeddedComment;
@property (nonatomic, retain) NSString* embeddedCopyright;
@property (nonatomic, retain) NSArray<SoundFontInfoPreset*>* presets;

+ (SoundFontInfo*)loadViaParser:(NSURL*)url;
+ (SoundFontInfo*)loadViaFile:(NSURL*)url;

+ (SoundFontInfo*)parseViaParser:(NSURL*)url fileDescriptor:(int)fd fileSize:(uint64_t)fileSize;
+ (SoundFontInfo*)parseViaFile:(NSURL*)url fileDescriptor:(int)fd fileSize:(uint64_t)fileSize;

- (id) init:(NSString*)name
        url:(NSURL*)url
     author:(NSString*)embeddedAuthor
    comment:(NSString*)embeddedComment
  copyright:(NSString*)embeddedCopyright
    presets:(NSArray<SoundFontInfoPreset*>*)presets;

@end

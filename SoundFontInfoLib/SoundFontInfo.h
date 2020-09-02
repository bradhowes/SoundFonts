// Copyright © 2019 Brad Howes. All rights reserved.

#pragma once

#import <Foundation/Foundation.h>

@interface SoundFontInfoPatch : NSObject

@property (nonatomic, retain) NSString* name;
@property (nonatomic, assign) int bank;
@property (nonatomic, assign) int patch;

@end

@interface SoundFontInfo : NSObject {
}

@property (nonatomic, retain) NSData* contents;
@property (nonatomic, retain) NSString* embeddedName;
@property (nonatomic, retain) NSArray<SoundFontInfoPatch*>* patches;

+ (SoundFontInfo*)load:(NSURL*)url;
+ (SoundFontInfo*)parse:(NSData*)data;

- (void)dump:(NSString*)path;

@end

// Copyright © 2019 Brad Howes. All rights reserved.

#pragma once

#import <Foundation/Foundation.h>

@interface SoundFontInfoPatch : NSObject

@property (nonatomic, retain) NSString* name;
@property (nonatomic, assign) int bank;
@property (nonatomic, assign) int patch;

@end

@interface SoundFontInfo : NSObject {
    void const* dataPtr;
    size_t dataSize;
}

@property (nonatomic, retain) NSString* embeddedName;
@property (nonatomic, retain) NSArray<SoundFontInfoPatch*>* patches;

+ (SoundFontInfo*)parse:(void const*)data size:(size_t)size;

- (void)dump:(NSString*)path;

@end

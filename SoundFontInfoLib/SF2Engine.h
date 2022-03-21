// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#include <Foundation/Foundation.h>
#include <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Objective-C wrapper for the C++ Engine class in SF2Lib.
 */
@interface SF2Engine : NSObject

/// @returns maximum number of voices that can play simultaneously
@property (nonatomic, readonly) int voiceCount;

/// @returns number of voices that are currently generating audio
@property (nonatomic, readonly) int activeVoiceCount;

/// @returns number of presets in the loaded soundfont file
@property (nonatomic, readonly) int presetCount;

/// @returns URL of the currently-loaded file
@property (nonatomic, readonly, nullable) NSURL* url;

@property (nonatomic, readonly, nullable) NSString* shortName;

/**
 Constructor.

 @param voicesCount the maximum number of voices that can play simultaneously
 @param loggingBase the value to use as the base for creating loggers
 */
- (instancetype)initLoggingBase:(NSString*)loggingBase voiceCount:(int)voicesCount;

/**
 Set the rendering parameters prior to starting the audio unit graph.

 @param format the format of the output to generate, including the sample rate
 @param maxFramesToRender the maximum number of frames to expect in a render call from CoreAudio.
 */
- (void)setRenderingFormat:(NSInteger)busCount format: (AVAudioFormat*)format
         maxFramesToRender:(AUAudioFrameCount)maxFramesToRender;

/**
 Notification that rendering is done.
 */
- (void)renderingStopped;

/**
 Load a soundfont file activate a preset in it. If the URL is the same as the last load, just change to a new preset.

 @param url the location of the file to load
 @param index the index of the preset to activate
 @param shortName the name to use in the AU shortName property
 */
- (void)load:(NSURL*)url preset:(int)index shortName:(NSString*)shortName;

/**
 Set the active preset.

 @param bank the bank holding the preset to load
 @param program the program ID for the preset to load
 */
- (void)selectBank:(int)bank program:(int)program;

- (void)allOff;

- (void)noteOff:(int)key;

- (void)noteOn:(int)key velocity:(int)velocity;

- (AUInternalRenderBlock)internalRenderBlock;

@end

NS_ASSUME_NONNULL_END

// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#include <Foundation/Foundation.h>
#include <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, SF2EnginePresetChangeStatus) {
  SF2EnginePresetChangeStatus_OK = 0,
  SF2EnginePresetChangeStatus_FileNotFound = 100,
  SF2EnginePresetChangeStatus_CannotAccessFile = 200,
  SF2EnginePresetChangeStatus_InvalidIndex = 300
};

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

/// @returns the name of the current preset
@property (nonatomic, readonly) NSString* presetName;

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
 Load a soundfont file.

 @param url the location of the file to load
 */
- (SF2EnginePresetChangeStatus)load:(NSURL*)url;

/**
 Set the active preset.

 @param index the index of the preset to use
 */
- (SF2EnginePresetChangeStatus)selectPreset:(int)index;

/**
 Set the active preset.

 @param bank the bank holding the preset to load
 @param program the program ID for the preset to load
 */
- (void)selectBank:(int)bank program:(int)program;

/**
 Stop playing all notes
 */
- (void)stopAllNotes;

/**
 Stop playing the given MIDI key

 @param key the MIDI key to stop
 */
- (void)stopNote:(UInt8)note velocity:(UInt8)velocity;

/**
 Start playing the given MIDI key

 @param key the MIDI key to play
 @param velocity the velocity to apply to the note
 */
- (void)startNote:(UInt8)note velocity:(UInt8)velocity;

/// @returns the internal render block used to generate samples
- (AUInternalRenderBlock)internalRenderBlock;

@end

NS_ASSUME_NONNULL_END

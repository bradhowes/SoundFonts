// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#include <Foundation/Foundation.h>
#include <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Collection of presets and metadata for a specific SF2 soundfont file.
 */
@interface SF2Engine : NSObject

- (instancetype)init:(int)voiceCount;

- (void)setRenderingFormat:(AVAudioFormat*)format maxFramesToRender:(AUAudioFrameCount)maxFramesToRender;

- (void)renderingStopped;

- (void)load:(NSURL*)url preset:(int)index;

- (void)usePreset:(int)index;

- (int)voiceCount;

- (int)activeVoiceCount;

- (int)presetCount;

- (void)allOff;

- (void)noteOff:(int)key;

- (void)noteOn:(int)key velocity:(int)velocity;

- (AUInternalRenderBlock)internalRenderBlock;

@end

NS_ASSUME_NONNULL_END

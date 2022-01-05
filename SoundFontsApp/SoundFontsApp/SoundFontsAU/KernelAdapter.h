// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#import <AudioToolbox/AudioToolbox.h>

/// A tiny AudioUnit kernel adapter that supports a 'bypass' flag that when set will just write out zeros in the render
/// proc.
@interface KernelAdapter : NSObject

- (nonnull id)init:(nonnull NSString*)appExtensionName wrapped:(nonnull AUAudioUnit*)audioUnit;

/**
 Configure the kernel for new max frame in preparation to begin rendering

 @param maxFramesToRender the max frames to expect in a render request
 */
- (void)setMaxFramesToRender:(AUAudioFrameCount)maxFramesToRender;

/**
 Obtain an `internalRenderBlock` to use for the AudioUnit. This is pretty much a straight connection into the kernel
 with a splash of input value checking.
 */
- (nonnull AUInternalRenderBlock)internalRenderBlock;

/**
 Set the bypass state.
 
 @param state new bypass value
 */
- (void)setBypass:(BOOL)state;

@end

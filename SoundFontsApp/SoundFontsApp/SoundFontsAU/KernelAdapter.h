// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#import <AudioToolbox/AudioToolbox.h>

/// A tiny AudioUnit kernel adapter that supports a 'bypass' flag that when set will just write out zeros in the render
/// proc.
@interface KernelAdapter : NSObject

- (nonnull id)init:(nonnull NSString*)appExtensionName wrapped:(nonnull AUAudioUnit*)audioUnit;

- (nonnull AUInternalRenderBlock)internalRenderBlock;

/**
 Set the bypass state.
 
 @param state new bypass value
 */
- (void)setBypass:(BOOL)state;

@end

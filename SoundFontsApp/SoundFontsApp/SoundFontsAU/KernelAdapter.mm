// Copyright © 2022 Brad Howes. All rights reserved.

#import "KernelAdapter.h"

@implementation KernelAdapter {
  AUAudioUnit* _audioUnit;
  NSInteger _bypassed;
}

- (instancetype)init:(NSString*)appExtensionName wrapped:(nonnull AUAudioUnit *)audioUnit {
  if (self = [super init]) {
    _audioUnit = audioUnit;
    _bypassed = 0;
  }

  return self;
}

- (void)setBypass:(BOOL)state { _bypassed = state ? -1 : 0; }

- (AUInternalRenderBlock)internalRenderBlock {
  volatile NSInteger *bypassed = &_bypassed;
  AUAudioUnit *audioUnit = _audioUnit;

  return ^AUAudioUnitStatus(AudioUnitRenderActionFlags *actionFlags,
                            const AudioTimeStamp       *timestamp,
                            AUAudioFrameCount           frameCount,
                            NSInteger                   outputBusNumber,
                            AudioBufferList            *outputData,
                            const AURenderEvent        *realtimeEventListHead,
                            AURenderPullInputBlock      pullInputBlock) {
    if (*bypassed != 0) {
      NSLog(@"bypassed!");
      for (size_t channel = 0; channel < outputData->mNumberBuffers; ++channel) {
        memset(outputData->mBuffers[channel].mData, 1, outputData->mBuffers[channel].mDataByteSize);
      }
      return noErr;
    }
    return audioUnit.internalRenderBlock(actionFlags, timestamp, frameCount, outputBusNumber, outputData,
                                         realtimeEventListHead, pullInputBlock);
  };
}

@end

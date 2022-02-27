// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <os/log.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

#import "BufferFacet.hpp"

/**
 Maintains a buffer of PCM samples which is used to save samples from an upstream node.
 */
struct InputBuffer {

  /**
   Set the format of the buffer to use.

   @param format the format of the samples
   @param maxFrames the maximum number of frames to be requested in a render request
   */
  void allocateBuffers(AVAudioFormat* format, AUAudioFrameCount maxFrames)
  {
    maxFramesToRender_ = maxFrames;
    buffer_ = [[AVAudioPCMBuffer alloc] initWithPCMFormat: format frameCapacity: maxFrames];
    mutableAudioBufferList_ = buffer_.mutableAudioBufferList;
    bufferFacet_.setBufferList(mutableAudioBufferList_);
  }

  /**
   Forget any allocated buffer.
   */
  void releaseBuffers()
  {
    buffer_ = nullptr;
    mutableAudioBufferList_ = nullptr;
    bufferFacet_.release();
  }

  /**
   Obtain samples from an upstream node. Output is stored in internal buffer.

   @param actionFlags render flags from the host
   @param timestamp the current transport time of the samples
   @param frameCount the number of frames to process
   @param inputBusNumber the bus to pull from
   @param pullInputBlock the function to call to do the pulling
   */
  AUAudioUnitStatus pullInput(AudioUnitRenderActionFlags* actionFlags, AudioTimeStamp const* timestamp,
                              AVAudioFrameCount frameCount, NSInteger inputBusNumber,
                              AURenderPullInputBlock pullInputBlock)
  {
    if (pullInputBlock == nullptr) return kAudioUnitErr_NoConnection;
    prepareBufferList(frameCount);
    return pullInputBlock(actionFlags, timestamp, frameCount, inputBusNumber, mutableAudioBufferList_);
  }

  /**
   Update the input buffer to reflect current format.

   @param frameCount the number of frames to expect to place in the buffer
   */
  void prepareBufferList(AVAudioFrameCount frameCount)
  {
    UInt32 byteSize = frameCount * sizeof(AUValue);
    for (auto channel = 0; channel < mutableAudioBufferList_->mNumberBuffers; ++channel) {
      mutableAudioBufferList_->mBuffers[channel].mDataByteSize = byteSize;
    }
  }

  /// Obtain the maximum size of the input buffer
  AUAudioFrameCount capacity() const { return maxFramesToRender_; }

  /// Obtain a mutable version of the internal AudioBufferList.
  AudioBufferList* mutableAudioBufferList() const { return mutableAudioBufferList_; }

  /// Obtain a C++ vector facet using the internal buffer.
  BufferFacet& bufferFacet() { return bufferFacet_; }

  /// Obtain the number of channels in the buffer
  size_t channelCount() const { return bufferFacet_.channelCount(); }

private:
  os_log_t logger_ = os_log_create("SimplyFlange", "BufferedInputBus");
  AUAudioFrameCount maxFramesToRender_;
  AVAudioPCMBuffer* buffer_{nullptr};
  AudioBufferList* mutableAudioBufferList_{nullptr};
  BufferFacet bufferFacet_{};
};

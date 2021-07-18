// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <os/log.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

namespace SF2::Render {

/**
 Provides a simple std::vector view of an AudioBufferList, providing indexing by channel that returns a pointer to
 AUValue values in the buffer. The pointer value is updated in the `setOffset` call should be called before using
 the values from the std::vector.
 */
class BufferFacet {

public:

  /**
   Default constructor that does not hold a buffer list.
   */
  BufferFacet() : bufferList_{nullptr}, pointers_{} {}

  /**
   Install an AudioBufferList to work with. NOTE: this is a borrow operation; there is no management of the lifetime
   of the `bufferList` value.

   @param bufferList the AudioBufferList to use
   @param inPlaceSource an AudioBufferList to use for in-place operations. If AudioUnit does not support in-place
   then this should be OK to be a nullptr.
   */
  void setBufferList(AudioBufferList* bufferList, AudioBufferList* inPlaceSource) {
    bufferList_ = bufferList;
    if (bufferList->mBuffers[0].mData == nullptr) {
      assert(inPlaceSource != nullptr);
      for (auto channel = 0; channel < bufferList->mNumberBuffers; ++channel) {
        bufferList->mBuffers[channel].mData = inPlaceSource->mBuffers[channel].mData;
      }
    }

    size_t numBuffers = bufferList_->mNumberBuffers;
    pointers_.reserve(numBuffers);
    pointers_.clear();
    for (auto channel = 0; channel < numBuffers; ++channel) {
      pointers_.push_back(static_cast<AUValue*>(bufferList_->mBuffers[channel].mData));
    }
  }

  /**
   Set the number of frames that will be held in this buffer.

   @param frameCount the number of frames
   */
  void setFrameCount(AUAudioFrameCount frameCount) {
    assert(bufferList_ != nullptr);
    UInt32 byteSize = frameCount * sizeof(AUValue);
    for (auto channel = 0; channel < bufferList_->mNumberBuffers; ++channel) {
      bufferList_->mBuffers[channel].mDataByteSize = byteSize;
    }
  }

  /**
   Set the unprocessed offset value.

   @param offset the index of the next frame to process.
   */
  void setOffset(AUAudioFrameCount offset) {
    for (size_t channel = 0; channel < pointers_.size(); ++channel) {
      pointers_[channel] = static_cast<AUValue*>(bufferList_->mBuffers[channel].mData) + offset;
    }
  }

  /**
   Forget the buffer list and its buffer pointers.
   */
  void release() {
    bufferList_ = nullptr;
    pointers_.clear();
  }

  /**
   Copy frames from this instance into another one.

   @param destination the BufferFacet to receive the frames
   @param offset the offset to apply to *both* instances before performing the copy operation
   @param frameCount the number of frames to process
   */
  void copyInto(BufferFacet& destination, AUAudioFrameCount offset, AUAudioFrameCount frameCount) const {
    auto outputs = destination.bufferList_;
    for (auto channel = 0; channel < bufferList_->mNumberBuffers; ++channel) {

      // No need to copy if the buffers are the same.
      if (bufferList_->mBuffers[channel].mData == outputs->mBuffers[channel].mData) {
        continue;
      }

      auto in = static_cast<AUValue*>(bufferList_->mBuffers[channel].mData) + offset;
      auto out = static_cast<AUValue*>(outputs->mBuffers[channel].mData) + offset;
      memcpy(out, in, frameCount * sizeof(AUValue));
    }
  }

  /// @returns number of channels represented by the facet
  size_t channelCount() const { return pointers_.size(); }

  /// @returns writable pointer to a channel's buffer
  AUValue* channel(size_t index) const { return pointers_[index]; }

  /// @returns read-only reference to the collection of channel buffer pointers.
  const std::vector<AUValue*>& channels() const { return pointers_; }

private:
  AudioBufferList* bufferList_;
  std::vector<AUValue*> pointers_;
};

} // namespace SF2::Render

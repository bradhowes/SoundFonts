// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include <vector>

#include "Types.hpp"

namespace SF2::Render {

/**
 Circular buffer that acts as a delay for samples.
 */
class DelayBuffer {
public:

  /**
   Construct new buffer.

   @param sizeInSamples number of samples to hold in the buffer
   */
  DelayBuffer(Float sizeInSamples)
  : wrapMask_{smallestPowerOf2For(sizeInSamples) - 1}, buffer_(wrapMask_ + 1, 0.0), writePos_{0}
  {
    clear();
  }

  /**
   Clear the buffer by setting all entries to zero.
   */
  void clear() { std::fill(buffer_.begin(), buffer_.end(), 0.0); }

  /**
   Resize the buffer.

   @param sizeInSamples new number of samples to hold
   */
  void setSizeInSamples(Float sizeInSamples) {
    wrapMask_ = smallestPowerOf2For(sizeInSamples) - 1;
    buffer_.resize(wrapMask_ + 1);
    writePos_ = 0;
    clear();
  }

  /**
   Place a sample in the buffer, overwriting the oldest.

   @param value the value to write
   */
  void write(Float value) {
    buffer_[writePos_] = value;
    writePos_ = (writePos_ + 1) & wrapMask_;
  }

  /**
   Obtain the size of the buffer.

   @returns buffer size
   */
  size_t size() const { return buffer_.size(); }

  /**
   Read the value at the given offset from the newest value.

   @param offset the offset from the most recently written sample
   @returns the value from the buffer
   */
  Float readFromOffset(int offset) const { return buffer_[(writePos_ - offset) & wrapMask_]; }

  /**
   Read the value at the given offset from the newest value.

   @param delay the offset from the most recently written sample
   @returns the value from the buffer
   */
  Float read(Float delay) const {
    auto offset = int(delay);
    Float y1 = readFromOffset(offset);
    Float y2 = readFromOffset(offset + 1);
    auto partial = delay - offset;
    assert(partial >= 0.0 && partial < 1.0);
    return y2 * partial + (1.0 - partial) * y1;
  }

private:

  static size_t smallestPowerOf2For(Float value) {
    return size_t(std::exp2(std::ceil(std::log2(std::fmaxf(value, 1.0)))));
  }

  size_t wrapMask_;
  std::vector<Float> buffer_;
  size_t writePos_;
};

} // namespace SF2 Render

// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <limits>

#include "Logger.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/Sample/Bounds.hpp"

namespace SF2::Render::Sample {

/**
 Interpolatable index into a CanonicalBuffer. Maintains two counters, an integral one (size_t) and a partial one (double)
 that indicates how close the index is to a sample index. These two values are then used by SampleBuffer routines
 to fetch the correct samples and interpolate over them.

 Updates to the index honor loops in the sample stream if allowed. The index can also signal when it has reached the
 end of the sample stream via its `finished` method.
 */
struct BufferIndex {

  BufferIndex(const Bounds& bounds) : pos_{bounds.startPos()} {}

  /**
   Set the increment to use when advancing the index. This can change with each sample depending on what modulators
   are doing with the pitch value (eg vibrato).

   @param increment the value to apply when advancing the index
   */
  void setIncrement(double increment) {
    posIncrement_ = size_t(increment);
    partialIncrement_ = increment - double(posIncrement_);
  }

  void stop() { setIncrement(0.0); }

  bool finished() const { return posIncrement_ == 0 && partialIncrement_ == 0.0; }

  /**
   Increment the index to the next location. Properly handles looping and buffer end.

   @param bounds current boundaries and loop point for the sample being indexed
   @param canLoop true if looping is allowed
   */
  void increment(const Bounds& bounds, bool canLoop) {
    if (finished()) return;

    if (posIncrement_) pos_ += posIncrement_;
    partial_ += partialIncrement_;

    if (partial_ >= 1.0) {
      auto carry = size_t(partial_);
      pos_ += carry;
      partial_ -= carry;
    }

    if (canLoop && pos_ >= bounds.endLoopPos()) {
      log_.debug() << "looping" << std::endl;
      pos_ -= (bounds.endLoopPos() - bounds.startLoopPos());
    }
    else if (pos_ >= bounds.endPos()) {
      log_.debug() << "stopping" << std::endl;
      stop();
    }
  }

  /// @returns index to first sample to use for rendering
  size_t pos() const { return pos_; }

  /// @returns normalized position between 2 samples. For instance, 0.5 indicates half-way between two samples.
  double partial() const { return partial_; }

private:
  size_t pos_;
  size_t posIncrement_{0};
  double partial_{0.0};
  double partialIncrement_{0.0};
  inline static Logger log_{Logger::Make("Render.Sample", "BufferIndex")};
};

} // namespace Sf2::Render::Sample

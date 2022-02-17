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
class BufferIndex {
public:

  /**
   Create new instance

   @param bounds boundaries and optional loop point for the sample being indexed
   */
  explicit BufferIndex(const Bounds& bounds) : bounds_{bounds}, pos_{bounds.startPos()} {}

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

   @param canLoop true if looping is allowed
   */
  void increment(bool canLoop) {
    if (finished()) return;

    if (posIncrement_) pos_ += posIncrement_;
    partial_ += partialIncrement_;

    if (partial_ >= 1.0) {
      auto carry = size_t(partial_);
      pos_ += carry;
      partial_ -= carry;
    }

    if (canLoop && pos_ >= bounds_.endLoopPos()) {
      pos_ -= (bounds_.endLoopPos() - bounds_.startLoopPos());
    }
    else if (pos_ >= bounds_.endPos()) {
      log_.debug() << "stopping" << std::endl;
      stop();
    }
  }

  /// @returns index to first sample to use for rendering
  size_t pos() const { return pos_; }

  /// @returns normalized position between 2 samples. For instance, 0.5 indicates half-way between two samples.
  double partial() const { return partial_; }

private:
  const Bounds& bounds_;
  size_t pos_{0};
  size_t posIncrement_{0};
  double partial_{0.0};
  double partialIncrement_{0.0};

  inline static Logger log_{Logger::Make("Render.Sample", "BufferIndex")};
};

} // namespace Sf2::Render::Sample

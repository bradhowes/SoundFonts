// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <limits>

#include "Logger.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/Sample/Bounds.hpp"

namespace SF2::Render::Sample {

/**
 Interpolatable index into a NormalizedSampleSource. Maintains two counters, an integral one (size_t) and a partial
 one (double) that indicates how close the index is to a sample index. These two values are then used by SampleBuffer
 routines to fetch the correct samples and interpolate over them.

 Updates to the index honor loops in the sample stream if allowed. The index can also signal when it has reached the
 end of the sample stream via its `finished` method.
 */
class GeneratorIndex {
public:

  GeneratorIndex() = default;

  void configure(const Bounds& bounds)
  {
    bounds_ = bounds;
  }

  /// Signal that no further operations will take place using this index.
  void stop() { whole_ = bounds_.endPos(); }

  /// @returns true if the index has been stopped.
  bool finished() const { return whole_ >= bounds_.endPos(); }

  /**
   Increment the index to the next location. Properly handles looping and buffer end.

   @param canLoop true if looping is allowed
   */
  void increment(Float increment, bool canLoop) {
    if (finished()) return;

    auto wholeIncrement = size_t(increment);
    auto partialIncrement = increment - Float(wholeIncrement);

    whole_ += wholeIncrement;
    partial_ += partialIncrement;

    if (partial_ >= 1.0) {
      auto carry = size_t(partial_);
      whole_ += carry;
      partial_ -= carry;
    }

    if (canLoop && whole_ >= bounds_.endLoopPos()) {
      whole_ -= (bounds_.endLoopPos() - bounds_.startLoopPos());
    }
    else if (whole_ >= bounds_.endPos()) {
      log_.debug() << "stopping" << std::endl;
      stop();
    }
  }

  /// @returns index to first sample to use for rendering
  size_t whole() const { return whole_; }

  /// @returns normalized position between 2 samples. For instance, 0.5 indicates half-way between two samples.
  Float partial() const { return partial_; }

private:
  size_t whole_{0};
  Float partial_{0.0};
  Bounds bounds_{};

  inline static Logger log_{Logger::Make("Render.Sample", "GeneratorIndex")};
};

} // namespace Sf2::Render::Sample

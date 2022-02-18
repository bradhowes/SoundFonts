// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>
#include <os/signpost.h>
#include <AudioToolbox/AUParameters.h>
#include <vector>

#include "DSP/DSP.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/Sample/Bounds.hpp"
#include "Render/Sample/BufferIndex.hpp"
#include "Render/NormalizedSampleSource.hpp"
#include "Render/State.hpp"

namespace SF2::Render::Sample {

/**
 Generator of new samples from a stream of original samples, properly scaled to sound correct for the output sample
 rate and the desired output frequency. We know the original samples' sample rate and root frequency, so we can do some
 simple math to calculate a proper increment to use when iterating through the original samples, and with some proper
 interpolation we should end up with something that does not sound too harsh.
 */
class Generator {
public:
  using State = Render::State;

  enum struct Interpolator {
    linear,
    cubic4thOrder
  };

  Generator(State& state, Interpolator kind) : state_{state}, interpolator_{kind} {}

  void configure();

//  bounds_{bounds},
//  interpolator_{kind},
//  sampleRateRatio_{samples.header().sampleRate() / sampleRate},
//  bufferIndex_{bounds}
//  {
//    samples.load();
//  }

  /**
   Obtain an interpolated sample value at the given index.

   @param pitch the pitch of the audio to generate
   @param canLoop true if the generator is permitted to loop for more samples
   @returns new sample value
   */
  
  Float generate(Float pitch, bool canLoop) {
    auto pos = bufferIndex_.pos();
    if (pos >= bounds_.endPos()) return 0.0;
    auto partial = bufferIndex_.partial();

    calculateIndexIncrement(pitch);
    bufferIndex_.increment(canLoop);

    switch (interpolator_) {
      case Interpolator::linear: return linearInterpolate(pos, partial, canLoop);
      case Interpolator::cubic4thOrder: return cubic4thOrderInterpolate(pos, partial, canLoop);
    }
  }

private:
  using InterpolatorProc = std::function<Float(size_t, Float)>;

  void calculateIndexIncrement(Float pitch) {

    // Don't keep calculating buffer increments if nothing has changed.
    if (pitch == lastPitch_ && !bufferIndex_.finished()) return;

    lastPitch_ = pitch;
    Float exponent = (pitch - samples_->header().originalMIDIKey() + samples_->header().pitchCorrection() / 100.0) / 12.0;
    Float frequencyRatio = std::exp2(exponent);
    Float increment = sampleRateRatio_ * frequencyRatio;
    bufferIndex_.setIncrement(increment);
  }

  /**
   Obtain a linearly interpolated sample for a given index value.

   @param pos the index of the first sample to use
   @param partial the non-integral part of the index
   @param canLoop true if wrapping around in loop is allowed
   @returns interpolated sample result
   */
  Float linearInterpolate(size_t pos, Float partial, bool canLoop) const {
    auto x0 = (*samples_)[pos++];
    auto x1 = sample(pos, canLoop);
    return DSP::Interpolation::linear(partial, x0, x1);
  }

  /**
   Obtain a cubic 4th-order interpolated sample for a given index value.

   @param pos the index of the first sample to use
   @param partial the non-integral part of the index
   @param canLoop true if wrapping around in loop is allowed
   @returns interpolated sample result
   */
  Float cubic4thOrderInterpolate(size_t pos, Float partial, bool canLoop) const {
    auto x0 = before(pos, canLoop);
    auto x1 = sample(pos++, canLoop);
    auto x2 = sample(pos++, canLoop);
    auto x3 = sample(pos++, canLoop);
    return DSP::Interpolation::cubic4thOrder(partial, x0, x1, x2, x3);
  }

  Float sample(size_t pos, bool canLoop) const {
    if (pos == bounds_.endLoopPos() && canLoop) pos = bounds_.startLoopPos();
    return pos < samples_->size() ? (*samples_)[pos] : 0.0;
  }

  Float before(size_t pos, bool canLoop) const {
    if (pos == 0) return 0.0;
    if (pos == bounds_.startLoopPos() && canLoop) pos = bounds_.endLoopPos();
    return (*samples_)[pos - 1];
  }

  State& state_;
  Interpolator interpolator_;
  const NormalizedSampleSource* samples_{nullptr};
  Bounds bounds_;
  BufferIndex bufferIndex_{bounds_};
  Float sampleRateRatio_;
  Float lastPitch_{0.0};
};

} // namespace SF2::Render::Sample

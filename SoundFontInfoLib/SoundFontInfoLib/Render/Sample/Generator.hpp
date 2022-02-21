// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>
#include <os/signpost.h>
#include <AudioToolbox/AUParameters.h>
#include <vector>

#include "DSP/DSP.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/Sample/Bounds.hpp"
#include "Render/Sample/GeneratorIndex.hpp"
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

  Generator(State& state, Interpolator kind) :
  state_{state}, interpolatorProc_{interpolator(kind)} {}

  void configure(const NormalizedSampleSource& sampleSource)
  {
    sampleSource_ = &sampleSource;
    bounds_ = Bounds::make(sampleSource.header(), state_);
    index_ = GeneratorIndex(bounds_);
    sampleRateRatio_ = sampleSource_->header().sampleRate() / state_.sampleRate();
    sampleSource_->load();
  }

  /**
   Obtain an interpolated sample value at the given index.

   @param pitch the pitch of the audio to generate
   @param canLoop true if the generator is permitted to loop for more samples
   @returns new sample value
   */
  
  Float generate(Float pitch, bool canLoop) {
    auto whole = index_.whole();
    if (whole >= bounds_.endPos()) return 0.0;
    auto partial = index_.partial();

    calculateIndexIncrement(pitch);
    index_.increment(canLoop);

    return interpolatorProc_(this, whole, partial, canLoop);
  }

private:
  using InterpolatorProc = std::function<Float(Generator*, size_t, Float, bool)>;

  static InterpolatorProc interpolator(Interpolator kind) {
    return kind == Interpolator::linear ? &Generator::linearInterpolate : &Generator::cubic4thOrderInterpolate;
  }

  void calculateIndexIncrement(Float pitch) {

    // Don't keep calculating buffer increments if nothing has changed.
    if (pitch == lastPitch_ && !index_.finished()) return;

    lastPitch_ = pitch;
    Float exponent = (pitch - sampleSource_->header().originalMIDIKey() +
                      sampleSource_->header().pitchCorrection() / 100.0) / 12.0;
    Float frequencyRatio = std::exp2(exponent);
    Float increment = sampleRateRatio_ * frequencyRatio;
    index_.setIncrement(increment);
  }

  /**
   Obtain a linearly interpolated sample for a given index value.

   @param whole the index of the first sample to use
   @param partial the non-integral part of the index
   @param canLoop true if wrapping around in loop is allowed
   @returns interpolated sample result
   */
  Float linearInterpolate(size_t whole, Float partial, bool canLoop) const {
    return DSP::Interpolation::linear(partial, sample(whole, canLoop), sample(whole + 1, canLoop));
  }

  /**
   Obtain a cubic 4th-order interpolated sample for a given index value.

   @param whole the index of the first sample to use
   @param partial the non-integral part of the index
   @param canLoop true if wrapping around in loop is allowed
   @returns interpolated sample result
   */
  Float cubic4thOrderInterpolate(size_t whole, Float partial, bool canLoop) const {
    return DSP::Interpolation::cubic4thOrder(partial, before(whole, canLoop), sample(whole, canLoop),
                                             sample(whole, canLoop) + 1, sample(whole, canLoop) + 2);
  }

  Float sample(size_t whole, bool canLoop) const {
    if (whole == bounds_.endLoopPos() && canLoop) whole = bounds_.startLoopPos();
    return whole < sampleSource_->size() ? (*sampleSource_)[whole] : 0.0;
  }

  Float before(size_t whole, bool canLoop) const {
    if (whole == 0) return 0.0;
    if (whole == bounds_.startLoopPos() && canLoop) whole = bounds_.endLoopPos();
    return (*sampleSource_)[whole - 1];
  }

  State& state_;
  InterpolatorProc interpolatorProc_;
  const NormalizedSampleSource* sampleSource_{nullptr};
  Bounds bounds_;
  GeneratorIndex index_{};
  Float sampleRateRatio_;
  Float lastPitch_{0.0};
};

} // namespace SF2::Render::Sample

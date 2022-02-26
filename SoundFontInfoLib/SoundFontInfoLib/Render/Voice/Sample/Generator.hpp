// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>
#include <os/signpost.h>
#include <AudioToolbox/AUParameters.h>
#include <vector>

#include "DSP/DSP.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/Voice/Sample/NormalizedSampleSource.hpp"
#include "Render/Voice/Sample/Bounds.hpp"
#include "Render/Voice/Sample/Index.hpp"
#include "Render/Voice/Sample/Pitch.hpp"
#include "Render/Voice/State/State.hpp"

namespace SF2::Render::Voice::Sample {

/**
 Generator of new samples from a stream of original samples, properly scaled to sound correct for the output sample
 rate and the desired output frequency. We know the original samples' sample rate and root frequency, so we can do some
 simple math to calculate a proper increment to use when iterating through the original samples, and with some proper
 interpolation we should end up with something that does not sound too harsh.
 */
class Generator {
public:
  using State = State::State;

  enum struct Interpolator {
    linear,
    cubic4thOrder
  };

  Generator(State& state, Interpolator kind) :
  state_{state}, interpolatorProc_{interpolator(kind)} {}

  void configure(const NormalizedSampleSource& sampleSource)
  {
    bounds_ = Bounds::make(sampleSource.header(), state_);
    index_.configure(bounds_);
    sampleSource_ = &sampleSource;
    sampleSource_->load();
  }

  /**
   Obtain an interpolated sample value at the current index.

   @param increment the increment to use to move to the next sample
   @param canLoop true if the generator is permitted to loop for more samples
   @returns new sample value
   */
  Float generate(Float increment, bool canLoop) {
    if (index_.finished()) return 0.0;
    auto whole = index_.whole();
    auto partial = index_.partial();
    index_.increment(increment, canLoop);
    return interpolatorProc_(this, whole, partial, canLoop);
  }

private:
  using InterpolatorProc = std::function<Float(Generator*, size_t, Float, bool)>;

  static InterpolatorProc interpolator(Interpolator kind) {
    return kind == Interpolator::linear ? &Generator::linearInterpolate : &Generator::cubic4thOrderInterpolate;
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
  Bounds bounds_;
  Index index_;
  InterpolatorProc interpolatorProc_;
  const NormalizedSampleSource* sampleSource_{nullptr};
};

} // namespace SF2::Render::Sample

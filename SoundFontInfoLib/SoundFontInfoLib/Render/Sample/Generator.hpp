// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>
#include <os/signpost.h>
#include <AudioToolbox/AUParameters.h>
#include <vector>

#include "DSP/DSP.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/Sample/BufferIndex.hpp"
#include "Render/Sample/CanonicalBuffer.hpp"
#include "Render/Sample/PitchControl.hpp"
#include "Render/Sample/Bounds.hpp"
#include "Render/Voice/State.hpp"

namespace SF2::Render::Sample {

template <typename S> class TGenerator {
public:
  TGenerator(S&& source) : source_{std::move(source)} {}

  double generate(double pitchAdjustment, bool canLoop) { return source_.generate(pitchAdjustment, canLoop); }

private:
  S source_;
};

class ConstantGenerator {
public:
  ConstantGenerator(double value) : value_{value} {}

  double generate(double pitchAdjustment, bool canLoop) {
    return value_;
  }

private:
  double value_;
};

class SineGenerator {
public:

  SineGenerator(double dTheta) : theta_{0.0}, dTheta_{dTheta} {}

  double generate(double pitchAdjustment, bool canLoop) {
    auto value = std::sin(theta_);
    theta_ += dTheta_;
    if (theta_ >= DSP::TwoPI) {
      theta_ -= DSP::TwoPI;
    }
    return value;
  }

private:
  double theta_;
  double dTheta_;
};

/**
 Generator of new samples from a stream of original samples, properly scaled to sound correct for the output sample
 rate and the desired output frequency. We know the original samples' sample rate and root frequency, so we can do some
 simple math to calculate a proper increment to use when iterating through the original samples, and with some proper
 interpolation we should end up with something that does not sound too harsh.
 */
class InterpolatedGenerator {
public:

  enum struct Interpolator {
    linear,
    cubic4thOrder
  };

  /**
   Construct a new sample generator.

   @param samples source of audio samples
   @param state the generator state to use for rendering
   @param kind the kind of interpolation to perform when generating the render samples
   */
  InterpolatedGenerator(const CanonicalBuffer& samples, const Voice::State& state,
                        Interpolator kind = Interpolator::linear) :
  samples_{samples}, state_{state}, interpolator_{kind}, bounds_{samples.header(), state},
  sampleRateRatio_{samples_.header().sampleRate() / state_.sampleRate()}, bufferIndex_{bounds_} {
    samples.load();
  }

  /**
   Obtain an interpolated sample value at the given index.

   @param pitchAdjustment value to add to the fundamental pitch of the key being played
   @param canLoop true if the generator is permitted to loop for more samples
   @returns new sample value
   */
  double generate(double pitchAdjustment, bool canLoop) {
    auto pos = bufferIndex_.pos();
    if (pos >= bounds_.endPos()) return 0.0;
    auto partial = bufferIndex_.partial();

    calculateIndexIncrement(pitchAdjustment);
    bufferIndex_.increment(bounds_, canLoop);

    switch (interpolator_) {
      case Interpolator::linear: return linearInterpolate(pos, partial, canLoop);
      case Interpolator::cubic4thOrder: return cubic4thOrderInterpolate(pos, partial, canLoop);
    }
  }

private:

  void calculateIndexIncrement(double pitchAdjustment) {

    // Don't keep calculating buffer increments if nothing has changed.
    if (pitchAdjustment == lastPitchAdjustment_ && !bufferIndex_.finished()) return;

    lastPitchAdjustment_ = pitchAdjustment;
    double exponent = (state_.pitch() + pitchAdjustment - samples_.header().originalMIDIKey()) / 12.0;
    double frequencyRatio = std::exp2(exponent);
    double increment = sampleRateRatio_ * frequencyRatio;
    bufferIndex_.setIncrement(increment);
  }

  /**
   Obtain a linearly interpolated sample for a given index value.

   @param pos the index of the first sample to use
   @param partial the non-integral part of the index
   @param canLoop true if wrapping around in loop is allowed
   @returns interpolated sample result
   */
  double linearInterpolate(size_t pos, double partial, bool canLoop) const {
    auto x0 = samples_[pos++];
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
  double cubic4thOrderInterpolate(size_t pos, double partial, bool canLoop) const {
    auto x0 = before(pos, canLoop);
    auto x1 = sample(pos++, canLoop);
    auto x2 = sample(pos++, canLoop);
    auto x3 = sample(pos++, canLoop);
    return DSP::Interpolation::cubic4thOrder(partial, x0, x1, x2, x3);
  }

  double sample(size_t pos, bool canLoop) const {
    if (pos == bounds_.endLoopPos() && canLoop) pos = bounds_.startLoopPos();
    return pos < samples_.size() ? samples_[pos] : 0.0;
  }

  double before(size_t pos, bool canLoop) const {
    if (pos == 0) return 0.0;
    if (pos == bounds_.startLoopPos() && canLoop) pos = bounds_.endLoopPos();
    return samples_[pos - 1];
  }

  const CanonicalBuffer& samples_;
  const Voice::State& state_;
  Interpolator interpolator_;
  Bounds bounds_;
  BufferIndex bufferIndex_;
  double sampleRateRatio_;
  double lastPitchAdjustment_{0.0};
};

} // namespace SF2::Render::aSample

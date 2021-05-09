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

namespace SF2 {
namespace Render {
namespace Sample {

/**
 Generator of new samples from a stream of original samples, properly scaled to sound correct for the output sample
 rate and the desired output frequency. We know the original samples' sample rate and root frequency, so we can do some
 simple math to calculate a proper increment to use when iterating through the original samples, and with some proper
 interpolation we should end up with something that does not sound too harsh.
 */
class Generator {
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
    Generator(const CanonicalBuffer& samples, const Voice::State& state, Interpolator kind = Interpolator::linear) :
    samples_{samples}, state_{state}, interpolator_{kind}, bounds_{samples.header(), state},
    sampleRateRatio_{samples_.header().sampleRate() / state_.sampleRate()}, bufferIndex_{bounds_} {
        samples.load();
    }

    /**
     Obtain an interpolated sample value at the given index.

     @returns new sample value
     */
    double generate(double pitchAdjustment, bool canLoop) {
        auto index = bufferIndex_.index();
        if (index >= bounds_.endIndex()) return 0.0;
        auto partial = bufferIndex_.partial();

        calculateIndexIncrement(pitchAdjustment);
        bufferIndex_.increment(bounds_, canLoop);

        switch (interpolator_) {
            case Interpolator::linear: return linearInterpolate(index, partial, canLoop);
            case Interpolator::cubic4thOrder: return cubic4thOrderInterpolate(index, partial, canLoop);
        }
    }

private:

    void calculateIndexIncrement(double pitchAdjustment) {
        if (pitchAdjustment == lastPitchAdjustment_ && bufferIndex_.hasIncrement()) return;
        lastPitchAdjustment_ = pitchAdjustment;
        double frequencyRatio = std::pow(2.0, (state_.pitch() + pitchAdjustment -
                                               samples_.header().originalMIDIKey()) / 12.0);
        double increment = sampleRateRatio_ * frequencyRatio;
        bufferIndex_.setIncrement(increment);
    }

    /**
     Obtain a linearly interpolated sample for a given index value.

     @param index the index of the first sample to use
     @param partial the non-integral part of the index
     @param canLoop true if wrapping around in loop is allowed
     @returns interpolated sample result
     */
    double linearInterpolate(size_t index, double partial, bool canLoop) const {
        auto x0 = samples_[index++];
        auto x1 = sample(index, canLoop);
        return DSP::Interpolation::linear(partial, x0, x1);
    }

    /**
     Obtain a cubic 4th-order interpolated sample for a given index value.

     @param index the index of the first sample to use
     @param partial the non-integral part of the index
     @param canLoop true if wrapping around in loop is allowed
     @returns interpolated sample result
     */
    double cubic4thOrderInterpolate(size_t index, double partial, bool canLoop) const {
        auto x0 = before(index, canLoop);
        auto x1 = sample(index++, canLoop);
        auto x2 = sample(index++, canLoop);
        auto x3 = sample(index++, canLoop);
        return DSP::Interpolation::cubic4thOrder(partial, x0, x1, x2, x3);
    }

    double sample(size_t index, bool canLoop) const {
        if (index == bounds_.endLoopIndex() && canLoop) index = bounds_.startLoopIndex();
        return index < samples_.size() ? samples_[index] : 0.0;
    }

    double before(size_t index, bool canLoop) const {
        if (index == 0) return 0.0;
        if (index == bounds_.startLoopIndex() && canLoop) index = bounds_.endLoopIndex();
        return samples_[index - 1];
    }

    const CanonicalBuffer& samples_;
    const Voice::State& state_;
    Interpolator interpolator_;
    Bounds bounds_;
    BufferIndex bufferIndex_;
    double sampleRateRatio_;
    double lastPitchAdjustment_{0.0};
};

} // namespace Sample
} // namespace Render
} // namespace SF2

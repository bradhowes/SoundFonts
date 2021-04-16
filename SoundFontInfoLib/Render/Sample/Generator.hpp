// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>
#include <os/signpost.h>
#include <AudioToolbox/AUParameters.h>
#include <vector>

#include "Entity/SampleHeader.hpp"
#include "Render/DSP.hpp"
#include "Render/Sample/BufferIndex.hpp"
#include "Render/Sample/CanonicalBuffer.hpp"
#include "Render/Sample/Bounds.hpp"
#include "Render/Voice/State.hpp"

namespace SF2 {
namespace Render {
namespace Sample {

template <typename T>
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
    Generator(const CanonicalBuffer<T>& samples, const Voice::State& state, Interpolator kind = Interpolator::linear) :
    samples_{samples}, state_{state}, interpolator_{kind}, bounds_{samples.header(), state},
    bufferIndex_{} {
        samples.load();
        auto sampleRateRatio = double(samples.header().sampleRate()) / state.sampleRate();
        auto frequencyRatio = double(std::pow(2.0, double(state.pitch() - samples.header().originalMIDIKey()) / 12.0));
        auto increment = sampleRateRatio * frequencyRatio;
        bufferIndex_.setIncrement(increment);
    }

    /**
     Obtain an interpolated sample value at the given index.

     @returns new sample value
     */
    inline T generate(bool canLoop) {
        auto index = bufferIndex_.index();
        if (index >= samples_.size()) return 0.0;
        auto partial = bufferIndex_.partial();
        bufferIndex_.increment(bounds_, canLoop);
        switch (interpolator_) {
            case Interpolator::linear: return linearInterpolate(index, partial, canLoop);
            case Interpolator::cubic4thOrder: return cubic4thOrderInterpolate(index, partial, canLoop);
        }
    }

private:

    /**
     Obtain a linearly interpolated sample for a given index value.

     @param index the index of the first sample to use
     @param partial the non-integral part of the index
     @param canLoop true if wrapping around in loop is allowed
     @returns interpolated sample result
     */
    inline T linearInterpolate(size_t index, double partial, bool canLoop) const {
        auto x0 = samples_[index++];
        auto x1 = sample(index, canLoop);
        return DSP::Interpolation::Linear<T>::interpolate(partial, x0, x1);
    }

    /**
     Obtain a cubic 4th-order interpolated sample for a given index value.

     @param index the index of the first sample to use
     @param partial the non-integral part of the index
     @param canLoop true if wrapping around in loop is allowed
     @returns interpolated sample result
     */
    inline T cubic4thOrderInterpolate(size_t index, double partial, bool canLoop) const {
        auto x0 = before(index, canLoop);
        auto x1 = sample(index++, canLoop);
        auto x2 = sample(index++, canLoop);
        auto x3 = sample(index++, canLoop);
        return DSP::Interpolation::Cubic4thOrder<T>::interpolate(partial, x0, x1, x2, x3);
    }

    inline T sample(size_t index, bool canLoop) const {
        if (index == bounds_.endLoopIndex() && canLoop) index = bounds_.startLoopIndex();
        return index < samples_.size() ? samples_[index] : 0.0;
    }

    inline T before(size_t index, bool canLoop) const {
        if (index == 0) return 0.0;
        if (index == bounds_.startLoopIndex() && canLoop) index = bounds_.endLoopIndex();
        return samples_[index - 1];
    }

    const CanonicalBuffer<T>& samples_;
    const Voice::State& state_;
    Interpolator interpolator_;
    Bounds bounds_;
    BufferIndex bufferIndex_;
};

} // namespace Sample
} // namespace Render
} // namespace SF2

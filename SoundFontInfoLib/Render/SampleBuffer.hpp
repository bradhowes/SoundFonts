// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>
#include <AudioToolbox/AUParameters.h>
#include <vector>

#include "Entity/SampleHeader.hpp"
#include "Render/DSP.hpp"
#include "Render/SampleIndex.hpp"

namespace SF2 {
namespace Render {

class SampleBuffer {
public:
    enum struct Interpolator {
        linear,
        cubic4thOrder
    };

    /**
     Construct a new normalized buffer of samples.

     @param samples pointer to the first 16-bit sample in the SF2 file
     @param header defines the range of samples to use for a sound
     */
    SampleBuffer(const int16_t* samples, const Entity::SampleHeader& header,
                 Interpolator kind = Interpolator::cubic4thOrder)
    : allSamples_{samples}, samples_{}, header_{header}, interpolator_{kind} {}

    inline void load() const { if (samples_.empty()) loadNormalizedSamples(); }

    bool isLoaded() const { return !samples_.empty(); }

    inline AUValue read(SampleIndex& sampleIndex, bool canLoop) const {
        auto index = sampleIndex.index();
        if (index >= header_.end()) return 0.0;
        auto partial = sampleIndex.partial();
        sampleIndex.increment(canLoop);
        switch (interpolator_) {
            case Interpolator::linear: return linearInterpolate(index, partial, canLoop);
            case Interpolator::cubic4thOrder: return cubic4thOrderInterpolate(index, partial, canLoop);
        }
    }

    /**
     Obtain an interpolated sample for a given index value.

     @param index the index of the first sample to use
     @param partial the non-integral part of the index
     @param canLoop true if wrapping around in loop is allowed
     @returns interpolated sample result
     */
    inline AUValue linearInterpolate(size_t index, double partial, bool canLoop) const {
        auto x0 = samples_[index++];
        auto x1 = sample(index, canLoop);
        return DSP::Interpolation::Linear::interpolate(partial, x0, x1);
    }

    /**
     Obtain a cubic 4th-order interpolated sample for a given index value.

     @param index the index of the first sample to use
     @param partial the non-integral part of the index
     @param canLoop true if wrapping around in loop is allowed
     @returns interpolated sample result
     */
    inline AUValue cubic4thOrderInterpolate(size_t index, double partial, bool canLoop) const {
        auto x0 = samples_[index++];
        auto x1 = sample(index++, canLoop);
        auto x2 = sample(index++, canLoop);
        auto x3 = sample(index++, canLoop);
        return DSP::Interpolation::Cubic4thOrder::interpolate(partial, x0, x1, x2, x3);
    }

private:

    inline AUValue sample(size_t index, bool canLoop) const {
        if (index == header_.loopEnd() && canLoop) index = header_.loopBegin();
        return index < header_.end() ? samples_[index] : 0.0;
    }

    void loadNormalizedSamples() const;

    const int16_t* allSamples_;
    mutable std::vector<AUValue> samples_;
    const Entity::SampleHeader& header_;
    Interpolator interpolator_;
};

} // namespace Render
} // namespace SF2

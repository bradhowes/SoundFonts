// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>
#include <os/signpost.h>
#include <AudioToolbox/AUParameters.h>
#include <vector>

#include "Entity/SampleHeader.hpp"
#include "Render/DSP.hpp"
#include "Render/SampleIndex.hpp"

namespace SF2 {
namespace Render {

/**
 Contains a collection of audio samples that range between -1.0 and 1.0. The values are derived from the
 16-bit values found in the SF2 file. Note that this conversion is done on-demand via the first call to
 `load`.

 Provides an interface for obtaining values from the buffer via a SampleIndex index. The actual returned value will be
 interpolated, either by simple linear weighting over 2 samples, or via cubic 4th-order interpolation over 4 samples.
 */
template <typename T>
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
     @param kind the kind of interpolation to use when returning values from `read`
     */
    SampleBuffer(const int16_t* samples, const Entity::SampleHeader& header,
                 Interpolator kind = Interpolator::cubic4thOrder)
    : allSamples_{samples}, samples_{}, header_{header}, interpolator_{kind} {}

    /**
     Load the samples into buffer if not already available.
     */
    inline void load() const { if (samples_.empty()) loadNormalizedSamples(); }

    /// @returns true if the buffer is loaded
    bool isLoaded() const { return !samples_.empty(); }

    /**
     Obtain an interpolated sample value at the given index.

     @param sampleIndex the index to fetch. NOTE: index is updated to point to next position
     */
    inline T read(SampleIndex& sampleIndex, bool canLoop) const {
        auto index = sampleIndex.index();
        if (index >= header_.end()) return 0.0;
        auto partial = sampleIndex.partial();
        sampleIndex.increment(canLoop);
        switch (interpolator_) {
            case Interpolator::linear: return linearInterpolate(index, partial, canLoop);
            case Interpolator::cubic4thOrder: return cubic4thOrderInterpolate(index, partial, canLoop);
        }
    }

private:

    /**
     Obtain an linearly interpolated sample for a given index value.

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

    inline AUValue sample(size_t index, bool canLoop) const {
        if (index == header_.loopEnd() && canLoop) index = header_.loopBegin();
        return index < header_.end() ? samples_[index] : 0.0;
    }

    inline AUValue before(size_t index, bool canLoop) const {
        if (index == header_.begin()) return 0.0;
        if (index == header_.loopBegin() && canLoop) index = header_.loopEnd();
        return samples_[index - 1];
    }

    void loadNormalizedSamples() const {
        static constexpr AUValue scale = 1.0 / 32768.0;

        os_log_t log = os_log_create("SF2", "loadSamples");
        auto signpost = os_signpost_id_generate(log);
        size_t size = header_.end() - header_.begin();
        os_signpost_interval_begin(log, signpost, "SampleBuffer", "begin - size: %ld", size);
        samples_.reserve(size);
        samples_.clear();
        auto pos = allSamples_ + header_.begin();
        while (size-- > 0) samples_.emplace_back(*pos++ * scale);
        os_signpost_interval_end(log, signpost, "SampleBuffer", "end");
    }

    const int16_t* allSamples_;
    mutable std::vector<T> samples_;
    const Entity::SampleHeader& header_;
    Interpolator interpolator_;
};

} // namespace Render
} // namespace SF2

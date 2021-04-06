// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>
#include <AudioToolbox/AUParameters.h>
#include <vector>

#include "Entity/SampleHeader.hpp"
#include "Render/SampleIndex.hpp"

namespace SF2 {
namespace Render {

class SampleBuffer {
public:

    /**
     Construct a new normalized buffer of samples.

     @param samples pointer to the first 16-bit sample in the SF2 file
     @param header defines the range of samples to use for a sound
     */
    SampleBuffer(const int16_t* samples, const Entity::SampleHeader& header) : samples_{}, header_{header} {
        loadNormalizedSamples(samples);
    }

    /**
     Obtain an interpolated sample for a given index value.

     @param sampleIndex the index to to read at
     @returns interpolated sample result
     */
    AUValue read(SampleIndex& sampleIndex, bool canLoop) const {
        size_t offset = size_t(sampleIndex.pos());
        if (offset >= samples_.size()) return 0.0;

        auto w2 = sampleIndex.pos() - offset;
        auto w1 = (1.0 - w2);
        auto x1 = samples_[offset];
        if (++offset == header_.loopEnd() && canLoop) offset = header_.loopBegin();
        auto x2 = samples_[offset];

        sampleIndex.increment(canLoop);

        return x1 * w1 + x2 * w2;
    }

private:
    void loadNormalizedSamples(const int16_t* samples);

    std::vector<AUValue> samples_;
    const Entity::SampleHeader& header_;
};

} // namespace Render
} // namespace SF2

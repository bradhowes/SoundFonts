// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <limits>

#include "Entity/SampleHeader.hpp"

namespace SF2 {
namespace Render {

/**
 Interpolatable index into a SampleBuffer. Maintains two counters, an integral one (size_t) and a partial one (double)
 that indicates how close the index is to a sample index. These two values are then used by SampleBuffer routines
 to fetch the correct samples and interpolate over them.

 Updates to the index honor loops in the sample stream if allowed. The index can also signal when it has reached the
 end of the sample stream via its `finished` method.
 */
struct SampleIndex {

    /**
     Construct new instance.

     @param header description of the samples being indexed
     @param increment the increment used to advance the index
     */
    SampleIndex(const Entity::SampleHeader& header, double increment)
    : index_{0}, partial_{0.0}, header_{header}
    {
        indexIncrement_ = size_t(increment);
        partialIncrement_ = increment - double(indexIncrement_);
    }

    /**
     Increment the index to the next location.

     @param canLoop if true allow wrapping to loop start
     */
    void increment(bool canLoop) {
        if (finished()) return;
        index_ += indexIncrement_;
        partial_ += partialIncrement_;

        if (partial_ >= 1.0) {
            auto carry = size_t(partial_);
            index_ += carry;
            partial_ -= carry;
        }

        if (index_ >= header_.loopEnd() && canLoop) {
            index_ -= (header_.loopEnd() - header_.loopBegin());
        }
    }

    /// @returns true if there a no more samples to index
    bool finished() const { return index_ >= header_.end(); }

    /// @returns index to first sample to use for rendering
    size_t index() const { return index_; }

    /// @returns normalized position between 2 samples. For instance, 0.5 indicates half-way between two samples.
    double partial() const { return partial_; }

private:
    size_t indexIncrement_;
    double partialIncrement_;
    size_t index_;
    double partial_;
    const Entity::SampleHeader& header_;
};

} // namespace Render
} // namespace SF2

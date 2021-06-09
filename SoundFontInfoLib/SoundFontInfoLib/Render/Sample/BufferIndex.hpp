// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <limits>

#include "Logger.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/Sample/Bounds.hpp"

namespace SF2::Render::Sample {

/**
 Interpolatable index into a CanonicalBuffer. Maintains two counters, an integral one (size_t) and a partial one (double)
 that indicates how close the index is to a sample index. These two values are then used by SampleBuffer routines
 to fetch the correct samples and interpolate over them.

 Updates to the index honor loops in the sample stream if allowed. The index can also signal when it has reached the
 end of the sample stream via its `finished` method.
 */
struct BufferIndex {

    BufferIndex(const Bounds& bounds) : index_{bounds.startIndex()} {}

    /**
     Set the increment to use when advancing the index. This can change with each sample depending on what modulators
     are doing with the pitch value (eg vibrato).

     @param increment the value to apply when advancing the index
     */
    void setIncrement(double increment) {
        indexIncrement_ = size_t(increment);
        partialIncrement_ = increment - double(indexIncrement_);
    }

    bool hasIncrement() const { return indexIncrement_ != 0 || partialIncrement_ != 0.0; }

    /**
     Increment the index to the next location. Properly handles looping and buffer end.

     @param bounds current boundaries and loop point for the sample being indexed
     @param canLoop true if looping is allowed
     */
    void increment(const Bounds& bounds, bool canLoop) {
        if (finished()) return;

        if (indexIncrement_) index_ += indexIncrement_;
        partial_ += partialIncrement_;

        if (partial_ >= 1.0) {
            auto carry = size_t(partial_);
            index_ += carry;
            partial_ -= carry;
        }

        if (canLoop && index_ >= bounds.endLoopIndex()) {
            log_.debug() << "looping" << std::endl;
            index_ -= (bounds.endLoopIndex() - bounds.startLoopIndex());
        }
        else if (index_ >= bounds.endIndex()) {
            log_.debug() << "stopping" << std::endl;
            partialIncrement_ = -1.0;
        }
    }

    /// @returns index to first sample to use for rendering
    size_t index() const { return index_; }

    /// @returns normalized position between 2 samples. For instance, 0.5 indicates half-way between two samples.
    double partial() const { return partial_; }

    /// @returns true if the index is no longer moving
    bool finished() const { return partialIncrement_ < 0.0; }

private:
    size_t index_;
    size_t indexIncrement_{0};
    double partial_{0.0};
    double partialIncrement_{0.0};
    inline static Logger log_{Logger::Make("Render.Sample", "BufferIndex")};
};

} // namespace Sf2::Render::Sample

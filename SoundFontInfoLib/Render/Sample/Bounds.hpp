// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Generator/Index.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/Voice/State.hpp"

namespace SF2 {
namespace Render {
namespace Sample {

/**
 Represents the sample index bounds and loop start/end indices using values from the SF2 'shdr' entity as well as
 state values from generators that can change in real-time. Note that unlike the "absolute" values in the 'shdr' and
 the state offsets which are all based on the entire sample block of the file, these values are offsets from the first
 sample value from the 'shdr'.
 */
struct Bounds {
    using Index = Entity::Generator::Index;

    Bounds(const Entity::SampleHeader& header, const Voice::State& state) {
        constexpr size_t coarse = 1 << 15;

        size_t startOffset = state[Index::startAddressOffset] + state[Index::startAddressCoarseOffset] * coarse;
        size_t startLoopOffset = state[Index::startLoopAddressOffset] + state[Index::startLoopAddressCoarseOffset] * coarse;
        size_t endLoopOffset = state[Index::endLoopAddressOffset] + state[Index::endLoopAddressCoarseOffset] * coarse;
        size_t endOffset = state[Index::endAddressOffset] + state[Index::endAddressCoarseOffset] * coarse;

        size_t shift = header.startIndex();
        startIndex_ = std::clamp<size_t>(header.startIndex() + startOffset,
                                         header.startIndex(),
                                         header.endIndex()) - shift;
        startLoopIndex_ = std::clamp<size_t>(header.startLoopIndex() + startLoopOffset,
                                             header.startIndex(),
                                             header.endIndex()) - shift;
        endLoopIndex_ = std::clamp<size_t>(header.endLoopIndex() + endLoopOffset,
                                           header.startIndex(),
                                           header.endIndex()) - shift;
        endIndex_ = std::clamp<size_t>(header.endIndex() + endOffset,
                                       header.startIndex(),
                                       header.endIndex()) - shift;
    }

    /// @returns the index of the first sample to use for rendering
    size_t startIndex() const { return startIndex_; }
    /// @returns the index of the first sample of a loop
    size_t startLoopIndex() const { return startLoopIndex_; }
    /// @returns the index of the first sample AFTER a loop
    size_t endLoopIndex() const { return endLoopIndex_; }
    /// @returns the index after the last valid sample to use for rendering
    size_t endIndex() const { return endIndex_; }

private:
    size_t startIndex_;
    size_t startLoopIndex_;
    size_t endLoopIndex_;
    size_t endIndex_;
};

} // namespace Sample
} // namespace Render
} // namespace SF2

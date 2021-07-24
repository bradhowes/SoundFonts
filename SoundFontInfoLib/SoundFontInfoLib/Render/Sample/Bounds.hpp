// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Generator/Index.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/Voice/State.hpp"

/**
 Classes used to generate new samples from SF2 sample data for a given pitch and sample rate.
 */
namespace SF2::Render::Sample {

/**
 Represents the sample index bounds and loop start/end indices using values from the SF2 'shdr' entity as well as
 state values from generators that can change in real-time. Note that unlike the "absolute" values in the 'shdr' and
 the state offsets which are all based on the entire sample block of the file, these values are offsets from the first
 sample value from the 'shdr'
 */
struct Bounds {
  using Index = Entity::Generator::Index;

  /**
   Construct new instance using information from 'shdr' and current voice state values from generators related to
   sample indices.

   @param header the 'shdr' header to use
   @param state the generator values to use
   */
  Bounds(const Entity::SampleHeader& header, const Voice::State& state) {
    constexpr size_t coarse = 1 << 15;
    auto offset = [&](Index a, Index b) -> size_t { return state.unmodulated(a) + state.unmodulated(b) * coarse; };

    // Calculate offsets for the samples using state generator values set by preset/instrument zones.
    auto startOffset = offset(Index::startAddressOffset, Index::startAddressCoarseOffset);
    auto startLoopOffset = offset(Index::startLoopAddressOffset, Index::startLoopAddressCoarseOffset);
    auto endLoopOffset = offset(Index::endLoopAddressOffset, Index::endLoopAddressCoarseOffset);
    auto endOffset = offset(Index::endAddressOffset, Index::endAddressCoarseOffset);

    auto lower = header.startIndex();
    auto upper = header.endIndex();
    auto clampPos = [&](size_t v) -> size_t { return std::clamp<size_t>(v, lower, upper) - lower; };

    // Calculate sample indices from the above.
    startPos_ = clampPos(header.startIndex() + startOffset);
    startLoopPos_ = clampPos(header.startLoopIndex() + startLoopOffset);
    endLoopPos_ = clampPos(header.endLoopIndex() + endLoopOffset);
    endPos_ = clampPos(header.endIndex() + endOffset);
  }

  /// @returns the index of the first sample to use for rendering
  size_t startPos() const { return startPos_; }
  /// @returns the index of the first sample of a loop
  size_t startLoopPos() const { return startLoopPos_; }
  /// @returns the index of the first sample AFTER a loop
  size_t endLoopPos() const { return endLoopPos_; }
  /// @returns the index after the last valid sample to use for rendering
  size_t endPos() const { return endPos_; }

private:
  size_t startPos_;
  size_t startLoopPos_;
  size_t endLoopPos_;
  size_t endPos_;
};

} // namespace SF2::Render::Sample

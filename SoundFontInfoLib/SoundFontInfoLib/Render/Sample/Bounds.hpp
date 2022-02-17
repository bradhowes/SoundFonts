// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Generator/Index.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/State.hpp"

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
class Bounds {
public:
    
  using Index = Entity::Generator::Index;

  /**
   Construct Bounds using information from 'shdr' and current voice state values from generators related to
   sample indices.

   @param header the 'shdr' header to use
   @param state the generator values to use
   */
  static Bounds make(const Entity::SampleHeader& header, const State& state) {
    constexpr size_t coarse = 1 << 15;
    auto offset = [&state, coarse](Index a, Index b) -> size_t {
      return size_t(state.unmodulated(a)) + size_t(state.unmodulated(b)) * coarse;
    };

    // Calculate offsets for the samples using state generator values set by preset/instrument zones.
    auto startOffset = offset(Index::startAddressOffset, Index::startAddressCoarseOffset);
    auto startLoopOffset = offset(Index::startLoopAddressOffset, Index::startLoopAddressCoarseOffset);
    auto endLoopOffset = offset(Index::endLoopAddressOffset, Index::endLoopAddressCoarseOffset);
    auto endOffset = offset(Index::endAddressOffset, Index::endAddressCoarseOffset);

    // Don't trust values above. Clamp them to valid ranges before using.
    auto lower = header.startIndex();
    auto upper = header.endIndex();
    auto clampPos = [lower, upper](size_t v) -> size_t { return std::clamp<size_t>(v, lower, upper) - lower; };

    return Bounds(clampPos(lower + startOffset),
                  clampPos(header.startLoopIndex() + startLoopOffset),
                  clampPos(header.endLoopIndex() + endLoopOffset),
                  clampPos(upper + endOffset));
  }

  Bounds() {}

  Bounds(size_t startPos, size_t startLoopPos, size_t endLoopPos, size_t endPos) :
  startPos_{startPos}, startLoopPos_{startLoopPos}, endLoopPos_{endLoopPos}, endPos_{endPos} {}

  /// @returns the index of the first sample to use for rendering
  size_t startPos() const { return startPos_; }
  /// @returns the index of the first sample of a loop
  size_t startLoopPos() const { return startLoopPos_; }
  /// @returns the index of the first sample AFTER a loop
  size_t endLoopPos() const { return endLoopPos_; }
  /// @returns the index after the last valid sample to use for rendering
  size_t endPos() const { return endPos_; }

private:
  size_t startPos_{0};
  size_t startLoopPos_{0};
  size_t endLoopPos_{0};
  size_t endPos_{0};
};

} // namespace SF2::Render::Sample

// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <iostream>

#include "DSP/DSP.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/LFO.hpp"
#include "Render/State.hpp"

namespace SF2::Render {

/**
 View of a State that pertains to pitch. Pitch is based on the MIDI key that triggered the note, several
 generator values that are set by instrument and preset zones, and values found in the sample header that
 spells out how the samples were originally recorded.

 - State::key() -- the MIDI key *or* the value from the `forcedMIDIKey` generator.
 - SampleHeader::originalMIDIKey -- the note of the original samples
 - SampleHeader::pitchCorrection -- adjustment to apply to have the samples really play at originalMIDIKey
 frequency
 - SampleHeader::sampleRate -- the sample rate used when recording the samples
 - State::sampleRate -- the sample rate in effect when rendering new samples
 - `overridingRootKey` -- generator that overrides `originalMIDIKey` in sample header
 - `scaleTuning` -- generator that sets the number of cents that increase as key numbers increase
 - `coarseTune` -- modulated generator that changes pitch in semitones
 - `fineTune` -- modulated generator that changes pitch in cents

 All but the last two items are fixed when Pitch instance is created. If/when those two items change due to
 modulation, one must call `Pitch::updatePitchOffset` to have them affect future frequency calculations.

 The routine `Pitch::samplePhaseIncrement` generates the appropriate increment to use when rendering audio
 samples from the original ones. If the target frequency is the same as the root one, then the increment would
 be 1.0. If the event key is an octave higher than the original root key, the increment would be 2.0 since we
 need to move past 2x the same number of samples to get 2x cycles in the same amount of time.

 This routine takes into account current modulation and vibrato LFO values as well as the current modulation
 envelope. These all can affect the pitch that is used in the increment calculations depending on the state
 generators `modulatorLFOToPitch`, `vibratoLFOToPitch` and `modulatorEnvelopeToPitch`.
 */
class Pitch
{
public:

  Pitch(const State& state) :
  state_{state}, key_{state.key()} {}

  void configure(const Entity::SampleHeader& header)
  {
    key_ = state_.key();
    initialize(header.originalMIDIKey(), header.pitchCorrection(), header.sampleRate());
  }

  /**
   Calculate the sample increment to use when rendering. If the target frequency is the same as the root frequency, then
   this would be 1. For a target frequency that is twice the root frequency, then this would be 2.0 since we need to
   move past 2x the same number of samples to get twice the cycle frequency.

   @param modLFO the current modulation LFO value
   @param vibLFO the current vibrato LFO value
   @param modEnv the current modulation envelope value
   */
  Float samplePhaseIncrement(Float modLFO, Float vibLFO, Float modEnv) const {
    auto value = DSP::centsToFrequency(pitch_ + pitchOffset_ +
                                       modLFO * centFs(State::Index::modulatorLFOToPitch) +
                                       vibLFO * centFs(State::Index::vibratoLFOToPitch) +
                                       modEnv * centFs(State::Index::modulatorEnvelopeToPitch)) / rootFrequency_;
    // std::cout << "phaseIncrement: " << value << '\n';
    return value;
  }

  /**
   Recalculate pitch offset using state generators `coarseTune` and `fineTune`.
   */
  void updatePitchOffset() {
    pitchOffset_ = std::clamp(state_.modulated(State::Index::coarseTune), -120.0, 120.0) * 100.0 +
    std::clamp(state_.modulated(State::Index::fineTune), -99.0, 99.0);
    std::cout << "pitchOffset: " << pitchOffset_ << '\n';
  }

private:

  Float centFs(State::Index index) const { return std::clamp(state_.modulated(index), -12000.0, 12000.0); }

  int rootKey(int originalMIDIKey) const {
    auto value = std::clamp(state_.unmodulated(State::Index::overridingRootKey), -1, 127);
    if (value == -1) value = originalMIDIKey;
    return value;
  }

  int scaleTuning() const { return std::clamp(state_.unmodulated(State::Index::scaleTuning), 0, 1200); }

  void initialize(int originalMIDIKey, int pitchCorrection, Float originalSampleRate) {
    auto rootKey = this->rootKey(originalMIDIKey);
    auto rootPitch = rootKey * 100.0 - pitchCorrection;
    rootFrequency_ = DSP::centsToFrequency(rootPitch) * state_.sampleRate() / originalSampleRate;
    std::cout << "rootPitch: " << rootPitch << " rootFrequency: " << rootFrequency_ << '\n';
    pitch_ = scaleTuning() * (key_ - rootPitch / 100.0) + rootPitch;
    std::cout << "pitch: " << pitch_ << '\n';
    updatePitchOffset();
  }

  const State& state_;
  int key_;
  Float pitch_;
  Float pitchOffset_{0.0};
  Float rootFrequency_;
};

} // namespace SF2::Render

// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <vector>

#include "Logger.hpp"

#include "Render/Envelope/Generator.hpp"
#include "Render/LFO.hpp"
#include "Render/Voice/Sample/Generator.hpp"
#include "Render/Voice/State/Modulator.hpp"
#include "Render/Voice/State/State.hpp"

namespace SF2::MIDI { class Channel; }

/**
 Collection of types involved in generating audio samples for note that is being played. For a polyphonic instrument,
 there can be more than one voice playing at the same time.
 */
namespace SF2::Render::Voice {

/**
 A voice renders audio samples for a given note / pitch.
 */
class Voice
{
public:
  using Index = Entity::Generator::Index;

  /**
   These are values for the sampleModes (#54) generator.

   - none -- rendering does not loop
   - activeEnvelope -- loop as long as the envelope allows
   - duringKeyPress -- loop only while they key is down
   */
  enum LoopingMode {
    none = 0,
    activeEnvelope = 1,
    duringKeyPress = 3
  };

  enum AudioDestinationChannel {
    both = 0,
    left = 1,
    right = 2
  };

  /**
   Construct a new voice renderer.

   @param sampleRate the sample rate to use for generating audio
   @param channel the MIDI state associated with the renderer
   */
  Voice(Float sampleRate, const MIDI::Channel& channel, size_t voiceIndex);

  void setSampleRate(Float sampleRate) { state_.setSampleRate(sampleRate); }

  size_t voiceIndex() const { return voiceIndex_; }

  /**
   Configure the voice for rendering.

   @param config the voice configuration to apply
   */
  void configure(const State::Config& config);

  int key() const { return state_.eventKey(); }

  bool isKeyDown() const { return gainEnvelope_.isGated(); }

  /**
   Signal the envelopes that the key is no longer pressed, transitioning to release phase.
   */
  void releaseKey() {
    gainEnvelope_.gate(false);
    modulatorEnvelope_.gate(false);
  }

  /// @returns true if this voice is still rendering interesting samples
  bool isActive() const { return !isDone(); }

  /// @returns true if this voice is done processing and will no longer render meaningful samples.
  bool isDone() const {
    if (!done_) done_ = (!gainEnvelope_.isActive() || !sampleGenerator_.isActive());
    return done_;
  }

  /// @returns looping mode of the sample being rendered
  LoopingMode loopingMode() const {
    switch (state_.unmodulated(Index::sampleModes)) {
      case 1: return LoopingMode::activeEnvelope;
      case 3: return LoopingMode::duringKeyPress;
      default: return LoopingMode::none;
    }
  }

  /// @returns true if the voice can enter a loop if it is available
  bool canLoop() const {
    return (loopingMode_ == activeEnvelope && gainEnvelope_.isActive()) ||
    (loopingMode_ == duringKeyPress && gainEnvelope_.isGated());
  }

  /**
   Renders the next sample for a voice. Inactive voices always return 0.0.

   Here are the modulation connections, taken from the SoundFont spec v2.

            Osc ------ Filter -- Amp -- L+R ----+-------------+-+-> Output
             | pitch     | Fc     | Volume      |            / /
            /|          /|        |             +- Reverb --+ /
   Mod Env +-----------+ |        |             |            /
            /|           |        |             +- Chorus --+
   Vib LFO + |           |        |
            /           /        /|
   Mod LFO +-----------+--------+ |
                                 /
   Vol Env ---------------------+

   @returns next sample
   */
  Float renderSample() {
    if (isDone()) { return 0.0; }

    auto modLFO = modulatorLFO_.getNextValue();
    auto vibLFO = vibratoLFO_.getNextValue();
    auto modEnv = modulatorEnvelope_.getNextValue();
    auto volEnv = gainEnvelope_.getNextValue();

    // According to FluidSynth this is the right think to do.
    if (gainEnvelope_.isDelayed()) return 0.0;

    auto gain = calculateGain(modLFO, volEnv);
    auto increment = pitch_.samplePhaseIncrement(modLFO, vibLFO, modEnv);
    auto sample = sampleGenerator_.generate(increment, canLoop());

    return sample * gain;
  }

  Float calculateGain(Float modLFO, Float volEnv)
  {
    // This formula follows what FluidSynth is doing for attenuation/gain.
    auto gain = (DSP::centibelsToAttenuation(state_.modulated(Index::initialAttenuation)) *
                 DSP::centibelsToAttenuation(DSP::MaximumAttenuation * (1.0 - volEnv) +
                                             modLFO * -state_.modulated(Index::modulatorLFOToVolume)));

    // When in the release stage, look for a magical point at which one can no longer hear the sample being generated.
    // Use that as a short-circuit to flagging the voice as done.
    if (gainEnvelope_.stage() == Envelope::StageIndex::release) {
      auto minGain = sampleGenerator_.looped() ? noiseFloorOverMagnitudeOfLoop_ : noiseFloorOverMagnitude_;
      if (gain < minGain) {
        done_ = true;
      }
    }
    return gain;
  }

  void renderIntoByAdding(float* left, float* right, size_t frameCount) {
    Float leftAmp;
    Float rightAmp;

    Float pan = state_.modulated(Index::pan);
    DSP::panLookup(pan, leftAmp, rightAmp);

    for (size_t index = 0; index < frameCount; ++index) {
      if (isDone()) {
        break;
      }

      auto sample = renderSample();
      float leftSample = float(sample * leftAmp);
      float rightSample = float(sample * rightAmp);
      *left++ += leftSample;
      *right++ += rightSample;
    }
  }

  State::State& state() { return state_; }

private:
  State::State state_;
  LoopingMode loopingMode_;
  Sample::Pitch pitch_;
  Sample::Generator sampleGenerator_;
  Envelope::Generator gainEnvelope_;
  Envelope::Generator modulatorEnvelope_;
  LFO modulatorLFO_;
  LFO vibratoLFO_;
  size_t voiceIndex_;
  AudioDestinationChannel audioDestinationChannel_;
  Float noiseFloorOverMagnitude_;
  Float noiseFloorOverMagnitudeOfLoop_;

  mutable bool done_{false};

  inline static Logger log_{Logger::Make("Render", "Voice")};
};

} // namespace SF2::Render::Voice

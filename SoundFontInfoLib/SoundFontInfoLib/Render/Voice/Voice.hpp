// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Logger.hpp"
#include "Render/Engine/Tick.hpp"
#include "Render/Envelope/Generator.hpp"
#include "Render/LFO.hpp"
#include "Render/Modulator.hpp"
#include "Render/Sample/Generator.hpp"
#include "Render/State.hpp"

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
   Construct a new voice renderer.

   @param sampleRate the sample rate to use for generating audio
   @param channel the MIDI state associated with the renderer
   */
  Voice(Float sampleRate, const MIDI::Channel& channel, size_t voiceIndex);

  size_t voiceIndex() const { return voiceIndex_; }
  Engine::Tick startedTick() const { return startedTick_; }

  /**
   Configure the voice for rendering.

   @param config the voice configuration to apply
   @param startTick the counter when the voice started
   */
  void configure(const Config& config, Engine::Tick startTick);

  /**
   Signal the envelopes that the key is no longer pressed, transitioning to release phase.
   */
  void keyReleased() {
    gainEnvelope_.gate(false);
    modulatorEnvelope_.gate(false);
  }

  /// @returns true if this voice is still rendering interesting samples
  bool isActive() const { return gainEnvelope_.isActive(); }

  /// @returns true if the voice can enter a loop if it is available
  bool canLoop() const {
    return (loopingMode_ == State::activeEnvelope && gainEnvelope_.isActive()) ||
    (loopingMode_ == State::duringKeyPress && gainEnvelope_.isGated());
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
  Float render() {
    if (!isActive()) return 0.0;

    // auto scaleTuning = state_.modulated(Index::scaleTuning);

    auto modEnv = modulatorEnvelope_.getNextValue();
    auto vibLfo = vibratoLFO_.getNextValue();
    auto modLfo = modulatorLFO_.getNextValue();
    auto volEnv = gainEnvelope_.getNextValue();

    // The primary pitch value (note that this can be modulated / adjusted as well depending on mod definitions)
    auto pitch = state_.pitch();

    // The adjustments that come from the modulators and envelopes. These are specified in cents so, divide by 100 to
    // get values in semitones.
    auto pitchAdjustment = (modEnv * state_.modulated(Index::modulatorEnvelopeToPitch) +
                            modLfo * state_.modulated(Index::modulatorLFOToPitch) +
                            vibLfo * state_.modulated(Index::vibratoLFOToPitch)) / 100.0;

    auto attenuation = 1.0; // state_.modulated(Index::initialAttenuation);

    auto sample = sampleGenerator_.generate(pitch + pitchAdjustment, canLoop());
    return sample * volEnv;
    
    return sample * modLfo * state_.modulated(Index::modulatorLFOToVolume) * volEnv * attenuation;
  }

private:
  State state_;
  State::LoopingMode loopingMode_;
  Sample::Generator sampleGenerator_;
  Envelope::Generator gainEnvelope_;
  Envelope::Generator modulatorEnvelope_;
  LFO modulatorLFO_;
  LFO vibratoLFO_;

  size_t voiceIndex_;
  Engine::Tick startedTick_;

  inline static Logger log_{Logger::Make("Render", "Voice")};
};

} // namespace SF2::Render::Voice

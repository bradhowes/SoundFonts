// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Logger.hpp"
#include "Render/Envelope/Generator.hpp"
#include "Render/LFO.hpp"
#include "Render/Modulator.hpp"
#include "Render/Sample/CanonicalBuffer.hpp"
#include "Render/Sample/Generator.hpp"
#include "Render/Voice/State.hpp"

namespace SF2::MIDI { class Channel; }

/**
 Collection of types involved in generating audio samples for note that is being played. For a polyphonic instrument,
 there can be more than one voice playing at the same time.
 */
namespace SF2::Render::Voice {

class Config;

/**
 A voice renders audio samples for a given note / pitch.
 */
class Voice
{
public:

  /**
   Construct a new voice renderer.

   @param sampleRate the sample rate to use for generating audio
   @param channel the MIDI state associated with the renderer
   @param config the zones to apply to build the generator values used for rendering
   */
  Voice(double sampleRate, const MIDI::Channel& channel, const Config& config);

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

   @returns next sample
   */
  double render() {
    if (!isActive()) return 0.0;

    auto amplitudeGain = gainEnvelope_.process();
    auto modulatorGain = modulatorEnvelope_.process();

    auto lfoValue = modulatorLFO_.valueAndIncrement();
    auto vibratoValue = vibratoLFO_.valueAndIncrement();

    auto pitchAdjustment = (modulatorGain * state_.modulated(Entity::Generator::Index::modulatorEnvelopeToPitch) +
                            lfoValue * state_.modulated(Entity::Generator::Index::modulatorLFOToPitch) +
                            vibratoValue * state_.modulated(Entity::Generator::Index::vibratoLFOToPitch));

    return sampleGenerator_.generate(pitchAdjustment, canLoop()) * amplitudeGain;
  }

private:
  State state_;
  State::LoopingMode loopingMode_;
  Sample::TGenerator<Sample::InterpolatedGenerator> sampleGenerator_;
  Envelope::Generator gainEnvelope_;
  Envelope::Generator modulatorEnvelope_;
  LFO modulatorLFO_;
  LFO vibratoLFO_;

  inline static Logger log_{Logger::Make("Render", "Voice")};
};

} // namespace SF2::Render::Voice

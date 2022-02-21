// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <cmath>
#include <limits>
#include <utility>

#include "Logger.hpp"
#include "Entity/Generator/Index.hpp"
#include "Render/Envelope/Stage.hpp"
#include "Render/State.hpp"

/**
 Representation of an envelope with various states that have timing characteristics and levels.
 */
namespace SF2::Render::Envelope {

/**
 Collection of states for all of the stages in an envelope.
 */
using Stages = std::array<Stage, static_cast<int>(StageIndex::release) + 1>;

/**
 Generator of values for the SF2 volume/filter envelopes. An envelope contains 6 stages:

 - Delay -- number of seconds to delay the beginning of the attack stage
 - Attack -- number of seconds to ramp up from 0.0 to 1.0. Also supports non-linear curvature.
 - Hold -- number of seconds to hold the envelope at 1.0 before entering the decay stage.
 - Decay -- number of seconds to lower the envelope from 1.0 to the sustain level
 - Sustain -- a stage that lasts as long as a note is held down
 - Release -- number of seconds to go from sustain level to 0.0

 The envelope will remain in the idle state until `gate(true)` is invoked. It will remain in the sustain stage until
 `gate(false)` is invoked at which point it will enter the `release` stage. Although the stages above are listed in the
 order in which they are performed, any stage will transition to the `release` stage upon a `gate(false)`
 call.

 The more traditional ADSR (attack, decay, sustain, release) envelope can be achieve by setting the delay and hold
 durations to zero (0.0).
 */
class Generator {
public:
  using Index = Entity::Generator::Index;
  using State = Render::State;

  inline static constexpr Float defaultCurvature = 0.01;

  Generator() = default;

  Generator(Generator&& rhs) noexcept
  : stages_{std::move(rhs.stages_)}, stageIndex_{rhs.stageIndex_}, counter_{rhs.counter_}, value_{rhs.value_}
  {
    os_log_info(log_, "Generator MOVE constructor");
  }

  Generator& operator=(Generator&& rhs) {
    os_log_info(log_, "Generator MOVE assignment");
    stages_ = std::move(rhs.stages_);
    stageIndex_ = rhs.stageIndex_;
    counter_ = rhs.counter_;
    value_ = rhs.value_;
    return *this;
  }

  /**
   Create new envelope for volume changes over time.

   @param state the state holding the generator values for the envelope definition
   */
  static Generator forVol(const State& state) {
    return Generator(state.sampleRate(),
                     DSP::centsToSeconds(state.modulated(Index::delayVolumeEnvelope)),
                     DSP::centsToSeconds(state.modulated(Index::attackVolumeEnvelope)),
                     DSP::centsToSeconds(state.modulated(Index::holdVolumeEnvelope) +
                                         state.keyedVolumeEnvelopeHold()),
                     DSP::centsToSeconds(state.modulated(Index::decayVolumeEnvelope) +
                                         state.keyedVolumeEnvelopeDecay()),
                     state.sustainLevelVolumeEnvelope(),
                     DSP::centsToSeconds(state.modulated(Index::releaseVolumeEnvelope)),
                     true);
  }

  /**
   Create new envelope for modulation changes over time.

   @param state the state holding the generator values for the envelope definition
   */
  static Generator forMod(const State& state) {
    return Generator(state.sampleRate(),
                     DSP::centsToSeconds(state.modulated(Index::delayModulatorEnvelope)),
                     DSP::centsToSeconds(state.modulated(Index::attackModulatorEnvelope)),
                     DSP::centsToSeconds(state.modulated(Index::holdModulatorEnvelope) +
                                         state.keyedModulatorEnvelopeHold()),
                     DSP::centsToSeconds(state.modulated(Index::decayModulatorEnvelope) +
                                         state.keyedModulatorEnvelopeDecay()),
                     state.sustainLevelModulatorEnvelope(),
                     DSP::centsToSeconds(state.modulated(Index::releaseModulatorEnvelope)),
                     true);
  }

  /**
   Set the status of a note playing. When true, the envelope begins proper. When set to false, the envelope will
   jump to the release stage.
   */
  void gate(bool noteOn) {
    if (noteOn) {
      value_ = 0.0;
      enterStage(StageIndex::delay);
    }
    else if (stageIndex_ != StageIndex::idle) {
      enterStage(StageIndex::release);
    }
  }

  /// @returns the currently active stage.
  StageIndex stage() const { return stageIndex_; }

  /// @returns true if the generator still has values to emit
  bool isActive() const { return stageIndex_ != StageIndex::idle; }

  /// @returns true if the generator is active and has not yet reached the release state
  bool isGated() const { return isActive() && stageIndex_ != StageIndex::release; }

  /// @returns the current envelope value.
  Float value() const { return value_; }

  /**
   Calculate the next envelope value. This must be called on every sample for proper timing of the stages.

   @returns the new envelope value.
   */
  Float getNextValue() {
    switch (stageIndex_) {
      case StageIndex::delay: checkIfEndStage(StageIndex::attack); break;
      case StageIndex::attack: updateValue(); checkIfEndStage(StageIndex::hold); break;
      case StageIndex::hold: checkIfEndStage(StageIndex::decay); break;
      case StageIndex::decay: updateAndCompare(sustainLevel(), StageIndex::sustain); break;
      case StageIndex::release: updateAndCompare(0.0, StageIndex::idle); break;
      default: break;
    }

    return value_;
  }

private:

  Generator(Float sampleRate, Float delay, Float attack, Float hold, Float decay, Float sustain, Float release,
            bool noteOn = false) : stages_{
    Stage::Delay(samplesFor(sampleRate, delay)),
    Stage::Attack(samplesFor(sampleRate, attack), defaultCurvature),
    Stage::Hold(samplesFor(sampleRate, hold)),
    Stage::Decay(samplesFor(sampleRate, decay), defaultCurvature, sustain),
    Stage::Sustain(sustain),
    Stage::Release(samplesFor(sampleRate, release), defaultCurvature, sustain)
  }
  {
    os_log_info(log_, "Generator constructor");
    if (noteOn) gate(true);
  }

  static int samplesFor(Float sampleRate, Float duration) { return int(round(sampleRate * duration)); }

  void updateAndCompare(Float floor, StageIndex next) {
    updateValue();
    if (value_ < floor)
      enterStage(next);
    else
      checkIfEndStage(next);
  }

  const Stage& active() const { return stage(stageIndex_); }

  const Stage& stage(StageIndex stageIndex) const { return stages_[static_cast<size_t>(stageIndex)]; }

  Float sustainLevel() const { return stage(StageIndex::sustain).initial_; }

  void updateValue() { value_ = active().next(value_); }

  void checkIfEndStage(StageIndex next) {
    if (--counter_ == 0) {
      log_.info() << "end stage: " << StageName(stageIndex_) << std::endl;
      enterStage(next);
    }
  }

  int activeDurationInSamples() const { return active().durationInSamples_; }

  void enterStage(StageIndex next) {
    log_.info() << "new stage: " << StageName(next) << std::endl;
    stageIndex_ = next;
    switch (stageIndex_) {
      case StageIndex::delay:
        if (activeDurationInSamples()) break;
        os_log_info(log_, "next stage: attack");
        stageIndex_ = StageIndex::attack;

      case StageIndex::attack:
        if (activeDurationInSamples()) break;
        os_log_info(log_, "next stage: hold");
        stageIndex_ = StageIndex::hold;

      case StageIndex::hold:
        value_ = 1.0;
        if (activeDurationInSamples()) break;
        os_log_info(log_, "next stage: decay");
        stageIndex_ = StageIndex::decay;

      case StageIndex::decay:
        if (activeDurationInSamples()) break;
        os_log_info(log_, "next stage: sustain");
        stageIndex_ = StageIndex::sustain;

      case StageIndex::sustain:
        value_ = active().initial_;
        break;

      case StageIndex::release:
        if (activeDurationInSamples()) break;
        os_log_info(log_, "next stage: idle");
        stageIndex_ = StageIndex::idle;
        value_ = 0.0;

      case StageIndex::idle: return;
    }

    counter_ = activeDurationInSamples();
  }

  Stages stages_{};
  StageIndex stageIndex_{StageIndex::idle};
  int counter_{0};
  Float value_{0.0};

  friend class EnvelopeTestInjector;
  
  inline static Logger log_{Logger::Make("Render.Envelope", "Generator")};
};

} // namespace SF2::Render::Envelope

// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "Render/Config.hpp"
#include "Render/State.hpp"

using namespace SF2::Render;

void
State::prepareForVoice(const Config& config)
{
  eventKey_ = config.eventKey();
  eventVelocity_ = config.eventVelocity();

  const auto& header{config.sampleSource().header()};
  sampleSampleRate_ = header.sampleRate();
  sampleOriginalMIDIKey_ = header.originalMIDIKey();
  samplePitchCorrection_ = header.pitchCorrection();

  // (1) Initialize to default values
  setDefaults();

  // (2) Set values from preset and instrument zone configurations that matched the MIDI key/velocity combination.
  config.apply(*this);

  // (3) Now finish configuring the modulators by resolving any links between them.
  for (const auto& modulator : modulators_) {
    if (!modulator.configuration().hasModulatorDestination()) continue;
    for (auto& destination : modulators_) {
      if (destination.configuration().source().isLinked() &&
          modulator.configuration().linkDestination() == destination.index()) {

        // Set up the destination modulator so that it pulls a value from another modulator when it is asked for a value
        // to apply to a generator.
        destination.setSource(modulator);
      }
    }
  }
}

void
State::setDefaults() {
  gens_.zero();
  setValue(Index::initialFilterCutoff, 13500);
  setValue(Index::delayModulatorLFO, -12000);
  setValue(Index::delayVibratoLFO, -12000);
  setValue(Index::delayModulatorEnvelope, -12000);
  setValue(Index::attackModulatorEnvelope, -12000);
  setValue(Index::holdModulatorEnvelope, -12000);
  setValue(Index::decayModulatorEnvelope, -12000);
  setValue(Index::releaseModulatorEnvelope, -12000);
  setValue(Index::delayVolumeEnvelope, -12000);
  setValue(Index::attackVolumeEnvelope, -12000);
  setValue(Index::holdVolumeEnvelope, -12000);
  setValue(Index::decayVolumeEnvelope, -12000);
  setValue(Index::releaseVolumeEnvelope, -12000);
  setValue(Index::forcedMIDIKey, -1);
  setValue(Index::forcedMIDIVelocity, -1);
  setValue(Index::scaleTuning, 100);
  setValue(Index::overridingRootKey, -1);

  // Install default modulators for the voice. Zones can override them and add new ones.
  for (const auto& modulator : Entity::Modulator::Modulator::defaults) {
    addModulator(modulator);
  }
}

void
State::addModulator(const Entity::Modulator::Modulator& modulator) {

  // Per spec, there must only be one modulator with specific (sfModSrcOper, sfModDestOper, and sfModSrcAmtOper)
  // values. If we find a duplicate, flag it as not being used, but keep it around so that modulator linking is not
  // broken if it is used.
  for (auto& mod : modulators_) {
    if (mod.configuration() == modulator) {
      mod.flagInvalid();
      break;
    }
  }

  size_t index = modulators_.size();
  modulators_.emplace_back(index, modulator, *this);

  if (modulator.hasGeneratorDestination()) {
    gens_[modulator.generatorDestination()].mods.push_front(index);
  }
}

void
State::generatorChanged(Index index)
{
  auto value = modulated(index);
  switch (index) {
    case Index::pan:
      DSP::panLookup(value, leftAttenuation_, rightAttenuation_);
      break;

    case Index::initialAttenuation:
      attenuation_ = DSP::clamp(value, 0.0f, 1440.0f);
      break;

    case Index::initialPitch:
    case Index::coarseTune:
    case Index::fineTune:
      pitch_ = modulated(Index::initialPitch) + 100.0f * modulated(Index::coarseTune) + modulated(Index::fineTune);
      break;

    case Index::reverbEffectSend:
      reverbAmount_ = DSP::clamp(value / 1000.0f, 0.0f, 1.0f);
      break;

    case Index::chorusEffectSend:
      chorusAmount_ = DSP::clamp(value / 1000.0f, 0.0f, 1.0f);
      break;

    case Index::overridingRootKey:
      if (unmodulated(index) > -1)
        rootPitch_ = unmodulated(index) * 100.0f - samplePitchCorrection_;
      else
        rootPitch_ = sampleOriginalMIDIKey_ * 100.0f - samplePitchCorrection_;
      pitch_ = unmodulated(Index::scaleTuning) * (key() - rootPitch_ / 100.0f) + rootPitch_;
      break;

    case Index::initialFilterCutoff:
      filterCutoff_ = value;
      break;

    case Index::initialFilterResonance:
      filterResonance_ = value;
      break;

    default:
      break;
  }
}


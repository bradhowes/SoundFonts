// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "Render/Voice/State/Config.hpp"
#include "Render/Voice/State/State.hpp"

using namespace SF2::Render::Voice::State;

void
State::prepareForVoice(const Config& config)
{
  // (1) Initialize to default values
  setDefaults();

  // (2) Set values from preset and instrument zone configurations that matched the MIDI key/velocity combination.
  config.apply(*this);

  eventKey_ = config.eventKey();
  eventVelocity_ = config.eventVelocity();

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
    // gens_[modulator.generatorDestination()].mods.push_front(index);
  }
}


// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "Render/Envelope/Generator.hpp"

#include "Render/Config.hpp"
#include "Render/State.hpp"

using namespace SF2::Render;

void
State::configure(const Config& config)
{
  key_ = config.key();
  velocity_ = config.velocity();

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
  gens_.fill(GenValue());
  setPrincipleValue(Index::initialFilterCutoff, 13500);
  setPrincipleValue(Index::delayModulatorLFO, -12000);
  setPrincipleValue(Index::delayVibratoLFO, -12000);
  setPrincipleValue(Index::delayModulatorEnvelope, -12000);
  setPrincipleValue(Index::attackModulatorEnvelope, -12000);
  setPrincipleValue(Index::holdModulatorEnvelope, -12000);
  setPrincipleValue(Index::decayModulatorEnvelope, -12000);
  setPrincipleValue(Index::releaseModulatorEnvelope, -12000);
  setPrincipleValue(Index::delayVolumeEnvelope, -12000);
  setPrincipleValue(Index::attackVolumeEnvelope, -12000);
  setPrincipleValue(Index::holdVolumeEnvelope, -12000);
  setPrincipleValue(Index::decayVolumeEnvelope, -12000);
  setPrincipleValue(Index::releaseVolumeEnvelope, -12000);
  setPrincipleValue(Index::forcedMIDIKey, -1);
  setPrincipleValue(Index::forcedMIDIVelocity, -1);
  setPrincipleValue(Index::scaleTuning, 100);
  setPrincipleValue(Index::overridingRootKey, -1);

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
  for (auto pos = modulators_.begin(); pos < modulators_.end(); ++pos) {
    if (pos->configuration() == modulator) {
      pos->flagInvalid();
      break;
    }
  }

  size_t index = modulators_.size();
  modulators_.emplace_back(index, modulator, *this);

  if (modulator.hasGeneratorDestination()) {
    gens_[indexValue(modulator.generatorDestination())].mods.push_front(index);
  }
}

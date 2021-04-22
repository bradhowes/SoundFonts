// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "Render/Envelope/Generator.hpp"

#include "Render/Voice/Setup.hpp"
#include "Render/Voice/State.hpp"

using namespace SF2::Render::Voice;

State::State(double sampleRate, const MIDI::Channel& channel, const Setup& setup) :
values_{}, sampleRate_{sampleRate}, channel_{channel}, key_{setup.key()}, velocity_{setup.velocity()}
{
    values_.fill(0.0);

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

    // Set values from preset and instrument zone configurations that matched the MIDI key/velocity combination.
    setup.apply(*this);

    // Now finish configuring the modulators by resolving any links between them.
    for (const auto& modulator : modulators_) {
        if (modulator.configuration().hasModulatorDestination()) {
            for (auto& destination : modulators_) {
                if (destination.configuration().source().isLinked() &&
                    modulator.configuration().linkDestination() == destination.index()) {
                    destination.setSource(modulator);
                }
            }
        }
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

    modulators_.emplace_back(modulators_.size(), modulator, *this);
    const auto& mod{modulators_.back()};
    if (modulator.hasGeneratorDestination()) {
        valueModulators_[Entity::Generator::indexValue(modulator.generatorDestination())].push_front(mod);
    }
}

// Copyright © 2020 Brad Howes. All rights reserved.

#include <limits>

#include "PresetZone.hpp"

using namespace SF2::Render;

PresetZone::PresetZone(const IO::File& file, const Entity::Bag& bag, const Render::InstrumentCollection& instruments)
: Zone(file.presetZoneGenerators().slice(bag.firstGeneratorIndex(), bag.generatorCount()),
       file.presetZoneModulators().slice(bag.firstModulatorIndex(), bag.modulatorCount()),
       Entity::Generator::Index::instrument),
instrument_{isGlobal() ? nullptr : &instruments.at(resourceLink())}
{}

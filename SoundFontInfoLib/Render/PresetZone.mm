// Copyright © 2020 Brad Howes. All rights reserved.

#include <limits>

#include "PresetZone.hpp"

using namespace SF2::Render;

PresetZone::PresetZone(const IO::File& file, const Render::InstrumentCollection& instruments, const Entity::Bag& bag)
: Zone(file.presetZoneGenerators().slice(bag.firstGeneratorIndex(), bag.generatorCount()),
       file.presetZoneModulators().slice(bag.firstModulatorIndex(), bag.modulatorCount()),
       Entity::Generator::Index::instrument),
instrument_{isGlobal() ? nullptr : &instruments.at(resourceLink())}
{}

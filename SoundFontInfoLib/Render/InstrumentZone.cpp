// Copyright © 2020 Brad Howes. All rights reserved.

#include "InstrumentZone.hpp"

using namespace SF2::Render;

InstrumentZone::InstrumentZone(const IO::File& file, const Entity::Bag& bag) :
Zone(file.instrumentZoneGenerators().slice(bag.firstGeneratorIndex(), bag.generatorCount()),
     file.instrumentZoneModulators().slice(bag.firstModulatorIndex(), bag.modulatorCount()),
     Entity::Generator::Index::sampleID),
sample_{isGlobal() ? nullptr : &file.samples()[resourceLink()]}, sampleDataBegin_{IO::Pos(-1, 0, 0)}
{}

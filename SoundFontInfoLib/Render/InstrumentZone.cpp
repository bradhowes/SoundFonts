// Copyright © 2020 Brad Howes. All rights reserved.

#include "InstrumentZone.hpp"

using namespace SF2::Render;

InstrumentZone::InstrumentZone(IO::File const& file, Entity::Bag const& bag) :
Zone(file.instrumentZoneGenerators().slice(bag.generatorIndex(), bag.generatorCount()),
     file.instrumentZoneModulators().slice(bag.modulatorIndex(), bag.modulatorCount()),
     Entity::GenIndex::sampleID),
sample_{isGlobal() ? nullptr : &file.samples()[resourceLink()]}, sampleDataBegin_{IO::Pos(-1, 0, 0)}
{}

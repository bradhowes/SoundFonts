// Copyright © 2020 Brad Howes. All rights reserved.

#include "InstrumentZone.hpp"

using namespace SF2;

InstrumentZone::InstrumentZone(SFFile const& file, SFBag const& bag) :
Zone(file.instrumentZoneGenerators.slice(bag.generatorIndex(), bag.generatorCount()),
     file.instrumentZoneModulators.slice(bag.modulatorIndex(), bag.modulatorCount()),
     SFGenIndex::sampleID),
sample_{isGlobal() ? nullptr : &file.samples[resourceLink()]}, sampleData_{file.sampleData}
{}

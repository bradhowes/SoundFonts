// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "IO/File.hpp"
#include "Render/Preset.hpp"

using namespace SF2::Render;

Preset::Preset(const IO::File& file, const InstrumentCollection& instruments, const Entity::Preset& config)
: Zones::WithZoneCollectionBase<Zones::Preset, Entity::Preset>(config.zoneCount(), config)
{
  for (const Entity::Bag& bag : file.presetZones().slice(config.firstZoneIndex(), config.zoneCount())) {
    zones_.add(Entity::Generator::Index::instrument,
               file.presetZoneGenerators().slice(bag.firstGeneratorIndex(), bag.generatorCount()),
               file.presetZoneModulators().slice(bag.firstModulatorIndex(), bag.modulatorCount()),
               instruments);
  }
}

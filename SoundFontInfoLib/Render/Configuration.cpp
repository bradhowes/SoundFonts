// Copyright © 2020 Brad Howes. All rights reserved.

#include "Instrument.hpp"

using namespace SF2::Render;

void Configuration::setDefaults()
{
    setAmount(Entity::GenIndex::initialFilterFc, 13500);
    setAmount(Entity::GenIndex::delayModLFO, -12000);
    setAmount(Entity::GenIndex::delayVibLFO, -12000);
    setAmount(Entity::GenIndex::delayModEnv, -12000);
    setAmount(Entity::GenIndex::attackModEnv, -12000);
    setAmount(Entity::GenIndex::holdModEnv, -12000);
    setAmount(Entity::GenIndex::decayModEnv, -12000);
    setAmount(Entity::GenIndex::releaseModEnv, -12000);
    setAmount(Entity::GenIndex::delayVolEnv, -12000);
    setAmount(Entity::GenIndex::attackVolEnv, -12000);
    setAmount(Entity::GenIndex::holdVolEnv, -12000);
    setAmount(Entity::GenIndex::decayVolEnv, -12000);
    setAmount(Entity::GenIndex::sustainVolEnv, -12000);
    setAmount(Entity::GenIndex::releaseVolEnv, -12000);
    setAmount(Entity::GenIndex::keynum, -1);
    setAmount(Entity::GenIndex::velocity, -1);
    setAmount(Entity::GenIndex::scaleTuning, 100);
    setAmount(Entity::GenIndex::overridingRootKey, -1);
}


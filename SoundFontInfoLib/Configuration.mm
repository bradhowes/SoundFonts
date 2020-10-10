// Copyright © 2020 Brad Howes. All rights reserved.

#include "Instrument.hpp"

using namespace SF2;

void Configuration::setDefaults()
{
    setAmount(SFGenIndex::initialFilterFc, 13500);
    setAmount(SFGenIndex::delayModLFO, -12000);
    setAmount(SFGenIndex::delayVibLFO, -12000);
    setAmount(SFGenIndex::delayModEnv, -12000);
    setAmount(SFGenIndex::attackModEnv, -12000);
    setAmount(SFGenIndex::holdModEnv, -12000);
    setAmount(SFGenIndex::decayModEnv, -12000);
    setAmount(SFGenIndex::releaseModEnv, -12000);
    setAmount(SFGenIndex::delayVolEnv, -12000);
    setAmount(SFGenIndex::attackVolEnv, -12000);
    setAmount(SFGenIndex::holdVolEnv, -12000);
    setAmount(SFGenIndex::decayVolEnv, -12000);
    setAmount(SFGenIndex::sustainVolEnv, -12000);
    setAmount(SFGenIndex::releaseVolEnv, -12000);
    setAmount(SFGenIndex::keynum, -1);
    setAmount(SFGenIndex::velocity, -1);
    setAmount(SFGenIndex::scaleTuning, 100);
    setAmount(SFGenIndex::overridingRootKey, -1);
}


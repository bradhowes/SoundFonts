// Copyright © 2020 Brad Howes. All rights reserved.

#ifndef SFGenerator_hpp
#define SFGenerator_hpp

#include <cstdlib>

namespace SF2 {

struct SFGenerator {
    static constexpr char const* names[] = {
        "startAddrsOffset",
        "endAddrsOffset",
        "startLoopAddrsOffset",
        "endLoopAddrsOffset",
        "startAddrsCoarseOffset",
        "modLFO2Pitch",
        "vibLFO2Pitch",
        "modEnvToPitch",
        "initialFilterFc",
        "initialFilterQ",
        "modLFO2FilterFc",
        "modEnv2FilterFc",
        "endAddrsCoarseOffset",
        "modLFO2Volume",
        "unused1",
        "chorusEffectsSend",
        "reverbEffectsSend",
        "pan",
        "unused2",
        "unused3",
        "unused4",
        "delayModLFO",
        "freqModLFO",
        "delayVibLFO",
        "freqVibLFO",
        "delayModEnv",
        "attackModEnv",
        "holdModEnv",
        "decayModEnv",
        "sustainModEnv",
        "releaseModEnv",
        "keynumMod2EnvHold",
        "keynumMod2EnvDecay",
        "delayVolEnv",
        "attackVolEnv",
        "holdVolEnv",
        "decayVolEnv",
        "sustainVolEnv",
        "releaseVolEnv",
        "keynum2VolEnvHold",
        "keynum2VolEnvDecay",
        "instrument",
        "reserved1",
        "keyRange",
        "velRange",
        "startLoopAddrsCoarseOffset",
        "keynum",
        "velocity",
        "initialAttenuation",
        "reserved2",
        "endLoopAddrsCoarseOffset",
        "coarseTune",
        "fineTume",
        "sampleID",
        "sampleMode",
        "reserved3",
        "scaleTuning",
        "exclusiveClass",
        "overridingRootKey",
        "unused5",
        "endOper"
    };

    SFGenerator() : bits_(0) {}
    SFGenerator(uint16_t bits) : bits_{bits} {}

    uint16_t value() const { return bits_; }

    char const* name() const { return names[bits_]; }

private:

    const uint16_t bits_;
};

}

#endif /* SFGenerator_hpp */

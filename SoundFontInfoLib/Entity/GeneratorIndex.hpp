// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <iosfwd>
#include <vector>

namespace SF2 {
namespace Entity {

enum struct GenIndex : uint16_t {
    startAddrsOffset = 0,
    endAddrsOffset,
    startLoopAddrsOffset,
    endLoopAddrsOffset,
    startAddrsCoarseOffset,
    // 5
    modLFO2Pitch,
    vibLFO2Pitch,
    modEnvToPitch,
    initialFilterFc,
    initialFilterQ,
    // 10
    modLFO2FilterFc,
    modEnv2FilterFc,
    endAddrsCoarseOffset,
    modLFO2Volume,
    unused1,
    // 15
    chorusEffectsSend,
    reverbEffectsSend,
    pan,
    unused2,
    unused3,
    // 20
    unused4,
    delayModLFO,
    freqModLFO,
    delayVibLFO,
    freqVibLFO,
    // 25
    delayModEnv,
    attackModEnv,
    holdModEnv,
    decayModEnv,
    sustainModEnv,
    // 30
    releaseModEnv,
    keynumMod2EnvHold,
    keynumMod2EnvDecay,
    delayVolEnv,
    attackVolEnv,
    // 35
    holdVolEnv,
    decayVolEnv,
    sustainVolEnv,
    releaseVolEnv,
    keynum2VolEnvHold,
    // 40
    keynum2VolEnvDecay,
    instrument,
    reserved1,
    keyRange,
    velRange,
    // 45
    startLoopAddrsCoarseOffset,
    keynum,
    velocity,
    initialAttenuation,
    reserved2,
    // 50
    endLoopAddrsCoarseOffset,
    coarseTune,
    fineTune,
    sampleID,
    sampleMode,
    // 55
    reserved3,
    scaleTuning,
    exclusiveClass,
    overridingRootKey,

    numValues
};

class GeneratorIndex {
public:

    GeneratorIndex() : rawIndex_{0} {}

    /**
     Obtain the raw index value.
     */
    uint16_t raw() const { return rawIndex_; }

    /**
     Obtain the SFGenIndex value that corresponds to the raw index value.
     */
    GenIndex index() const { return GenIndex(rawIndex_); }

private:
    uint16_t const rawIndex_;
};

}
}

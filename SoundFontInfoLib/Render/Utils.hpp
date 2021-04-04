// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include <limits>
#include <algorithm>

#include "Entity/Types.hpp"

namespace SF2 {

using Float = double;

namespace Render {
namespace Utils {

static constexpr Float ReferenceNoteFrequency = 440.0;
static constexpr Float ReferenceNoteMIDI = 69.0;
static constexpr Float ReferenceNoteSemi = ReferenceNoteMIDI * 100;
static constexpr Float CentsPerOctave = 1200.0;

static constexpr Int CentsToDurationMin = -15000;
static constexpr Int CentsToDurationDelayMax = 5186;
static constexpr Int CentsToDurationAttackMax = 8000;
static constexpr Int CentsToDurationHoldMax = 5186;
static constexpr Int CentsToDurationDecayMax = 8000;
static constexpr Int CentsToDurationReleaseMax = 8000;

static constexpr Int CentsToFrequencyMin = -16000;
static constexpr Int CentsToFrequencyMax = 4500;

static constexpr Float CentiBelsPerDecade = 200.0;
static constexpr Int CentiBelToAttenuationMax = 1440;

/**
 Convert cents value into a power of 2. There are 1200 cents per power of 2.

 @param value the value to convert
 @returns power of 2 value
 */
inline Float centsToPower2(Int value) { return std::pow(2.0, value / CentsPerOctave); }

/**
 Convert cents value into a duration of seconds. Range is limited by spec. Input values are clamped to
 [-15000, 5186], with special-casing of -32768 which returns 0.0.

 @param value value to convert
 @returns duration in seconds
 */
inline Float centsToDuration(Int value, Int maximum) {
    if (value == std::numeric_limits<Int>::min()) return 0.0; // special case for 0.0 (silly)
    else if (value < CentsToDurationMin) value = CentsToDurationMin; // min ~0.01s (per spec)
    else if (value > maximum) value = maximum;
    return centsToPower2(value);
}

inline Float centsToDurationDelay(Int value) { return centsToDuration(value, CentsToDurationDelayMax); }
inline Float centsToDurationAttack(Int value) { return centsToDuration(value, CentsToDurationAttackMax); }
inline Float centsToDurationHold(Int value) { return centsToDuration(value, CentsToDurationHoldMax); }
inline Float centsToDurationDecay(Int value) { return centsToDuration(value, CentsToDurationDecayMax); }
inline Float centsToDurationRelease(Int value) { return centsToDuration(value, CentsToDurationReleaseMax); }

/**
 Convert cents to frequency, with 0 being 8.175798 Hz. Input values are clamped to [-16000, 4500].

 @param value value to convert
 @returns frequency in Hz
 */
inline Float absoluteCentsToFrequency(Int value) {
    if (value < CentsToFrequencyMin) value = CentsToFrequencyMin; // min ~0.000792 Hz
    else if (value > CentsToFrequencyMax) value = CentsToFrequencyMax; // max ~110 Hz (spec says 100 Hz)
    return ReferenceNoteFrequency * centsToPower2(value - ReferenceNoteSemi);
}

/**
 Convert centiBel to attenuation between [1.0, 0.0]. Input values are clamped to [0, 1440]

 @param value value to convert
 @returns attenuation
 */
inline Float centiBelToAttenuation(Int value) {
    if (value <= 0) return 1.0; // max attenuation per spec
    if (value > CentiBelToAttenuationMax) return 0.0; // 144 dB limit per spec
    return std::pow(10.0, value / -CentiBelsPerDecade);
}

/**
 Convert integer into value from 0 - 1.
 */
inline Float tenthPercentage(Int value) { return std::min(std::max(value / 1000.0, 0.0), 1.0); }

inline Int clampFilterCutoff(Int value) { return value < 1500 ? 1500 : (value > 13500 ? 13500 : value); }

/**
 Generate stereo channel attenuation values from input that is in range [-500, 500], where zero is center.

 @param value value to convert
 @returns pair of attenuation values for the left (first) and right (second) channels
 */
inline std::pair<Float,Float> panAttenuation(Int value) {
    if (value < -500) value = -500;
    else if (value > 500) value = 500;
    Float theta = M_PI * (value / 500.0 + 1.0) / 4.0;
    return std::pair<Float, Float>(std::cos(theta), std::sin(theta));
}

} // namespace Utils
} // namespace Render
} // namespace SF2

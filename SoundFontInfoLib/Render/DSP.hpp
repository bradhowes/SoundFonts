// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <array>
#include <cmath>

#include "Types.hpp"

namespace SF2 {
namespace DSP {

inline constexpr double PI = M_PI;            // 180°
inline constexpr double TwoPI = 2.0 * PI;     // 360°
inline constexpr double HalfPI = PI / 2.0;    // 90°
inline constexpr double QuarterPI = PI / 4.0; // 45°

inline constexpr double ReferenceNoteFrequency = 440.0;
inline constexpr double ReferenceNoteMIDI = 69.0;
inline constexpr double ReferenceNoteSemi = ReferenceNoteMIDI * 100;
inline constexpr double CentsPerOctave = 1200.0;

inline constexpr Int CentsToDurationMin = -15000;
inline constexpr Int CentsToDurationDelayMax = 5186;
inline constexpr Int CentsToDurationAttackMax = 8000;
inline constexpr Int CentsToDurationHoldMax = 5186;
inline constexpr Int CentsToDurationDecayMax = 8000;
inline constexpr Int CentsToDurationReleaseMax = 8000;

inline constexpr Int CentsToFrequencyMin = -16000;
inline constexpr Int CentsToFrequencyMax = 4500;

inline constexpr double CentiBelsPerDecade = 200.0;
inline constexpr Int CentiBelToAttenuationMax = 1440;

// 440 * pow(2.0, (N - 69) / 12)
inline constexpr static double LowestNoteFrequency = 8.17579891564370697665253828745335; // C-1

// sqrt(2) / 2.0
inline constexpr static double HalfSquareRoot2 = M_SQRT2 / 2.0;

// The value to multiply one note frequency to get the next note's frequency
inline constexpr static double InterNoteMultiplier = 1.0594630943592953;

inline double centsToSeconds(double v) { return std::pow(2.0, v / 1200.0); }
inline double centsToFrequency(double v) { return std::pow(2.0, v / 1200.0) * LowestNoteFrequency; }

/**
 Convert cents value into a power of 2. There are 1200 cents per power of 2.

 @param value the value to convert
 @returns power of 2 value
 */
inline double centsToPower2(Int value) { return std::pow(2.0, value / CentsPerOctave); }

/**
 Convert cents value into a duration of seconds. Range is limited by spec. Input values are clamped to
 [-15000, 5186], with special-casing of -32768 which returns 0.0.

 @param value value to convert
 @returns duration in seconds
 */
inline double centsToDuration(Int value, Int maximum) {
    if (value == std::numeric_limits<Int>::min()) return 0.0; // special case for 0.0 (silly)
    else if (value < CentsToDurationMin) value = CentsToDurationMin; // min ~0.01s (per spec)
    else if (value > maximum) value = maximum;
    return centsToPower2(value);
}

inline double centsToDurationDelay(Int value) { return centsToDuration(value, CentsToDurationDelayMax); }
inline double centsToDurationAttack(Int value) { return centsToDuration(value, CentsToDurationAttackMax); }
inline double centsToDurationHold(Int value) { return centsToDuration(value, CentsToDurationHoldMax); }
inline double centsToDurationDecay(Int value) { return centsToDuration(value, CentsToDurationDecayMax); }
inline double centsToDurationRelease(Int value) { return centsToDuration(value, CentsToDurationReleaseMax); }

/**
 Convert cents to frequency, with 0 being 8.175798 Hz. Input values are clamped to [-16000, 4500].

 @param value value to convert
 @returns frequency in Hz
 */
inline double absoluteCentsToFrequency(Int value) {
    if (value < CentsToFrequencyMin) value = CentsToFrequencyMin; // min ~0.000792 Hz
    else if (value > CentsToFrequencyMax) value = CentsToFrequencyMax; // max ~110 Hz (spec says 100 Hz)
    return ReferenceNoteFrequency * centsToPower2(value - ReferenceNoteSemi);
}

/**
 Restrict lowpass filter cutoff value to be between 1500 and 13500, inclusive.

 @param value cutoff value
 @returns clamped cutoff value
 */
inline Int clampFilterCutoff(Int value) { return std::clamp<Int>(value, 1500, 13500); }

/**
 Convert integer from integer [0-1000] into [0.0-1.0]

 @param value percentage value expressed as tenths
 @returns normalized value between 0 and 1.
 */
inline double tenthPercentage(Int value) { return std::clamp(value / 1000.0, 0.0, 1.0); }

/**
 Translate value in range [0, +1] into one in range [-1, +1]

 @param modulator the value to translate
 @returns value in range [-1, +1]
 */
inline double unipolarToBipolar(double modulator) { return 2.0 * modulator - 1.0; }

/**
 Translate value in range [-1, +1] into one in range [0, +1]

 @param modulator the value to translate
 @returns value in range [0, +1]
 */
inline double bipolarToUnipolar(double modulator) { return 0.5 * modulator + 0.5; }

/**
 Perform linear translation from a value in range [0.0, 1.0] into one in [minValue, maxValue].

 @param modulator the value to translate
 @param minValue the lowest value to return when modulator is 0
 @param maxValue the highest value to return when modulator is +1
 @returns value in range [minValue, maxValue]
 */
inline double unipolarModulation(double modulator, double minValue, double maxValue) {
    return std::clamp(modulator, 0.0, 1.0) * (maxValue - minValue) + minValue;
}

/**
 Perform linear translation from a value in range [-1.0, 1.0] into one in [minValue, maxValue]

 @param modulator the value to translate
 @param minValue the lowest value to return when modulator is -1
 @param maxValue the highest value to return when modulator is +1
 @returns value in range [minValue, maxValue]
 */
inline double bipolarModulation(double modulator, double minValue, double maxValue) {
    auto mid = (maxValue - minValue) * 0.5;
    return std::clamp(modulator, -1.0, 1.0) * mid + mid + minValue;
}

/**
 Estimate sin() value from a radian angle between -PI and PI.
 Derived from code in "Designing Audio Effect Plugins in C++" by Will C. Pirkle (2019)
 As can be seen in the unit test `testParabolicSineAccuracy`, the worst-case deviation from
 std::sin is ~0.0011.

 @param angle value between -PI and PI
 @returns approximate sin value
 */
constexpr double parabolicSine(double angle) {
    constexpr double B = 4.0 / M_PI;
    constexpr double C = -4.0 / (M_PI * M_PI);
    constexpr double P = 0.225;
    const double y = B * angle + C * angle * (angle >= 0.0 ? angle : -angle);
    return P * y * ((y >= 0.0 ? y : -y) - 1.0) + y;
}

struct PanLookup {
    inline constexpr static size_t TableSize = 500 + 500 + 1;

    static void lookup(int pan, double& left, double& right) {
        pan = std::clamp(pan, -500, 500);
        left = lookup_[-pan + 500];
        right = lookup_[pan + 500];
    }

private:
    static const std::array<double, PanLookup::TableSize> lookup_;
};

inline void panLookup(int pan, double& left, double& right) { PanLookup::lookup(pan, left, right); }

/**
 Estimate sin() value using a table of pre-calculated sin values and linear interpolation.
 */
struct SineLookup {
    inline constexpr static size_t TableSize = 4096;

    static double lookup(double radians) {
        if (radians < 0.0) return -sin(-radians);
        while (radians > TwoPI) radians -= TwoPI;
        if (radians <= HalfPI) return interpolate(radians);
        if (radians <= PI) return interpolate(PI - radians);
        if (radians <= 3 * HalfPI) return -interpolate(radians - PI);
        return -interpolate(TwoPI - radians);
    }

private:

    inline constexpr static double TableScale = (TableSize - 1) / HalfPI;

    static double interpolate(double radians) {
        double phase = std::clamp(radians, 0.0, HalfPI) * TableScale;
        int index = int(phase);
        double partial = phase - index;
        double value = lookup_[index] * (1.0 - partial);
        if (partial > 0.0) value += lookup_[index + 1] * partial;
        return value;
    }

    static const std::array<double, TableSize> lookup_;
};

inline double sineLookup(double radians) { return SineLookup::lookup(radians); }

/**
 Convert cent into frequency multiplier using a table lookup. For instance, to reduce a frequency by -1200 cents means
 to drop 1 octave which is the same as multiplying the source frequency by 0.5. In the other direction an increase of
 1200 cents should result in a multiplier of 2.0 to double the source frequency.
 */
struct CentFrequencyLookup {
    inline constexpr static int MaxCentValue = 1200;

    /**
     Convert given cents value into a frequency multiplier.

     @param cent the value to convert
     @returns multiplier for a frequency that will change the frequency by the given cent value
     */
    static double convert(int cent) { return lookup_[std::clamp(cent, -MaxCentValue, MaxCentValue) + MaxCentValue]; }

private:
    static const std::array<double, MaxCentValue * 2 + 1> lookup_;
};

inline double centToFrequencyMultiplier(int cent) { return CentFrequencyLookup::convert(cent); }

/**
 Table lookup for the centToFrequency method below.
 */
struct CentPartialLookup {
    inline constexpr static int MaxCentValue = 1200;
    static double find(int partial) { return lookup_[partial]; }
private:
    static const std::array<double, MaxCentValue> lookup_;
};

/**
 Quickly convert cent value into a frequency using a table lookup. These calculations are taken from the Fluid Synth
 fluid_conv.c file, in particular the fluid_ct2hz_real function. Uses CentPartialLookup above to convert values from
 0 - 1199 into the proper multiplier.
 */
inline double centToFrequency(double value) {
    if (value < 0.0) return 1.0;
    unsigned int cents = (unsigned int)(value) + 300;
    unsigned int whole = cents / 1200;
    unsigned int partial = cents - whole * 1200;
    return (1u << whole) * CentPartialLookup::find(partial);
}

inline double centibelsToNorm(int centibels) { return std::pow(10.0, centibels / -200.0); }

/**
 Convert centibels into attenuation via table lookup.
 */
struct AttenuationLookup {
    inline constexpr static int TableSize = 1441;
    static double convert(int centibels) { return lookup_[std::clamp(centibels, 0, TableSize - 1)]; }
private:
    static const std::array<double, TableSize> lookup_;
};

/**
 Convert centibels into gain value (same as 1.0 / attenuation)
 */
struct GainLookup {
    inline constexpr static int TableSize = 1441;
    static double lookup(int centibels) { return lookup_[std::clamp(centibels, 0, TableSize - 1)]; }
private:
    static const std::array<double, TableSize> lookup_;
};

inline double centibelToAttenuation(int centibels) { return AttenuationLookup::convert(centibels); }

inline double centibelToGain(int centibels) { return GainLookup::lookup(centibels); }

namespace Interpolation {

struct Linear {

    /**
     Interpolate a value from two values.

     @param partial indication of affinity for one of the two values. Low values give greater weight to x0 while higher
     values give greater weight to x1.
     @param x0 first value to use
     @param x1 second value to use
     */
    inline static double interpolate(double partial, double x0, double x1) {
        double w1 = partial;
        double w0 = 1.0 - partial;
        return x0 * w0 + x1 * w1;
    }
};

/**
 Collection of objects and methods for performing fast cubic 4th-order interpolation.
 */
struct Cubic4thOrder {

    /**
     Number of weights (x4) to generate.
     */
    constexpr static size_t weightsCount = 1024;

    using WeightsArray = std::array<std::array<double, 4>, weightsCount>;

    /**
     Interpolate a value from four values.

     @param partial location between the second value and the third. By definition it should always be < 1.0
     @param x0 first value to use
     @param x1 second value to use
     @param x2 third value to use
     @param x3 fourth value to use
     */
    inline static double interpolate(double partial, double x0, double x1, double x2, double x3) {
        auto index = size_t(partial * weightsCount);
        assert(index < weightsCount); // should always be true based on definition of `partial`
        auto w = weights_[index];
        return x0 * w[0] + x1 * w[1] + x2 * w[2] + x3 * w[3];
    }

private:

    /**
     Array of weights used during interpolation. Initialized at startup.
     */
    static const WeightsArray weights_;
};

} // Interpolation namespace
} // DSP namespace
} // SF2 namespace

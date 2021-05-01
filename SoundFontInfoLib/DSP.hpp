// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <array>
#include <cmath>
#include <iosfwd>

#include "Types.hpp"

namespace SF2 {
namespace DSP {
namespace Generators { void Generate(std::ostream&); }

inline constexpr double PI = M_PI;            // 180°
inline constexpr double TwoPI = 2.0 * PI;     // 360°
inline constexpr double HalfPI = PI / 2.0;    // 90°
inline constexpr double QuarterPI = PI / 4.0; // 45°

inline constexpr double ReferenceNoteFrequency = 440.0;
inline constexpr double ReferenceNoteMIDI = 69.0;
inline constexpr double ReferenceNoteSemi = ReferenceNoteMIDI * 100;
inline constexpr double CentsPerOctave = 1200.0;

inline constexpr Int CentsToFrequencyMin = -16000;
inline constexpr Int CentsToFrequencyMax = 4500;

inline constexpr double CentiBelsPerDecade = 200.0;
inline constexpr Int CentiBelToAttenuationMax = 1440;

// 440 * pow(2.0, (N - 69) / 12)
inline constexpr double LowestNoteFrequency = 8.17579891564370697665253828745335; // C-1

// sqrt(2) / 2.0
inline constexpr static double HalfSquareRoot2 = M_SQRT2 / 2.0;

// The value to multiply one note frequency to get the next note's frequency
inline constexpr static double InterNoteMultiplier = 1.05946309435929530984310531493975;

/**
 Convert cents value into seconds, where There are 1200 cents per power of 2.

 @param value the number to convert
 */
template <typename T>
inline double centsToSeconds(T value) { return std::pow(2.0, double(value) / 1200.0); }

/**
 Convert cents value into a power of 2. There are 1200 cents per power of 2.

 @param value the value to convert
 @returns power of 2 value
 */
template <typename T>
inline double centsToPower2(T value) { return std::pow(2.0, double(value) / CentsPerOctave); }

/**
 Convert cents to frequency, with 0 being 8.175798 Hz. Input values are clamped to [-16000, 4500].

 @param value value to convert
 @returns frequency in Hz
 */
inline double absoluteCentsToFrequency(Int value) {
    return ReferenceNoteFrequency * centsToPower2(std::clamp(value, CentsToFrequencyMin, CentsToFrequencyMax) -
                                                  ReferenceNoteSemi);
}

/**
 Restrict lowpass filter cutoff value to be between 1500 and 13500, inclusive.

 @param value cutoff value
 @returns clamped cutoff value
 */
inline double clampFilterCutoff(double value) { return std::clamp<double>(value, 1500, 20000); }

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
inline double unipolarModulate(double modulator, double minValue, double maxValue) {
    return std::clamp(modulator, 0.0, 1.0) * (maxValue - minValue) + minValue;
}

/**
 Perform linear translation from a value in range [-1.0, 1.0] into one in [minValue, maxValue]

 @param modulator the value to translate
 @param minValue the lowest value to return when modulator is -1
 @param maxValue the highest value to return when modulator is +1
 @returns value in range [minValue, maxValue]
 */
inline double bipolarModulate(double modulator, double minValue, double maxValue) {
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
    PanLookup() = delete;
};

/**
 Calculate the amount of left and right signal gain in [0.0-1.0] for the given `pan` value which is in range
 [-500-+500]. A `pan` of -500 is only left, and +500 is only right. A `pan` of 0 should result in ~0.7078 for both.

 @param pan the value to convert
 @param left reference to storage for the left gain
 @param right reference to storage for the right gain
 */
inline void panLookup(int pan, double& left, double& right) { PanLookup::lookup(pan, left, right); }

/**
 Estimate sin() value using a table of pre-calculated sin values and linear interpolation.
 */
struct SineLookup {
    inline constexpr static size_t TableSize = 4096;
    inline static double lookup(double radians) {
        if (radians < 0.0) return -sin(-radians);
        while (radians > TwoPI) radians -= TwoPI;
        if (radians <= HalfPI) return interpolate(radians);
        if (radians <= PI) return interpolate(PI - radians);
        if (radians <= 3 * HalfPI) return -interpolate(radians - PI);
        return -interpolate(TwoPI - radians);
    }

private:
    inline constexpr static double TableScale = (TableSize - 1) / HalfPI;

    inline static double interpolate(double radians) {
        double phase = std::clamp(radians, 0.0, HalfPI) * TableScale;
        int index = int(phase);
        double partial = phase - index;
        double value = lookup_[index] * (1.0 - partial);
        if (partial > 0.0) value += lookup_[index + 1] * partial;
        return value;
    }

    friend void Generators::Generate(std::ostream&);
    static const std::array<double, TableSize> lookup_;
    SineLookup() = delete;
};

/**
 Obtain approximate sine value from table.

 @param radians the value to use for theta
 @returns the sine approximation
 */
inline double sineLookup(double radians) { return SineLookup::lookup(radians); }

/**
 Convert cent into frequency multiplier using a table lookup. For instance, to reduce a frequency by -1200 cents means
 to drop 1 octave which is the same as multiplying the source frequency by 0.5. In the other direction an increase of
 1200 cents should result in a multiplier of 2.0 to double the source frequency.
 */
struct CentsFrequencyLookup {
    inline constexpr static int MaxCentsValue = 1200;
    inline constexpr static size_t TableSize = MaxCentsValue * 2 + 1;

    /**
     Convert given cents value into a frequency multiplier.

     @param cent the value to convert
     @returns multiplier for a frequency that will change the frequency by the given cent value
     */
    static double convert(int cent) { return lookup_[std::clamp(cent, -MaxCentsValue, MaxCentsValue) + MaxCentsValue]; }

private:
    static const std::array<double, TableSize> lookup_;
    CentsFrequencyLookup() = delete;
};

inline double centsToFrequencyMultiplier(int cent) { return CentsFrequencyLookup::convert(cent); }

/**
 Table lookup for the centToFrequency method below.
 */
struct CentsPartialLookup {
    inline constexpr static int MaxCentsValue = 1200;
    inline constexpr static size_t TableSize = MaxCentsValue;
    static double find(int partial) { return lookup_[std::clamp(partial, 0, MaxCentsValue - 1)]; }
private:
    static const std::array<double, TableSize> lookup_;
    CentsPartialLookup() = delete;
};

/**
 Quickly convert cent value into a frequency using a table lookup. These calculations are taken from the Fluid Synth
 fluid_conv.c file, in particular the fluid_ct2hz_real function. Uses CentPartialLookup above to convert values from
 0 - 1199 into the proper multiplier.
 */
inline double centsToFrequency(double value) {
    if (value < 0.0) return 1.0;
    unsigned int cents = (unsigned int)(value) + 300;
    unsigned int whole = cents / 1200;
    unsigned int partial = cents - whole * 1200;
    return (1u << whole) * CentsPartialLookup::find(partial);
}

inline double centibelsToNorm(int centibels) { return std::pow(10.0, centibels / -200.0); }

/**
 Convert centibels into attenuation via table lookup.
 */
struct AttenuationLookup {
    inline constexpr static size_t TableSize = 1441;
    static double convert(int centibels) { return lookup_[std::clamp<int>(centibels, 0, TableSize - 1)]; }
private:
    static const std::array<double, TableSize> lookup_;
    AttenuationLookup() = delete;
};

/**
 Convert centibels [0-1441] into an attenuation value from [1.0-0.0]. Zero indicates no attenuation (1.0), 60 is ~0.5,
 and every 200 is a reduction by 10 (0.1, 0.001, etc.)

 @param centibels value to convert
 @returns gain value
 */
inline double centibelsToAttenuation(int centibels) { return AttenuationLookup::convert(centibels); }

/**
 Convert centibels into gain value (same as 1.0 / attenuation)
 */
struct GainLookup {
    inline constexpr static size_t TableSize = 1441;
    static double lookup(int centibels) { return lookup_[std::clamp<int>(centibels, 0, TableSize - 1)]; }
private:
    static const std::array<double, TableSize> lookup_;
    GainLookup() = delete;
};

/**
 Convert centibels [0-1441] into a gain value [0.0-1.0].

 @param centibels value to convert
 @returns gain value
 */
inline double centibelsToGain(int centibels) { return GainLookup::lookup(centibels); }

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
private:
    Linear() = delete;
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
    Cubic4thOrder() = delete;
};

} // Interpolation namespace
} // DSP namespace
} // SF2 namespace

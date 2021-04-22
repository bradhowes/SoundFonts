// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <array>
#include <cmath>
// #include <iostream>

namespace SF2 {
namespace DSP {

inline constexpr static double PI = M_PI;            // 180°
inline constexpr static double TwoPI = 2.0 * PI;     // 360°
inline constexpr static double HalfPI = PI / 2.0;    // 90°
inline constexpr static double QuarterPI = PI / 4.0; // 45°

// 440 * pow(2.0, (N - 69) / 12)
constexpr static double LowestNoteFrequency = 8.175798915643707; // C-1

// sqrt(2) / 2.0
constexpr static double HalfSquareRoot2 = 1.4142135623730951L / 2.0;

// The value to multiply one note frequency to get the next note's frequency
constexpr static double InterNoteMultiplier = 1.0594630943592953;

inline double centsToSeconds(double v) { return pow(2.0, v / 1200.0); }
inline double centsToFrequency(double v) { return pow(2.0, v / 1200.0) * LowestNoteFrequency; }

/**
 Translate value in range [0, +1] into one in range [-1, +1]

 @param modulator the value to translate
 @returns value in range [-1, +1]
 */
template <typename T> T unipolarToBipolar(T modulator) { return 2.0 * modulator - 1.0; }

/**
 Translate value in range [-1, +1] into one in range [0, +1]

 @param modulator the value to translate
 @returns value in range [0, +1]
 */
template <typename T> T bipolarToUnipolar(T modulator) { return 0.5 * modulator + 0.5; }

/**
 Perform linear translation from a value in range [0.0, 1.0] into one in [minValue, maxValue].

 @param modulator the value to translate
 @param minValue the lowest value to return when modulator is 0
 @param maxValue the highest value to return when modulator is +1
 @returns value in range [minValue, maxValue]
 */
template <typename T> T unipolarModulation(T modulator, T minValue, T maxValue) {
    return std::clamp<T>(modulator, 0.0, 1.0) * (maxValue - minValue) + minValue;
}

/**
 Perform linear translation from a value in range [-1.0, 1.0] into one in [minValue, maxValue]

 @param modulator the value to translate
 @param minValue the lowest value to return when modulator is -1
 @param maxValue the highest value to return when modulator is +1
 @returns value in range [minValue, maxValue]
 */
template <typename T> T bipolarModulation(T modulator, T minValue, T maxValue) {
    auto mid = (maxValue - minValue) * 0.5;
    return std::clamp<T>(modulator, -1.0, 1.0) * mid + mid + minValue;
}

/**
 Estimate sin() value from a radian angle between -PI and PI.
 Derived from code in "Designing Audio Effect Plugins in C++" by Will C. Pirkle (2019)
 As can be seen in the unit test `testParabolicSineAccuracy`, the worst-case deviation from
 std::sin is ~0.0011.

 @param angle value between -PI and PI
 @returns approximate sin value
 */
template <typename T> T parabolicSine(T angle) {
    constexpr T B = 4.0 / M_PI;
    constexpr T C = -4.0 / (M_PI * M_PI);
    constexpr T P = 0.225;
    const T y = B * angle + C * angle * std::abs(angle);
    return P * y * (std::abs(y) - 1.0) + y;
}

template <typename T>
struct PanLookup {
    inline constexpr static size_t TableSize = 500 + 500 + 1;

    static void lookup(int pan, T& left, T& right) {
        pan = std::clamp(pan, -500, 500);
        left = lookup_[-pan + 500];
        right = lookup_[pan + 500];
    }

private:

    inline static const std::array<T, TableSize> lookup_ = [] {
        auto init = decltype(PanLookup::lookup_){};
        auto scale = HalfPI / (TableSize - 1);
        for (auto index = 0; index < init.size(); ++index) {
            init[index] = ::std::sin(scale * index);
        }
        return init;
    }();
};

template <typename T> void panLookup(int pan, T& left, T& right) { PanLookup<T>::lookup(pan, left, right); }

/**
 Estimate sin() value using a table of pre-calculated sin values and linear interpolation.
 */
template <typename T>
struct SineLookup {
    inline constexpr static size_t TableSize = 4096;

    static T lookup(T radians) {
        if (radians < 0.0) return -sin(-radians);
        while (radians > TwoPI) radians -= TwoPI;
        if (radians <= HalfPI) return interpolate(radians);
        if (radians <= PI) return interpolate(PI - radians);
        if (radians <= 3 * HalfPI) return -interpolate(radians - PI);
        return -interpolate(TwoPI - radians);
    }

private:

    inline constexpr static T TableScale = (TableSize - 1) / HalfPI;

    static T interpolate(T radians) {
        T phase = std::clamp(radians, 0.0, HalfPI) * TableScale;
        int index = int(phase);
        double partial = phase - index;
        double value = lookup_[index] * (1.0 - partial);
        if (partial > 0.0) value += lookup_[index + 1] * partial;
        return value;
    }

    inline static const std::array<T, TableSize> lookup_ = [] {
        auto init = decltype(SineLookup::lookup_){};
        auto scale = HalfPI / (init.size() - 1);
        for (auto index = 0; index < init.size(); ++index) {
            init[index] = ::std::sin(scale * index);
        }
        return init;
    }();
};

template <typename T> T sineLookup(T radians) { return SineLookup<T>::lookup(radians); }

/**
 Convert cent into frequency multiplier using a table lookup. For instance, to reduce a frequency by -1200 cents means
 to drop 1 octave which is the same as multiplying the source frequency by 0.5. In the other direction an increase of
 1200 cents should result in a multiplier of 2.0 to double the source frequency.
 */
template <typename T>
struct CentFrequencyLookup {
    inline constexpr static int MaxCentValue = 1200;

    /**
     Convert given cents value into a frequency multiplier.

     @param cent the value to convert
     @returns multiplier for a frequency that will change the frequency by the given cent value
     */
    static T convert(int cent) { return lookup_[std::clamp(cent, -MaxCentValue, MaxCentValue) + MaxCentValue]; }

private:

    inline static const std::array<T, MaxCentValue * 2 + 1> lookup_ = [] {
        auto init = decltype(lookup_){};
        auto span = T((init.size() - 1) / 2);
        for (auto index = 0; index < init.size(); ++index) {
            init[index] = std::pow(2.0, (index - span) / span);
        }
        return init;
    }();
};

template <typename T> T centToFrequencyMultiplier(int cent) {
    return CentFrequencyLookup<T>::convert(cent);
}

/**
 Table lookup for the centToFrequency method below.
 */
template <typename T>
struct CentPartialLookup {
    inline constexpr static int MaxCentValue = 1200;

    static T find(int partial) { return lookup_[partial]; }

private:

    inline static const std::array<T, MaxCentValue> lookup_ = [] {
        auto init = decltype(lookup_){};
        for (auto index = 0; index < init.size(); ++index) {
            init[index] = 6.875 * std::pow(2.0, double(index) / 1200.0);
        }
        return init;
    }();
};

/**
 Quickly convert cent value into a frequency using a table lookup. These calculations are taken from the Fluid Synth
 fluid_conv.c file, in particular the fluid_ct2hz_real function. Uses CentPartialLookup above to convert values from
 0 - 1199 into the proper multiplier.
 */
template <typename T>
T centToFrequency(double value) {
    if (value < 0.0) return 1.0;
    unsigned int cents = (unsigned int)(value) + 300;
    unsigned int whole = cents / 1200;
    unsigned int partial = cents - whole * 1200;
    return (1u << whole) * CentPartialLookup<T>::find(partial);
}

template <typename T> T centibelsToNorm(int centibels) { return std::pow(10.0, centibels / -200.0); }

/**
 Convert centibels into attenuation via table lookup.
 */
template <typename T>
struct AttenuationLookup {
    inline constexpr static int TableSize = 1441;

    static T convert(int centibels) {
        return centibels <= 0 ? 1.0 : (centibels >= TableSize ? 0.0 : lookup_[centibels]);
    }

private:

    inline static const std::array<T, TableSize> lookup_ = [] {
        auto init = decltype(lookup_){};
        for (auto index = 0; index < init.size(); ++index) {
            init[index] = centibelsToNorm<T>(index);
        }
        return init;
    }();
};

template <typename T> T centibelToAttenuation(int centibels) { return AttenuationLookup<T>::convert(centibels); }

/**
 Convert centibels into gain value (same as 1.0 / attenuation)
 */
template <typename T>
struct GainLookup {
    inline constexpr static int TableSize = 1441;

    static T lookup(int centibels) {
        if (centibels <= 0.0) return 1.0;
        if (centibels >= TableSize) centibels = TableSize - 1;
        return lookup_[centibels];
    }

private:

    inline static const std::array<T, TableSize> lookup_ = [] {
        auto init = decltype(lookup_){};
        for (auto index = 0; index < init.size(); ++index) {
            init[index] = 1.0 / centibelsToNorm<T>(index);
        }
        return init;
    }();
};

template <typename T> T centibelToGain(int centibels) { return GainLookup<T>::lookup(centibels); }

namespace Interpolation {

template <typename T>
struct Linear {

    /**
     Interpolate a value from two values.

     @param partial indication of affinity for one of the two values. Low values give greater weight to x0 while higher
     values give greater weight to x1.
     @param x0 first value to use
     @param x1 second value to use
     */
    inline static T interpolate(double partial, T x0, T x1) {
        T w1 = partial;
        T w0 = 1.0 - partial;
        return x0 * w0 + x1 * w1;
    }
};

/**
 Collection of objects and methods for performing fast cubic 4th-order interpolation.
 */
template <typename T>
struct Cubic4thOrder {

    /**
     Number of weights (x4) to generate.
     */
    constexpr static size_t weightsCount = 256;

    using WeightsArray = std::array<std::array<T, 4>, weightsCount>;

    /**
     Interpolate a value from four values.

     @param partial location between the second value and the third. By definition it should always be < 1.0
     @param x0 first value to use
     @param x1 second value to use
     @param x2 third value to use
     @param x3 fourth value to use
     */
    inline static T interpolate(double partial, T x0, T x1, T x2, T x3) {
        auto index = size_t(partial * weightsCount);
        assert(index < weightsCount); // should always be true based on definition of `partial`
        auto w = weights[index];
        return x0 * w[0] + x1 * w[1] + x2 * w[2] + x3 * w[3];
    }

private:

    /**
     Array of weights used during interpolation. Initialized at startup.
     */
    inline static WeightsArray weights = []() {

        // Comment from FluidSynth - see https://github.com/FluidSynth/fluidsynth/blob/master/src/gentables/gen_rvoice_dsp.c
        // Initialize the coefficients for the interpolation. The math comes from a mail, posted by Olli Niemitalo to the
        // music-dsp mailing list (I found it in the music-dsp archives http://www.smartelectronix.com/musicdsp/).
        //
        // Reordered and normalized to better understand coefficients.
        WeightsArray weights;
        for (int index = 0; index < weightsCount; ++index) {
            auto x = double(index) / double(weightsCount);
            auto x_05 = 0.5 * x;
            auto x2 = x * x;
            auto x3 = x2 * x;
            auto x3_05 = 0.5 * x3;
            auto x3_15 = 1.5 * x3;
            weights[index][0] = -x3_05 +       x2 - x_05;
            weights[index][1] =  x3_15 - 2.5 * x2         + 1.0;
            weights[index][2] = -x3_15 + 2.0 * x2 + x_05;
            weights[index][3] =  x3_05 - 0.5 * x2;
        }

        return weights;
    }();

};

} // Interpolation namespace
} // DSP namespace
} // SF2 namespace

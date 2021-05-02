// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

namespace Tables {

struct Generator;

struct PanLookup {
    inline constexpr static size_t TableSize = 500 + 500 + 1;

    static void lookup(Float pan, Float& left, Float& right) {
        int index = std::clamp(int(std::round(pan)), -500, 500);
        left = lookup_[-index + 500];
        right = lookup_[index + 500];
    }

private:
    inline constexpr static Float Scaling = HalfPI / (TableSize - 1);

    static Float value(size_t index) { return parabolicSine(index * Scaling); }

    static const std::array<Float, PanLookup::TableSize> lookup_;
    PanLookup() = delete;
    friend struct Generator;
};

/**
 Estimate sin() value using a table of pre-calculated sin values and linear interpolation.
 */
struct SineLookup {
    inline constexpr static size_t TableSize = 4096;

    inline static Float convert(Float radians) {
        if (radians < 0.0) return -sin(-radians);
        while (radians > TwoPI) radians -= TwoPI;
        if (radians <= HalfPI) return interpolate(radians);
        if (radians <= PI) return interpolate(PI - radians);
        if (radians <= 3 * HalfPI) return -interpolate(radians - PI);
        return -interpolate(TwoPI - radians);
    }

private:
    inline constexpr static Float TableScale = (TableSize - 1) / HalfPI;
    inline constexpr static Float Scaling = HalfPI / (TableSize - 1);

    inline static Float interpolate(Float radians) {
        Float phase = std::clamp(radians, 0.0, HalfPI) * TableScale;
        int index = int(phase);
        Float partial = phase - index;
        Float value = lookup_[index] * (1.0 - partial);
        if (partial > 0.0) value += lookup_[index + 1] * partial;
        return value;
    }

    static Float value(size_t index) { return std::sin(index * Scaling); }

    static const std::array<Float, TableSize> lookup_;
    SineLookup() = delete;
    friend struct Generator;
};

/**
 Convert cent into frequency multiplier using a table lookup. For instance, to reduce a frequency by -1200 cents means
 to drop 1 octave which is the same as multiplying the source frequency by 0.5. In the other direction an increase of
 1200 cents should result in a multiplier of 2.0 to double the source frequency.
 */
struct CentsFrequencyLookup {
    inline constexpr static int Max = 1200;
    inline constexpr static size_t TableSize = Max * 2 + 1;

    /**
     Convert given cents value into a frequency multiplier.

     @param value the value to convert
     @returns multiplier for a frequency that will change the frequency by the given cent value
     */
    static Float convert(int value) { return lookup_[std::clamp(value, -Max, Max) + Max]; }

    static Float convert(Float value) { return convert(int(std::round(value))); }

private:
    inline constexpr static Float Span = Float((CentsFrequencyLookup::TableSize - 1) / 2);

    static Float value(size_t index) { return std::pow(2.0, (index - Span) / Span); }

    static const std::array<Float, TableSize> lookup_;
    CentsFrequencyLookup() = delete;
    friend struct Generator;
};

/**
 Convert cents to frequency.
 */
struct CentsPartialLookup {
    inline constexpr static int MaxCentsValue = 1200;
    inline constexpr static size_t TableSize = MaxCentsValue;

    static Float convert(int partial) { return lookup_[std::clamp<int>(partial, 0, MaxCentsValue - 1)]; }

private:
    static Float value(size_t index) { return 6.875 * std::pow(2.0, Float(index) / 1200.0); }
    static const std::array<Float, TableSize> lookup_;
    CentsPartialLookup() = delete;
    friend struct Generator;
};

/**
 Convert centibels into attenuation via table lookup.
 */
struct AttenuationLookup {
    inline constexpr static size_t TableSize = 1441;

    static Float convert(int centibels) { return lookup_[std::clamp<int>(centibels, 0, TableSize - 1)]; }

    static Float convert(Float centibels) { return convert(int(std::round(centibels))); }

private:
    static const std::array<Float, TableSize> lookup_;

    static Float value(size_t index) { return centibelsToAttenuation(index); }

    AttenuationLookup() = delete;
    friend struct Generator;
};

/**
 Convert centibels into gain value (same as 1.0 / attenuation)
 */
struct GainLookup {
    inline constexpr static size_t TableSize = 1441;

    static Float convert(int centibels) { return lookup_[std::clamp<int>(centibels, 0, TableSize - 1)]; }

    static Float convert(Float centibels) { return convert(int(std::round(centibels))); }

private:
    static Float value(size_t index) { return 1.0 / centibelsToAttenuation(index); }
    static const std::array<Float, TableSize> lookup_;
    GainLookup() = delete;
    friend struct Generator;
};

struct Cubic4thOrder {

    /// Number of weights (x4) to generate.
    inline constexpr static size_t TableSize = 1024;

    using WeightsArray = std::array<std::array<Float, 4>, TableSize>;

    /**
     Interpolate a value from four values.

     @param partial location between the second value and the third. By definition it should always be < 1.0
     @param x0 first value to use
     @param x1 second value to use
     @param x2 third value to use
     @param x3 fourth value to use
     */
    inline static Float interpolate(Float partial, Float x0, Float x1, Float x2, Float x3) {
        auto index = size_t(partial * TableSize);
        assert(index < TableSize); // should always be true based on definition of `partial`
        auto w = weights_[index];
        return x0 * w[0] + x1 * w[1] + x2 * w[2] + x3 * w[3];
    }

private:

    /**
     Array of weights used during interpolation. Initialized at startup.
     */
    static const WeightsArray weights_;
    Cubic4thOrder() = delete;
    friend struct Generator;
};

} // Tables namespace

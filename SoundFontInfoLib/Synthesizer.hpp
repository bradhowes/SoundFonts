// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <array>
#include <cassert>
#include <cmath>
#include <iostream>

namespace SF2 {

inline auto clamp(double value, double min, double max) -> auto { return std::min(std::max(value, min), max); }
// cb = -200 * log10(amp)
// amp = pow(10, cb/-200)

struct SampleRateBased {
    constexpr static double sampleRate = 44100.0;
};

struct Duration : SampleRateBased {
    constexpr explicit Duration(double duration) : samples{duration * sampleRate} {}
    double const samples;
};

struct Frequency : SampleRateBased {
    constexpr explicit Frequency(double frequency) : samples{frequency * sampleRate} {}
    double const samples;
    double const value() const { return samples / sampleRate; }
};

class Synthesizer {
public:
    constexpr static double PI = M_PI;            // 180°
    constexpr static double TwoPI = 2.0 * PI;     // 360°
    constexpr static double HalfPI = PI / 2.0;    // 90°
    constexpr static double QuarterPI = PI / 4.0; // 45°

    // 440 * pow(2.0, (N - 69) / 12)
    constexpr static double LowestNoteFrequency = 8.175798915643707; // C-1

    constexpr static size_t SineLookupTableSize = 4096;
    constexpr static double SineLookupTableScale = (SineLookupTableSize - 1) / HalfPI;

    // sqrt(2) / 2.0
    constexpr static double HalfSquareRoot2 = 1.4142135623730951L / 2.0;

    // The value to multiply one note frequency to get the next note's frequency
    constexpr static double InterNoteMultiplier = 1.0594630943592953;

    static void setSampleRate(double sampleRate) { sampleRate_ = sampleRate; }
    static auto sampleRate() -> auto { return sampleRate_; }

    constexpr static int MaxMIDINote = 127;

    static auto midiKeyToFrequency(int key) -> auto {
        return standardNoteFrequencies_[clamp(key, 0, MaxMIDINote)];
    }

    constexpr static int MaxCentValue = 1200;

    static auto centToFrequencyMultiplier(int cent) -> auto {
        return centFrequencyMultiplier_[clamp(cent, -MaxCentValue, MaxCentValue) + MaxCentValue];
    }

    static auto sineLookup(double radians) -> double {
        double phase = clamp(radians, 0.0, HalfPI) * SineLookupTableScale;
        int index = int(phase);
        double frac = phase - index;
        double value = sineLookup_[index] * (1.0 - frac);
        if (frac > 0.0) value += sineLookup_[index + 1] * frac;
        return value;
    }

    constexpr static auto sin(double radians) -> double {
        if (radians < 0.0) {                // < 0°
            return -sin(-radians);
        }
        else if (radians <= HalfPI) {       // 90°
            return sineLookup(radians);
        }
        else if (radians <= PI) {           // 180°
            return sin(PI - radians);
        }
        else if (radians <= 3 * HalfPI) {   // 270°
            return -sin(radians - PI);
        }
        else if (radians <= TwoPI) {        // 360°
            return -sin(TwoPI - radians);
        }
        else {                              // > 360°
            return sin(radians - TwoPI);
        }
    }

    constexpr static int CentibelsTableSize = 1441;

    constexpr static auto attenuation(int centibels) -> auto {
        if (centibels <= 0) return 1.0;
        if (centibels >= CentibelsTableSize) return 0.0;
        return centibelsToAttenuation_[centibels];
    }
    
    constexpr static auto gain(int centibels) -> auto {
        if (centibels <= 0.0) return 1.0;
        if (centibels >= CentibelsTableSize) centibels = CentibelsTableSize - 1;
        return centibelsToGain_[centibels];
    }

private:
    static double sampleRate_;

    static std::array<double, MaxMIDINote + 1> standardNoteFrequencies_;
    static std::array<double, MaxCentValue * 2 + 1> centFrequencyMultiplier_;
    static std::array<double, SineLookupTableSize> sineLookup_;
    static std::array<double, CentibelsTableSize> centibelsToAttenuation_;
    static std::array<double, CentibelsTableSize> centibelsToGain_;
};

}

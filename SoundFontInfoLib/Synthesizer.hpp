// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>
#include <cassert>
#include <cmath>
#include <iostream>

namespace SF2 {

class Synthesizer {
public:
    constexpr static double PI = M_PI;            // 180°
    constexpr static double TwoPI = 2.0 * PI;     // 360°
    constexpr static double HalfPI = PI / 2.0;    // 90°
    constexpr static double QuarterPI = PI / 4.0; // 45°

    constexpr static int MaxMIDINote = 127;
    constexpr static int MaxCentValue = 1200;

    // 440 * pow(2.0, (N - 69) / 12)
    constexpr static double LowestNoteFrequency = 8.175798915643707; // C-1

    constexpr static size_t SineLookupTableSize = 4096;
    constexpr static double SineLookupTableScale = (SineLookupTableSize - 1) / HalfPI;

    // sqrt(2) / 2.0
    constexpr static double HalfSquareRoot2 = 1.4142135623730951L / 2.0;

    // The value to multiply one note frequency to get the next note's frequency
    constexpr static double InterNoteMultiplier = 1.0594630943592953;

    static void setSampleRate(double sampleRate) { sampleRate_ = sampleRate; }
    static double sampleRate() { return sampleRate_; }

    static double midiKeyToFrequency(int key) {
        assert(key >= 0 && key <= MaxMIDINote);
        return standardNoteFrequencies_[key];
    }

    static double centToFrequencyMultiplier(int cent) {
        assert(cent >= -MaxCentValue && cent <= MaxCentValue);
        return centFrequencyMultiplier_[cent + MaxCentValue];
    }

    static double sineLookup(double radians) {
        assert(radians >= 0.0 && radians <= HalfPI);
        double phase = radians * SineLookupTableScale;
        int index = int(phase);
        double frac = phase - index;
        double value = sineLookup_[index] * (1.0 - frac);
        if (frac > 0.0) value += sineLookup_[index + 1] * frac;
        return value;
    }

    static constexpr double sin(double radians) {
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

private:
    static double sampleRate_;

    static std::array<double, MaxMIDINote + 1> standardNoteFrequencies_;
    static std::array<double, MaxCentValue * 2 + 1> centFrequencyMultiplier_;
    static std::array<double, SineLookupTableSize> sineLookup_;
};

}

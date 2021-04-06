// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <cmath>

#include "DSP.hpp"

enum class LFOWaveform { sinusoid, triangle, sawtooth };

/**
 Implementation of a low-frequency oscillator. Can generate:

 - sinusoid
 - triangle
 - sawtooth

 Loosely based on code found in "Designing Audio Effect Plugins in C++" by Will C. Pirkle (2019)
 */
template <typename T>
class LFO {
public:

    /**
     Create a new instance.

     @param sampleRate number of samples per second
     @param frequency the frequency of the oscillator
     @param waveform the waveform to emit
     */
    LFO(T sampleRate, T frequency, LFOWaveform waveform)
    : sampleRate_{sampleRate}, frequency_{frequency}, valueGenerator_{WaveformGenerator(waveform)} {
        reset();
    }

    /**
     Create a new instance.
     */
    LFO(T sampleRate, T frequency) : LFO(sampleRate, frequency, LFOWaveform::sinusoid) {}

    /**
     Create a new instance.
     */
    LFO() : LFO(44100.0, 1.0, LFOWaveform::sinusoid) {}

    /**
     Initialize the LFO with the given parameters.

     @param sampleRate number of samples per second
     @param frequency the frequency of the oscillator
     */
    void initialize(T sampleRate, T frequency) {
        sampleRate_ = sampleRate;
        frequency_ = frequency;
        reset();
    }

    /**
     Set the waveform to use

     @param waveform the waveform to emit
     */
    void setWaveform(LFOWaveform waveform) { valueGenerator_ = WaveformGenerator(waveform); }

    /**
     Set the frequency of the oscillator.

     @param frequency the frequency to operate at
     */
    void setFrequency(T frequency) {
        frequency_ = frequency;
        phaseIncrement_ = frequency_ / sampleRate_;
    }

    /**
     Restart from a known zero state.
     */
    void reset() {
        moduloCounter_ = phaseIncrement_ > 0 ? 0.0 : 1.0;
    }

    /**
     Save the state of the oscillator.

     @returns current internal state
     */
    T saveState() const { return moduloCounter_; }

    /**
     Restore the oscillator to a previously-saved state.

     @param value the state to restore to
     */
    void restoreState(T value) {
        moduloCounter_ = value;
        quadPhaseCounter_ = incrementModuloCounter(value, 0.25);
    }

    /**
     Increment the oscillator to the next value.
     */
    void increment() {
        moduloCounter_ = incrementModuloCounter(moduloCounter_, phaseIncrement_);
        quadPhaseCounter_ = incrementModuloCounter(moduloCounter_, 0.25);
    }

    /**
     Obtain the next value of the oscillator. Advances counter before returning, so this is not idempotent.

     @returns current waveform value
     */
    T valueAndIncrement() {
        auto counter = moduloCounter_;
        quadPhaseCounter_ = incrementModuloCounter(counter, 0.25);
        moduloCounter_ = incrementModuloCounter(counter, phaseIncrement_);
        return valueGenerator_(counter);
    }

    /**
     Obtain the current value of the oscillator.

     @returns current waveform value
     */
    T value() { return valueGenerator_(moduloCounter_); }

    /**
     Obtain the current value of the oscillator that is 90° advanced from what `value()` would return.

     @returns current 90° advanced waveform value
     */
    T quadPhaseValue() const { return valueGenerator_(quadPhaseCounter_); }

private:
    using ValueGenerator = std::function<T(T)>;

    static ValueGenerator WaveformGenerator(LFOWaveform waveform) {
        switch (waveform) {
            case LFOWaveform::sinusoid: return sineValue;
            case LFOWaveform::sawtooth: return sawtoothValue;
            case LFOWaveform::triangle: return triangleValue;
        }
    }

    static T wrappedModuloCounter(T counter, T inc) {
        if (inc > 0 && counter >= 1.0) return counter - 1.0;
        if (inc < 0 && counter <= 0.0) return counter + 1.0;
        return counter;
    }

    static T incrementModuloCounter(T counter, T inc) { return wrappedModuloCounter(counter + inc, inc); }
    static T sineValue(T counter) { return DSP::parabolicSine(M_PI - counter * 2.0 * M_PI); }
    static T sawtoothValue(T counter) { return DSP::unipolarToBipolar(counter); }
    static T triangleValue(T counter) { return DSP::unipolarToBipolar(std::abs(DSP::unipolarToBipolar(counter))); }

    T sampleRate_;
    T frequency_;
    std::function<T(T)> valueGenerator_;
    T moduloCounter_ = {0.0};
    T quadPhaseCounter_ = {0.0};
    T phaseIncrement_;
};

// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include "Render/DSP.hpp"

namespace SF2 {
namespace Render {

enum class LFOWaveform { sinusoid, triangle, sawtooth };

/**
 Implementation of a low-frequency oscillator. Can generate the following waveforms:

 - sinusoid
 - triangle
 - sawtooth

 By design, this LFO emits unipolar values from 0.0 to 1.0 in order to be useful in SF2 processing. One can obtain
 bipolar values via the DSP::unipolarToBipolar method. An LFO will start emitting with value 0.0, again by design, in
 order to smoothly transition from a paused LFO to a running one.
 */
template <typename T>
class LFO {
public:

    /**
     Configures an LFO via a "fluent" interface.
     */
    struct Config {

        /**
         Begin configuration with the sample rate

         @param sampleRate the sample rate to use
         */
        explicit Config(T sampleRate) :
        sampleRate_{sampleRate}, frequency_{1.0}, delay_{0.0}, waveform_{LFOWaveform::triangle} {}

        /**
         Set the frequency for the LFO.

         @param frequency the frequency to run the LFO at
         */
        Config& frequency(T frequency) {
            frequency_ = frequency;
            return *this;
        }

        /**
         Set the delay for the LFO. Until the delay duration passes, the LFO will emit 0.0 values.

         @param delay the number of seconds to wait before starting the LFO.
         */
        Config& delay(T delay) {
            delay_ = delay;
            return *this;
        }

        /**
         Set the waveform type for the LFO to emit.

         @param waveform the waveform to use. Per SF2 spec, LFOs emit triangular waveforms.
         */
        Config& waveform(LFOWaveform waveform) {
            waveform_ = waveform;
            return *this;
        }

        /**
         Create an LFO instance with the configured properties.

         @returns LFO instance
         */
        LFO make() const {
            return LFO(sampleRate_, frequency_, delay_, waveform_);
        }

    private:
        T sampleRate_;
        T frequency_;
        T delay_;
        LFOWaveform waveform_;
    };

    /**
     Create a new instance.

     @param sampleRate number of samples per second
     @param frequency the frequency of the oscillator
     @param waveform the waveform to emit
     */
    LFO(T sampleRate, T frequency, T delay, LFOWaveform waveform) :
    valueGenerator_{WaveformGenerator(waveform)}, init_{WaveformInit(waveform)} {
        initialize(sampleRate, frequency, delay);
    }

    /**
     Create a new instance that generates triangular waveforms. Per spec, SF2 LFOs only generate triangular waveforms.
     */
    LFO(T sampleRate, T frequency, T delay) : LFO(sampleRate, frequency, delay, LFOWaveform::triangle) {}

    /**
     Initialize the LFO with the given parameters.

     @param sampleRate number of samples per second
     @param frequency the frequency of the oscillator
     */
    void initialize(T sampleRate, T frequency, T delay) {
        sampleRate_ = sampleRate;
        frequency_ = frequency;
        delaySampleCount_ = size_t(sampleRate * delay);
        setPhaseIncrement();
        reset();
    }

    /**
     Set the waveform to use

     @param waveform the waveform to emit
     */
    void setWaveform(LFOWaveform waveform) { valueGenerator_ = WaveformGenerator(waveform); }

    /**
     Set the frequency of the oscillator. NOTE: it does *not* reset the counter.

     @param frequency the frequency to operate at
     */
    void setFrequency(T frequency) {
        frequency_ = frequency;
        setPhaseIncrement();
    }

    /**
     Set the delay of the oscillator in seconds. NOTE: resets the counter.

     @param delay the duration before the LFO begins
     */
    void setDelay(T delay) {
        delaySampleCount_ = size_t(delay * sampleRate_);
        reset();
    }

    /**
     Restart from a known zero state.
     */
    void reset() {
        moduloCounter_ = init_;
    }

    struct State {
        T moduloCounter_;
        size_t delaySampleCount_;
        State(T moduloCounter, size_t delaySampleCount) :
        moduloCounter_{moduloCounter}, delaySampleCount_{delaySampleCount} {}
    };

    /**
     Save the state of the oscillator.

     @returns current internal state
     */
    State saveState() const { return State(moduloCounter_, delaySampleCount_); }

    /**
     Restore the oscillator to a previously-saved state.

     @param state the state to restore to
     */
    void restoreState(const State& state) {
        moduloCounter_ = state.moduloCounter_;
        delaySampleCount_ = state.delaySampleCount_;
        quadPhaseCounter_ = incrementModuloCounter(state.moduloCounter_, 0.25);
    }

    /**
     Increment the oscillator to the next value.
     */
    void increment() {
        if (delaySampleCount_ > 0) {
            --delaySampleCount_;
        }
        else {
            moduloCounter_ = incrementModuloCounter(moduloCounter_, phaseIncrement_);
            quadPhaseCounter_ = incrementModuloCounter(moduloCounter_, 0.25);
        }
    }

    /**
     Obtain the next value of the oscillator. Advances counter before returning, so this is not idempotent.

     @returns current waveform value
     */
    T valueAndIncrement() {
        if (delaySampleCount_ > 0) {
            --delaySampleCount_;
            return 0.0;
        }

        auto counter = moduloCounter_;
        quadPhaseCounter_ = incrementModuloCounter(counter, 0.25);
        moduloCounter_ = incrementModuloCounter(counter, phaseIncrement_);
        return valueGenerator_(counter);
    }

    /**
     Obtain the next value of the quad-phase oscillator. Advances counter before returning, so this is not idempotent.

     @returns current waveform value
     */
    T quadPhaseValueAndIncrement() {
        if (delaySampleCount_ > 0) {
            --delaySampleCount_;
            return 0.0;
        }
        auto counter = moduloCounter_;
        quadPhaseCounter_ = incrementModuloCounter(counter, 0.25);
        moduloCounter_ = incrementModuloCounter(counter, phaseIncrement_);
        return valueGenerator_(quadPhaseCounter_);
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
    void setPhaseIncrement() { phaseIncrement_ = frequency_ / sampleRate_; }

    using ValueGenerator = std::function<T(T)>;

    static ValueGenerator WaveformGenerator(LFOWaveform waveform) {
        switch (waveform) {
            case LFOWaveform::sinusoid: return sineValue;
            case LFOWaveform::sawtooth: return sawtoothValue;
            case LFOWaveform::triangle: return triangleValue;
        }
    }

    /**
     For a given waveform type obtain the starting value for moduloCounter_ so that the first value from the generator
     is 0.0 and the subsequent value is a positive value (derivative > 0).

     @param waveform the waveform being generated
     @returns the initial value for moduloCounter_
     */
    static T WaveformInit(LFOWaveform waveform) {
        switch (waveform) {
            case LFOWaveform::sinusoid: return 0.0;
            case LFOWaveform::sawtooth: return 0.0;
            case LFOWaveform::triangle: return 0.5;
        }
    }

    static T wrappedModuloCounter(T counter, T inc) {
        if (inc > 0 && counter >= 1.0) return counter - 1.0;
        if (inc < 0 && counter <= 0.0) return counter + 1.0;
        return counter;
    }

    static T incrementModuloCounter(T counter, T inc) { return wrappedModuloCounter(counter + inc, inc); }
    static T sineValue(T counter) { return DSP::bipolarToUnipolar(DSP::sineLookup(counter * 2.0 * M_PI - M_PI / 2.0)); }
    static T sawtoothValue(T counter) { return counter; }
    static T triangleValue(T counter) { return std::abs(DSP::unipolarToBipolar(counter)); }

    T sampleRate_;
    T frequency_;
    std::function<T(T)> valueGenerator_;
    T init_{0.0};
    T moduloCounter_{0.0};
    T quadPhaseCounter_{0.0};
    T phaseIncrement_;
    size_t delaySampleCount_;
};

} // namespace Render
} // namespace SF2

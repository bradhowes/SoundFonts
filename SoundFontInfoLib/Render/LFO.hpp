// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include "Render/DSP.hpp"

namespace SF2 {
namespace Render {

/**
 Implementation of a low-frequency triangular oscillator. By design, this LFO emits bipolar values from -1.0 to 1.0 in
 order to be useful in SF2 processing. One can obtain unipolar values via the DSP::bipolarToUnipolar method. An LFO
 will start emitting with value 0.0, again by design, in order to smoothly transition from a paused LFO into a running
 one.
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
        explicit Config(T sampleRate) : sampleRate_{sampleRate}, frequency_{1.0}, delay_{0.0} {}

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
         Create an LFO instance with the configured properties.

         @returns LFO instance
         */
        LFO make() const {
            return LFO(sampleRate_, frequency_, delay_);
        }

    private:
        T sampleRate_;
        T frequency_;
        T delay_;
    };

    /**
     Create a new instance.

     @param sampleRate number of samples per second
     @param frequency the frequency of the oscillator
     */
    LFO(T sampleRate, T frequency, T delay) { initialize(sampleRate, frequency, delay); }

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
        counter_ = 0.0;
        if (increment_ < 0) increment_ = -increment_;
    }

    struct State {
        T counter_;
        size_t delaySampleCount_;
        State(T counter, size_t delaySampleCount) : counter_{counter}, delaySampleCount_{delaySampleCount} {}
    };

    /**
     Save the state of the oscillator.

     @returns current internal state
     */
    State saveState() const { return State(counter_, delaySampleCount_); }

    /**
     Restore the oscillator to a previously-saved state.

     @param state the state to restore to
     */
    void restoreState(const State& state) {
        counter_ = state.counter_;
        delaySampleCount_ = state.delaySampleCount_;
    }

    /**
     Increment the oscillator to the next value.
     */
    void increment() {
        if (delaySampleCount_ > 0) {
            --delaySampleCount_;
        }
        else {
            counter_ += increment_;
            if (counter_ >= 1.0) {
                increment_ = -increment_;
                counter_ = 2.0 - counter_;
            }
            else if (counter_ <= -1.0) {
                increment_ = -increment_;
                counter_ = -2.0 - counter_;
            }
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

        auto counter = counter_;
        increment();
        return counter;
    }

    /**
     Obtain the current value of the oscillator.

     @returns current waveform value
     */
    T value() { return counter_; }

private:

    void setPhaseIncrement() { increment_ = frequency_ / sampleRate_ * 4.0; }

    T sampleRate_;
    T frequency_;
    T counter_{0.0};
    T increment_;
    size_t delaySampleCount_;
};

} // namespace Render
} // namespace SF2

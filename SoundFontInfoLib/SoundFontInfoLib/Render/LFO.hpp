// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <cmath>

#include "Types.hpp"
#include "DSP/DSP.hpp"

namespace SF2::Render {

/**
 Implementation of a low-frequency triangular oscillator. By design, this LFO emits bipolar values from -1.0 to 1.0 in
 order to be useful in SF2 processing. One can obtain unipolar values via the DSP::bipolarToUnipolar method. An LFO
 will start emitting with value 0.0, again by design, in order to smoothly transition from a paused LFO into a running
 one. An LFO can be configured to delay oscillating for N samples. During that time it will emit 0.0.
 */
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
    explicit Config(Float sampleRate) : sampleRate_{sampleRate}, frequency_{1.0}, delay_{0.0} {}

    /**
     Set the frequency for the LFO.

     @param frequency the frequency to run the LFO at
     */
    Config& frequency(Float frequency) {
      frequency_ = frequency;
      return *this;
    }

    /**
     Set the delay for the LFO. Until the delay duration passes, the LFO will emit 0.0 values.

     @param delay the number of seconds to wait before starting the LFO.
     */
    Config& delay(Float delay) {
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
    Float sampleRate_;
    Float frequency_;
    Float delay_;
  };

  /**
   Create a new instance.

   @param sampleRate number of samples per second
   @param frequency the frequency of the oscillator
   @param delay the number of seconds to wait before starting the LFO.
   */
  LFO(Float sampleRate, Float frequency, Float delay) { initialize(sampleRate, frequency, delay); }

  /**
   Initialize the LFO with the given parameters.

   @param sampleRate number of samples per second
   @param frequency the frequency of the oscillator
   @param delay the number of seconds to wait before starting the LFO.
   */
  void initialize(Float sampleRate, Float frequency, Float delay) {
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
  void setFrequency(Float frequency) {
    frequency_ = frequency;
    setPhaseIncrement();
  }

  /**
   Set the delay of the oscillator in seconds. NOTE: resets the counter.

   @param delay the number of seconds to wait before starting the LFO.
   */
  void setDelay(Float delay) {
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
    Float counter_;
    size_t delaySampleCount_;
    State(Float counter, size_t delaySampleCount) : counter_{counter}, delaySampleCount_{delaySampleCount} {}
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
   Obtain the next value of the oscillator. Advances counter before returning, so this is not idempotent.

   @returns current waveform value
   */
  Float valueAndIncrement() {
    auto counter = counter_;
    increment();
    return counter;
  }

  /**
   Obtain the current value of the oscillator.

   @returns current waveform value
   */
  Float value() { return counter_; }

private:

  void setPhaseIncrement() { increment_ = frequency_ / sampleRate_ * 4.0; }

  void increment() {
    if (delaySampleCount_ > 0) {
      --delaySampleCount_;
      return;
    }

    counter_ += increment_;

    // For triangle waveform, the increment is the slope, so to just negate current value when changing directions.
    if (counter_ >= 1.0) {
      increment_ = -increment_;
      counter_ = 2.0 - counter_;
    }
    else if (counter_ <= -1.0) {
      increment_ = -increment_;
      counter_ = -2.0 - counter_;
    }
  }

  Float sampleRate_;
  Float frequency_;
  Float counter_{0.0};
  Float increment_;
  size_t delaySampleCount_;
};

} // namespace SF2::Render

// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <array>
#include <cassert>
#include <cmath>

#include "Types.hpp"
#include "Render/MIDI/MIDI.hpp"

namespace SF2 {
namespace Render {
namespace MIDI {

/**
 Collection of state values that pertains to a specific MIDI channel.
 */
class Channel {
public:
    using ContinuousControllerValues = std::array<int, MaxNote + 1>;
    using KeyPressureValues = std::array<int, MaxNote + 1>;

    /**
     Construct new channel.
     */
    Channel() : continuousControllerValues_{}, keyPressureValues_{} {
        continuousControllerValues_.fill(0);
        keyPressureValues_.fill(0);
    }

    /**
     Set the pressure for a given key.

     @param key the key to set
     @param value the pressure value to record
     */
    void setKeyPressure(int key, int value) {
        assert(key <= MaxNote);
        keyPressureValues_[key] = value;
    }

    /**
     Get the pressure for a given key.

     @param key the key to get
     @returns the current pressure value for a key
     */
    int keyPressure(int key) const {
        assert(key <= MaxNote);
        return keyPressureValues_[key];
    }

    /**
     Set the channel pressure.

     @param value the pressure value to record
     */
    void setChannelPressure(int value) { channelPressure_ = value; }

    /// @returns the current channel pressure
    int channelPressure() const { return channelPressure_; }

    /**
     Set the pitch wheel value

     @param value the pitch wheel value
     */
    void setPitchWheelValue(int value) { pitchWheelValue_ = value; }

    /// @returns the current pitch wheel value
    int pitchWheelValue() const { return pitchWheelValue_; }

    /**
     Set the pitch wheel sensitivity value

     @param value the sensitivity value to record
     */
    void setPitchWheelSensitivity(int value) { pitchWheelSensitivity_ = value; }

    /// @returns the current pitch wheel sensitivity value
    int pitchWheelSensitivity() const { return pitchWheelSensitivity_; }

    /**
     Set a continuous controller value

     @param id the controller ID
     @param value the value to set for the controller
     */
    void setContinuousControllerValue(int id, int value) {
        assert(id <= MaxNote);
        continuousControllerValues_[id] = value;
    }

    /**
     Get a continuous controller value.

     @param id the controller ID to get
     @returns the controller value
     */
    int continuousControllerValue(int id) const {
        assert(id <= MaxNote);
        return continuousControllerValues_[id];
    }

private:
    ContinuousControllerValues continuousControllerValues_;
    KeyPressureValues keyPressureValues_;
    int channelPressure_{0};
    int pitchWheelValue_{0};
    int pitchWheelSensitivity_{200};
};

} // namespace MIDI
} // namespace Render
} // namespace SF2

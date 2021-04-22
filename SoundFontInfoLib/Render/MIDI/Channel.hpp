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

struct Channel {
    using ContinuousControllerValues = std::array<int, MaxNote + 1>;
    using KeyPressureValues = std::array<int, MaxNote + 1>;

    Channel() : continuousControllerValues_{}, keyPressureValues_{} {
        continuousControllerValues_.fill(0);
        keyPressureValues_.fill(0);
    }

    int keyPressure(int key) const {
        assert(key <= MaxNote);
        return keyPressureValues_[key];
    }

    void setKeyPressure(int key, int value) {
        assert(key <= MaxNote);
        keyPressureValues_[key] = value;
    }

    int channelPressure() const { return channelPressure_; }
    void setChannelPressure(int value) { channelPressure_ = value; }

    int pitchWheelValue() const { return pitchWheelValue_; }
    void setPitchWheelValue(int value) { pitchWheelValue_ = value; }

    int pitchWheelSensitivity() const { return pitchWheelSensitivity_; }
    void setPitchWheelSensitivity(int value) { pitchWheelSensitivity_ = value; }

    int continuousControllerValue(int id) const {
        assert(id <= MaxNote);
        return continuousControllerValues_[id];
    }

    void setContinuousControllerValue(int id, int value) {
        assert(id <= MaxNote);
        continuousControllerValues_[id] = value;
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

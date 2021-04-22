// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cassert>
#include <cmath>
#include <functional>
#include <limits>

#include "Render/Transform.hpp"

namespace SF2 {

namespace Entity::Modulator { class Modulator; }

namespace Render {

namespace MIDI { class Channel; }
namespace Voice { class State; }

/**
 Render-side modulator that understands how to fetch source values that will be used to modulate voice state. Per the
 SF2 spec, a modulator does the following:

 - takes a source value (Sv) (eg from a MIDI controller) and transforms it into a unipolar or bipolar value
 - takes an 'amount' source value (Av) and transforms it into a unipolar or bipolar value
 - calculates and returns Sv * Av * amount (from SF2 Entity::Modulator)

 The Sv and Av transformations are done in the Transform class.

 The Modulator instances operate in a 'pull' fashion: a call to their `value()` method fetches source values, which may
 themselves be modulator instances. In this way, the `value()` method will always return the most up-to-date values.
 */
class Modulator {
public:

    /**
     Construct new modulator

     @param index the index of the entity in the instrument zone (presets do not have or define modulators)
     @param configuration the entity configuration that defines the modulator
     @param state the voice state that can be used as a source for modulators
     */
    Modulator(size_t index, const Entity::Modulator::Modulator& configuration, const Voice::State& state);

    /// @returns current value of the modulator
    double value() const;

    /// @returns configuration of the modulator from the SF2 file
    const Entity::Modulator::Modulator& configuration() const { return configuration_; }

    /// @returns index offset for the modulator
    size_t index() const { return index_; }

    void flagInvalid() { index_ = std::numeric_limits<size_t>::max(); }

    bool isValid() const { return index_ != std::numeric_limits<size_t>::max(); }

    /**
     Resolve the linking between two modulators. Configures this modulator to invoke the `value()` method of another.
     */
    void setSource(const Modulator& modulator) {
        sourceValue_ = [&]() { return int(std::round(modulator.value())); };
    }

private:
    static std::function<int()> SourceValue(const Entity::Modulator::Modulator& configuration,
                                            const Voice::State& state, int noneValue);

    const Entity::Modulator::Modulator& configuration_;
    size_t index_;

    Transform sourceTransform_;
    Transform amountTransform_;

    std::function<int()> sourceValue_;
    std::function<int()> amountValue_;
};

} // namespace Render
} // namespace SF2

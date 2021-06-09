// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cassert>
#include <cmath>
#include <functional>
#include <limits>

#include "Logger.hpp"
#include "MIDI/ValueTransformer.hpp"

namespace SF2::Entity::Modulator { class Modulator; class Source; }

namespace SF2::MIDI { class Channel; }

namespace SF2::Render {

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

   @param index the index of the entity in the zone
   @param configuration the entity configuration that defines the modulator
   @param state the voice state that can be used as a source for modulators
   */
  Modulator(size_t index, const Entity::Modulator::Modulator& configuration, const Voice::State& state);

  /// @returns current value of the modulator
  double value() const {
    assert(isValid());
    // log_.debug() << "evaluating " << description() << std::endl;

    // If there is no source for the modulator, it always returns 0.0 (no modulation).
    if (sourceValue_ == nullptr) return 0.0;

    // Obtain transformed value from source.
    double value = sourceTransform_.value(sourceValue_());
    if (value == 0.0) return 0.0;

    // If there is a source for the scaling factor, apply its transformed value.
    if (amountScale_ != nullptr) value *= amountTransform_.value(amountScale_());

    return value * amount_;
  }

  /// @returns configuration of the modulator from the SF2 file
  const Entity::Modulator::Modulator& configuration() const { return configuration_; }

  /// @returns index offset for the modulator
  size_t index() const { return index_; }

  void flagInvalid() { index_ = std::numeric_limits<size_t>::max(); }

  bool isValid() const { return index_ != std::numeric_limits<size_t>::max(); }

  /**
   Resolve the linking between two modulators. Configures this modulator to invoke the `value()` method of another to
   obtain an Sv value. Per spec, linking is NOT allowed for Av values. Also per spec, source values fall in range
   0-127 and are transformed into unipolar or bipolar ranges depending on their definition. This makes linking a bit
   strange: the 'source' modulator generates a unipolar or bipolar value per its definition, but unipolar is only
   useful in the linked case, and its `amount` must be 127 or 128 in order to get back a value that is reasonable to
   use as a source value for another modulator.

   @param modulator provider for an Sv to use for this modulator
   */
  void setSource(const Modulator& modulator) { sourceValue_ = [&]() { return int(std::round(modulator.value())); }; }

  std::string description() const;

private:
  using ValueProc = std::function<int()>;

  /**
   Obtain a generic callable entity that returns a integral value. This is used to obtain both the Sv and Av values,
   regardless of their sources.

   @param source the modulator source definition from the SF2 file
   @param state the voice state that will be modulated
   */
  static ValueProc SourceValue(const Entity::Modulator::Source& source, const Voice::State& state);

  const Entity::Modulator::Modulator& configuration_;
  size_t index_;
  int amount_;
  MIDI::ValueTransformer sourceTransform_;
  MIDI::ValueTransformer amountTransform_;

  ValueProc sourceValue_;
  ValueProc amountScale_;

  inline static Logger log_{Logger::Make("Render.Voice", "Modulator")};
};

} // namespace SF2::Render

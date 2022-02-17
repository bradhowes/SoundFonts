#pragma once

#include <optional>

#include "Render/PresetZone.hpp"
#include "Render/InstrumentZone.hpp"
#include "Render/NormalizedSampleSource.hpp"

namespace SF2::Render {

class State;

/**
 A combination of preset zone and instrument zone (plus optional global zones for each) that pertains to a MIDI
 key/velocity pair. One instance represents the configuration that should apply to the state of one voice for rendering
 samples at a specific key frequency and velocity.
 */
class Config {
public:

  /**
   Construct a preset/instrument pair

   @param presetZone the PresetZone that matched a key/velocity search
   @param globalPresetZone the global PresetZone to apply (optional -- nullptr if no global)
   @param instrumentZone the InstrumentZone that matched a key/velocity search
   @param globalInstrumentZone the global InstrumentZone to apply (optional -- nullptr if no global)
   @param key the MIDI key that triggered the rendering
   @param velocity the MIDI velocity that triggered the rendering
   */
  Config(const PresetZone& presetZone, GlobalPresetZone globalPresetZone,
         const InstrumentZone& instrumentZone, GlobalInstrumentZone globalInstrumentZone, int key, int velocity) :
  presetZone_{presetZone}, globalPresetZone_{globalPresetZone},
  instrumentZone_{instrumentZone}, globalInstrumentZone_{globalInstrumentZone}, key_{key}, velocity_{velocity}
  {}

  /// @returns the buffer of audio samples to use for rendering
  const NormalizedSampleSource& sampleSource() const {
    assert(instrumentZone_.sampleSource() != nullptr);
    return *(instrumentZone_.sampleSource());
  }

  /// @returns original MIDI key that triggered the voice
  int key() const { return key_; }

  /// @returns original MIDI velocity that triggered the voice
  int velocity() const { return velocity_; }

private:

  /// Grant access to `apply`.
  friend State;
  
  /**
   Update a state with the various zone configurations. This is done once during the initialization of a Voice with a
   Config instance.

   @param state the voice state to update
   */
  void apply(State& state) const {

    // Instrument zones first to set absolute values. Do the global state first, then allow instruments to change
    // their settings.
    if (globalInstrumentZone_) globalInstrumentZone_.value()->apply(state);
    instrumentZone_.apply(state);

    // Presets apply refinements to absolute values set from instruments zones above.
    if (globalPresetZone_) globalPresetZone_.value()->refine(state);
    presetZone_.refine(state);
  }

  const PresetZone& presetZone_;
  const GlobalPresetZone globalPresetZone_;
  const InstrumentZone& instrumentZone_;
  const GlobalInstrumentZone globalInstrumentZone_;
  int key_;
  int velocity_;
};

} // namespace SF2::Render

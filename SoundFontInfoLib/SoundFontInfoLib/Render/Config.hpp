#pragma once

#include <optional>

#include "Render/Zones/Preset.hpp"
#include "Render/Zones/Instrument.hpp"
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

   @param preset the PresetZone that matched a key/velocity search
   @param globalPreset the global PresetZone to apply (optional -- nullptr if no global)
   @param instrument the InstrumentZone that matched a key/velocity search
   @param globalInstrument the global InstrumentZone to apply (optional -- nullptr if no global)
   @param key the MIDI key that triggered the rendering
   @param velocity the MIDI velocity that triggered the rendering
   */
  Config(const Zones::Preset& preset, const Zones::Preset* globalPreset,
         const Zones::Instrument& instrument, const Zones::Instrument* globalInstrument, int key, int velocity) :
  preset_{preset}, globalPreset_{globalPreset},
  instrument_{instrument}, globalInstrument_{globalInstrument}, key_{key}, velocity_{velocity}
  {}

  /// @returns the buffer of audio samples to use for rendering
  const NormalizedSampleSource& sampleSource() const { return instrument_.sampleSource(); }

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
    if (globalInstrument_ != nullptr) globalInstrument_->apply(state);
    instrument_.apply(state);

    // Presets apply refinements to absolute values set from instruments zones above.
    if (globalPreset_ != nullptr) globalPreset_->refine(state);
    preset_.refine(state);
  }

  const Zones::Preset& preset_;
  const Zones::Preset* globalPreset_;
  const Zones::Instrument& instrument_;
  const Zones::Instrument* globalInstrument_;
  int key_;
  int velocity_;
};

} // namespace SF2::Render

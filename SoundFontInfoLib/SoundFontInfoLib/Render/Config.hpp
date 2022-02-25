#pragma once

#include <optional>

#include "Render/Zone/Preset.hpp"
#include "Render/Zone/Instrument.hpp"
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
   @param eventKey the MIDI key that triggered the rendering
   @param eventVelocity the MIDI velocity that triggered the rendering
   */
  Config(const Zone::Preset& preset, const Zone::Preset* globalPreset, const Zone::Instrument& instrument,
         const Zone::Instrument* globalInstrument, int eventKey, int eventVelocity) :
  preset_{preset}, globalPreset_{globalPreset},
  instrument_{instrument}, globalInstrument_{globalInstrument}, eventKey_{eventKey}, eventVelocity_{eventVelocity}
  {}

  /// @returns the buffer of audio samples to use for rendering
  const NormalizedSampleSource& sampleSource() const { return instrument_.sampleSource(); }

  /// @returns original MIDI key that triggered the voice
  int eventKey() const { return eventKey_; }

  /// @returns original MIDI velocity that triggered the voice
  int eventVelocity() const { return eventVelocity_; }

private:

  /// Grant access to `apply`.
  friend State;
  
  /**
   Update a state with the various zone configurations. This is done once during the initialization of a Voice with a
   Config instance.

   @param state the voice state to update
   */
  void apply(State& state) const {

    // Use Instrument zones to set absolute values. Do the global state first, then allow instruments to change
    // their settings.
    if (globalInstrument_ != nullptr) globalInstrument_->apply(state);
    instrument_.apply(state);

    // Presets apply refinements to absolute values set from instruments zones above.
    if (globalPreset_ != nullptr) globalPreset_->refine(state);
    preset_.refine(state);
  }

  const Zone::Preset& preset_;
  const Zone::Preset* globalPreset_;
  const Zone::Instrument& instrument_;
  const Zone::Instrument* globalInstrument_;
  int eventKey_;
  int eventVelocity_;
};

} // namespace SF2::Render

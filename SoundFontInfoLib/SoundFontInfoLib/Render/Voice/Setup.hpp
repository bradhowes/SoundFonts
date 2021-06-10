#pragma once

#include <optional>

#include "Render/PresetZone.hpp"
#include "Render/InstrumentZone.hpp"
#include "Render/Sample/CanonicalBuffer.hpp"

namespace SF2::Render::Voice {

class State;

/**
 A combination of preset zone and instrument zone (plus optional global zones for each) that pertains to a MIDI
 key/velocity pair. One instance represents the configuration that should apply to the state of one voice for rendering
 samples.
 */
class Setup {
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
  Setup(const PresetZone& presetZone, GlobalPresetZone globalPresetZone, const InstrumentZone& instrumentZone,
        GlobalInstrumentZone globalInstrumentZone, int key, int velocity) :
  presetZone_{presetZone}, globalPresetZone_{globalPresetZone}, instrumentZone_{instrumentZone},
  globalInstrumentZone_{globalInstrumentZone}, key_{key}, velocity_{velocity} {}

  /**
   Update a state with the various zone configurations. This is to be done just once during the start of a voice playing
   a note.

   @param state the voice state to update
   */
  void apply(State& state) const {

    // Instrument zones first to set absolute values. Do the global state first, then allow instruments to change
    // their settings.
    if (globalInstrumentZone_) globalInstrumentZone_.value()->apply(state);
    instrumentZone_.apply(state);

    // According to spec, a preset global should only be applied iff there is NOT a preset generator.
    if (globalPresetZone_) globalPresetZone_.value()->refine(state);
    presetZone_.refine(state);
  }

  /// @returns the buffer of audio samples to use for rendering
  const Sample::CanonicalBuffer& sampleBuffer() const {
    assert(instrumentZone_.sampleBuffer() != nullptr);
    return *(instrumentZone_.sampleBuffer());
  }

  /// @returns original MIDI key that triggered the voice
  int key() const { return key_; }

  /// @returns original MIDI velocity that triggered the voice
  int velocity() const { return velocity_; }

private:
  const PresetZone& presetZone_;
  const GlobalPresetZone globalPresetZone_;
  const InstrumentZone& instrumentZone_;
  const GlobalInstrumentZone globalInstrumentZone_;
  int key_;
  int velocity_;
};

} // namespace SF2::Render::Voice


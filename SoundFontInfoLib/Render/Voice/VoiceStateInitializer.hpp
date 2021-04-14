#pragma once

#include "Render/PresetZone.hpp"
#include "Render/InstrumentZone.hpp"
#include "Render/SampleBuffer.hpp"

namespace SF2 {
namespace Render {

/**
 A combination of preset zone and instrument zone (plus optional global zones for each). One zone pair represents
 the configuration that should apply to the state of one voice.
 */
class VoiceStateInitializer {
public:

    /**
     Construct a preset/instrument pair

     @param presetZone the PresetZone that matched a key/velocity search
     @param presetGlobal the global PresetZone to apply (optional -- nullptr if no global)
     @param instrumentZone the InstrumentZone that matched a key/velocity search
     @param instrumentGlobal the global InstrumentZone to apply (optional -- nullptr if no global)
     */
    VoiceStateInitializer(const PresetZone& presetZone, const PresetZone* presetGlobal,
                          const InstrumentZone& instrumentZone, const InstrumentZone* instrumentGlobal,
                          UByte key, UByte velocity) :
    presetZone_{presetZone}, presetGlobal_{presetGlobal}, instrumentZone_{instrumentZone},
    instrumentGlobal_{instrumentGlobal}, key_{key}, velocity_{velocity} {}

    /**
     Update a VoiceState with the various zone configurations.

     @param state the VoiceState to update
     */
    void apply(VoiceState& state) const {

        // Instrument zones first to set absolute values
        if (instrumentGlobal_ != nullptr) instrumentGlobal_->apply(state);
        instrumentZone_.apply(state);

        // Preset values to refine those from instrument
        if (presetGlobal_ != nullptr) presetGlobal_->refine(state);
        presetZone_.refine(state);
    }

    const Render::SampleBuffer<AUValue>& sampleBuffer() const {
        assert(instrumentZone_.sampleBuffer() != nullptr);
        return *(instrumentZone_.sampleBuffer());
    }

    UByte key() const { return key_; }
    UByte velocity() const { return velocity_; }

private:
    const PresetZone& presetZone_;
    const PresetZone* presetGlobal_;
    const InstrumentZone& instrumentZone_;
    const InstrumentZone* instrumentGlobal_;
    UByte key_;
    UByte velocity_;
};

} // namespace Render
} // namespace SF2


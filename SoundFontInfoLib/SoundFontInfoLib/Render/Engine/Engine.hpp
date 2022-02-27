// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <functional>
#include <map>
#include <memory>
#include <queue>
#include <set>
#include <vector>

#include "Types.hpp"
#include "Render/Engine/OldestActiveVoiceCache.hpp"
#include "Render/Engine/PresetCollection.hpp"
#include "Render/Engine/EventProcessor.hpp"
#include "Render/Voice/Voice.hpp"

namespace SF2::IO { class File; }

namespace SF2::Render::Engine {

/**
 Engine that generates audio from SF2 files due to incoming MIDI signals. Maintains a collection of voices sized by the
 sole template parameter. A Voice generates samples based on the configuration it is given from a Preset.
 */
template <size_t VoiceCount>
class Engine : public EventProcessor<Engine<VoiceCount>> {
  using super = EventProcessor<Engine>;
  friend super;

public:
  static constexpr size_t maxVoiceCount = VoiceCount;
  using Config = Voice::State::Config;
  using Voice = Voice::Voice;

  /**
   Construct new engine and its voices.

   @param sampleRate the expected sample rate to use
   */
  Engine(Float sampleRate) : super(os_log_create("SoundFonts", "Engine")),
  sampleRate_{sampleRate}, oldestActive_{maxVoiceCount}
  {
    available_.reserve(maxVoiceCount);
    voices_.reserve(maxVoiceCount);
    for (size_t voiceIndex = 0; voiceIndex < maxVoiceCount; ++voiceIndex) {
      voices_.emplace_back(sampleRate, channel_, voiceIndex);
      available_.push_back(voiceIndex);
    }
  }

  /**
   Update kernel and buffers to support the given format and channel count

   @param format the audio format to render
   @param maxFramesToRender the maximum number of samples we will be asked to render in one go
   */
  void setRenderingFormat(AVAudioFormat* format, AUAudioFrameCount maxFramesToRender) {
    super::setRenderingFormat(format, maxFramesToRender);
    initialize(format.channelCount, format.sampleRate);
  }

  /// Obtain the current sample rate
  Float sampleRate() const { return sampleRate_; }

  /// Obtain the MIDI channel assigned to the engine.
  MIDI::Channel channel() const { return channel_; }

  /**
   Load the presets from an SF2 file.

   @param file the file to load from
   */
  void load(const IO::File& file) { presets_.build(file); }

  /// @returns number of presets available.
  size_t presetCount() const { return presets_.size(); }

  /**
   Activate the preset at the given index.

   @param index the preset to use
   */
  void usePreset(size_t index) {
    if (index >= presets_.size()) throw std::runtime_error("invalid preset index");
    activePreset_ = index;
  }

  /// @return the number of active voices
  size_t activeVoiceCount() const { return oldestActive_.size(); }

  /**
   Turn off all voices, making them all available for rendering.
   */
  void allOff()
  {
    while (!oldestActive_.empty()) {
      auto voiceIndex = oldestActive_.takeOldest();
      std::cout << "voice " << voiceIndex << " available\n";
      available_.push_back(voiceIndex);
    }
  }

  /**
   Tell any voices playing the current MIDI key that the key has been released. The voice will continue to render until
   it figures out that it is done.

   @param key the MIDI key that was released
   */
  void noteOff(int key)
  {
    for (auto voiceIndex : oldestActive_) {
      const auto& voice{voices_[voiceIndex]};
      if (!voice.isActive()) {
        oldestActive_.remove(voiceIndex);
        available_.push_back(voiceIndex);
      }
      else if (voices_[voiceIndex].key() == key) {
        voices_[voiceIndex].releaseKey();
      }
    }
  }

  /**
   Activate one or more voices to play a MIDI key with the given velocity.

   @param key the MIDI key to play
   @param velocity the MIDI velocity to play at
   */
  void noteOn(int key, int velocity)
  {
    if (activePreset_ >= presets_.size()) return;
    for (const Config& config : presets_[activePreset_].find(key, velocity)) {
      startVoice(config);
    }
  }

  /**
   Render samples to the given stereo output buffers. The buffers are guaranteed to be able to hold `frameCount`
   samples, and `frameCount` will never be more than the `maxFramesToRender` value given to the `setRenderingFormat`.

   @param left pointer to buffer for left channel audio samples
   @param right pointer to buffer for right channel audio samples
   @param frameCount number of samples to render.
   */
  void render(AUValue* left, AUValue* right, AUAudioFrameCount frameCount)
  {
    std::fill(left, left + frameCount, 0.0);
    std::fill(right, right + frameCount, 0.0);
    for (auto voiceIndex : oldestActive_) {
      voices_[voiceIndex].renderIntoByAdding(left, right, frameCount);
      if (!voices_[voiceIndex].isActive()) {
        oldestActive_.remove(voiceIndex);
        available_.push_back(voiceIndex);
      }
    }
  }

private:

  void initialize(int channelCount, double sampleRate) {
    sampleRate_ = sampleRate;
    allOff();
    for (auto& voice : voices_) {
      voice.setSampleRate(sampleRate);
    }
  }

  /// API for EventProcessor
  void setParameterFromEvent(const AUParameterEvent& event) {}

  /// API for EventProcessor
  void doMIDIEvent(const AUMIDIEvent& midiEvent) {}

  /// API for EventProcessor
  void doRendering(std::vector<AUValue*>& ins, std::vector<AUValue*>& outs, AUAudioFrameCount frameCount)
  {
    assert(outs.size() == 2);
    render(outs[0], outs[1], frameCount);
  }

  size_t selectVoice(int key)
  {
    size_t found = voices_.size();

    if (!available_.empty()) {
      found = available_.back();
      available_.pop_back();
    }
    else if (!oldestActive_.empty()){
      found = oldestActive_.takeOldest();
    }

    return found;
  }

  void startVoice(const Config& config)
  {
    size_t index = selectVoice(config.eventKey());
    if (index == voices_.size()) return;
    Voice& voice{voices_[index]};
    voice.configure(config);
    oldestActive_.add(index);
  }

  Float sampleRate_;
  MIDI::Channel channel_{};
  std::vector<Voice> voices_{};
  std::vector<size_t> available_{};
  OldestActiveVoiceCache oldestActive_;

  PresetCollection presets_{};
  size_t activePreset_{0};
};

} // end namespace SF2::Render

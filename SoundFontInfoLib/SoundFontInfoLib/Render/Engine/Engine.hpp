// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <functional>
#include <map>
#include <memory>
#include <queue>
#include <set>
#include <vector>

#include "Render/Engine/OldestActiveVoiceCache.hpp"
#include "Render/Engine/PresetCollection.hpp"
#include "Render/Engine/Tick.hpp"
#include "Render/Voice/Voice.hpp"

namespace SF2::IO { class File; }

namespace SF2::Render::Engine {

class Engine
{
public:
  using Config = SF2::Render::Config;
  using Voice = SF2::Render::Voice::Voice;

  Engine(Float sampleRate, size_t maxVoiceCount);

  void load(const IO::File& file);

  size_t maxVoiceCount() const { return voices_.size(); }
  size_t activeVoiceCount() const { return voices_.size(); }
  size_t presetCount() const { return presets_.size(); }

  void usePreset(size_t index) {
    if (index >= presets_.size()) throw std::runtime_error("invalid preset index");
    activePreset_ = index;
  }

  Tick tick() { return tick_++; }

  void noteOn(int key, int velocity);
  void noteOff(int key);

  bool oneVoicePerKey() const { return false; }

private:

  void startVoice(const Config& config);

  size_t selectVoice(int key);

  Float sampleRate_;
  Tick tick_{0};

  MIDI::Channel channel_{};
  std::vector<Voice> voices_{};
  std::vector<size_t> available_{};
  std::array<Voice*, 256> activeKeys_{};
  OldestActiveVoiceCache oldestActive_;

  PresetCollection presets_{};
  size_t activePreset_{0};
};

} // end namespace SF2::Render

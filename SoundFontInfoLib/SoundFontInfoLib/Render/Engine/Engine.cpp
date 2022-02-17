#include "Render/Engine/Engine.hpp"

using namespace SF2::Render::Engine;

Engine::Engine(double sampleRate, size_t maxVoiceCount)
: sampleRate_{sampleRate}, oldestActive_{maxVoiceCount}
{
  available_.reserve(maxVoiceCount);
  voices_.reserve(maxVoiceCount);
  while (voices_.size() < maxVoiceCount) {
    auto voiceIndex = voices_.size();
    voices_.emplace_back(sampleRate, channel_, voiceIndex);
    available_.push_back(voiceIndex);
  }


}

void
Engine::load(const IO::File& file)
{
  presets_.build(file);
}

void
Engine::noteOn(int key, int velocity)
{
  if (activePreset_ >= presets_.size()) return;
  for (const Config& config : presets_[activePreset_].find(key, velocity)) {
    startVoice(config);
  }
}

void
Engine::startVoice(const Config& config)
{
  size_t index = selectVoice(config.key());
}

size_t
Engine::selectVoice(int key)
{
  size_t found = voices_.size();

  if (oneVoicePerKey() && activeKeys_[size_t(key)] != nullptr) {
    found = activeKeys_[size_t(key)]->voiceIndex();
  }
  else if (!available_.empty()) {
    found = available_.back();
    available_.pop_back();
  }
  else {
    // Steal oldest note.
    found = oldestActive_.takeOldest();
  }

  
  return found;
}

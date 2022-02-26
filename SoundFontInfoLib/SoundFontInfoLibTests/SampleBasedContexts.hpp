// Copyright © 2021 Brad Howes. All rights reserved.
//

#pragma once

#import <memory>

#import <XCTest/XCTest.h>

#import "IO/File.hpp"
#import "Render/Preset.hpp"
#import "Render/Voice/State/State.hpp"

struct PresetTestContextBase
{
  inline static SF2::Float epsilon = 1.0e-8;
  static NSURL* getUrl(int urlIndex);
};

/**
 Test harness for working with presets in SF2 files. Lazily creates test contexts. The template parameter UrlIndex is
 an integer index into `SF2Files.allResources` which is a list of SF2 files that are available to read.
 */
template <int UrlIndex>
struct PresetTestContext : PresetTestContextBase
{
  PresetTestContext(int presetIndex = 0, SF2::Float sampleRate = 44100.0) :
  sampleRate_{sampleRate}, presetIndex_{presetIndex}
  {}

  /// @return URL path to the SF2 file
  const NSURL* url() const { return getUrl(UrlIndex); }

  /// @return open file descriptor to the SF2 file
  int fd() const { return ::open(url().path.UTF8String, O_RDONLY); }

  /// @return reference to File that loaded the SF2 file.
  const SF2::IO::File& file() const { return state()->file_; }

  /// @return reference to Preset from SF2 file.
  const SF2::Render::Preset& preset() const { return state()->preset_; }

  SF2::Render::Voice::State::State makeState(const SF2::Render::Voice::State::Config& config) const {
    SF2::Render::Voice::State::State state(sampleRate_, channel_);
    state.prepareForVoice(config);
    return state;
  }

  SF2::Render::Voice::State::State makeState(int key, int velocity) const {
    auto found = state()->preset_.find(key, velocity);
    return makeState(found[0]);
  }

  SF2::MIDI::Channel& channel() { return channel_; }

  static void SamplesEqual(SF2::Float a, SF2::Float b) {
    XCTAssertEqualWithAccuracy(a, b, epsilon);
  }

private:

  struct State {
    SF2::IO::File file_;
    SF2::Render::InstrumentCollection instruments_;
    SF2::Render::Preset preset_;
    State(const char* path, size_t presetIndex)
    : file_{path}, instruments_{file_}, preset_{file_, instruments_, file_.presets()[presetIndex]} {}
  };

  State* state() const {
    if (!state_) state_.reset(new State(url().path.UTF8String, presetIndex_));
    return state_.get();
  }

  SF2::MIDI::Channel channel_{};
  SF2::Float sampleRate_;
  int presetIndex_;
  mutable std::unique_ptr<State> state_;
};

struct SampleBasedContexts {
  PresetTestContext<0> context0;
  PresetTestContext<1> context1;
  PresetTestContext<2> context2;
  PresetTestContext<3> context3;
};

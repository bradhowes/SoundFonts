// Copyright © 2021 Brad Howes. All rights reserved.
//

#pragma once

#import <XCTest/XCTest.h>

#import "IO/File.hpp"
#import "Render/Preset.hpp"
#import "Render/State.hpp"

struct PresetTestContextBase
{
  inline static SF2::Float epsilon = 1.0e-8;
  static NSURL* getUrl(int urlIndex);
  static int openFile(int urlIndex);
};

template <int UrlIndex>
struct PresetTestContext : PresetTestContextBase
{
  PresetTestContext(int presetIndex = 0, SF2::Float sampleRate = 44100.0) :
  fd_{openFile(UrlIndex)},
  file_{SF2::IO::File(fd_)},
  instruments_{file_},
  preset_{file_, instruments_, file_.presets()[presetIndex]},
  channel_{},
  sampleRate_{sampleRate}
  {}

  const NSURL* url() const {
    return getUrl(UrlIndex);
  }

  int fd() const { return fd_; }

  const SF2::IO::File& file() const { return file_; }

  const SF2::Render::Preset& preset() const { return preset_; }

  SF2::Render::State makeState(const SF2::Render::Config& config) const {
    SF2::Render::State state(sampleRate_, channel_);
    state.prepareForVoice(config);
    return state;
  }

  SF2::Render::State makeState(int key, int velocity) const {
    auto found = preset_.find(key, velocity);
    return makeState(found[0]);
  }

  SF2::MIDI::Channel& channel() { return channel_; }

  static void SamplesEqual(SF2::Float a, SF2::Float b) {
    XCTAssertEqualWithAccuracy(a, b, epsilon);
  }

private:
  int fd_;
  SF2::IO::File file_;
  SF2::Render::InstrumentCollection instruments_;
  SF2::Render::Preset preset_;
  SF2::MIDI::Channel channel_;
  SF2::Float sampleRate_;
};

struct SampleBasedContexts {
  PresetTestContext<0> context0;
  PresetTestContext<1> context1;
  PresetTestContext<2> context2;
  PresetTestContext<3> context3;
};

@interface XCTestCase (SampleComparison)

- (void)sample:(SF2::Float)A equals:(SF2::Float)B;

@end


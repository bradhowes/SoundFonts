// Copyright © 2021 Brad Howes. All rights reserved.
//

#pragma once

#import <XCTest/XCTest.h>

#import "IO/File.hpp"
#import "Render/Preset.hpp"

struct RolandPianoPresetTestContext
{
  inline static double epsilon = 0.0001;

  RolandPianoPresetTestContext() :
  file_{makeFile()},
  preset_{file_, SF2::Render::InstrumentCollection(file_), file_.presets()[0]},
  channel_{}
  {}

  const SF2::IO::File& file() const { return file_; }

  const SF2::Render::Preset& preset() const { return preset_; }

  SF2::Render::Preset::VoiceConfigCollection find(int key, int velocity) const { return preset_.find(key, velocity); }

  SF2::Render::Voice::State* makeState(const SF2::Render::Voice::Config& config, double sampleRate = 44100) const {
    return new SF2::Render::Voice::State(sampleRate, channel_, config);
  }

  SF2::MIDI::Channel& channel() { return channel_; }

  static void SamplesEqual(double a, double b) {
    XCTAssertEqualWithAccuracy(a, b, epsilon);
  }

private:
  static SF2::IO::File makeFile();

  SF2::IO::File file_;
  SF2::Render::Preset preset_;
  SF2::MIDI::Channel channel_;
};

@interface SampleBasedTestCase : XCTestCase {
  RolandPianoPresetTestContext context;
}

- (void)sample:(double)A equals:(double)B;

@end

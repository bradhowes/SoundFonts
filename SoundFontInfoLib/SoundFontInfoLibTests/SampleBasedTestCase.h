//// Copyright © 2021 Brad Howes. All rights reserved.
////
//
//#pragma once
//
//#import <XCTest/XCTest.h>
//
//#import "IO/File.hpp"
//#import "Render/Preset.hpp"
//
//struct PresetTestContextBase
//{
//  inline static double epsilon = 0.0001;
//  static SF2::IO::File makeFile(int urlIndex);
//};
//
//template <int UrlIndex>
//struct PresetTestContext : PresetTestContextBase
//{
//  PresetTestContext() :
//  file_{makeFile(UrlIndex)},
//  instruments_{file_},
//  preset_{file_, instruments_, file_.presets()[0]},
//  channel_{}
//  {}
//
//  const SF2::IO::File& file() const { return file_; }
//
//  const SF2::Render::Preset& preset() const { return preset_; }
//
//  SF2::Render::Preset::VoiceConfigCollection find(int key, int velocity) const { return preset_.find(key, velocity); }
//
//  SF2::Render::Voice::State makeState(int key, int velocity) const {
//    return SF2::Render::Voice::State(44100, channel_, find(key, velocity)[0]);
//  }
//
//  SF2::Render::Voice::State makeState(const SF2::Render::Voice::Config& config, double sampleRate = 44100) const {
//    return SF2::Render::Voice::State(sampleRate, channel_, config);
//  }
//
//  SF2::MIDI::Channel& channel() { return channel_; }
//
//  static void SamplesEqual(double a, double b) {
//    XCTAssertEqualWithAccuracy(a, b, epsilon);
//  }
//
//private:
//  SF2::IO::File file_;
//  SF2::Render::InstrumentCollection instruments_;
//  SF2::Render::Preset preset_;
//  SF2::MIDI::Channel channel_;
//};
//
//@interface SampleBasedTestCase : XCTestCase {
//  PresetTestContextBase context;
//  PresetTestContext<0> context0;
//  PresetTestContext<1> context1;
//  PresetTestContext<2> context2;
//  PresetTestContext<3> context3;
//}
//
//- (void)sample:(double)A equals:(double)B;
//
//@end

// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#import "File.hpp"
#import "NormalizedSampleSource.hpp"

using namespace SF2;

static NSArray<NSURL*>* urls = SF2Files.allResources;

@interface SFFileTestsObjC : XCTestCase

@end

@implementation SFFileTestsObjC

- (void)testParsing1 {
  NSURL* url = [urls objectAtIndex:0];
  int fd = ::open(url.path.UTF8String, O_RDONLY);
  auto file = IO::File(fd);

  XCTAssertEqual(235, file.presets().size());
  XCTAssertEqual(235, file.presetZones().size());
  XCTAssertEqual(705, file.presetZoneGenerators().size());
  XCTAssertEqual(0, file.presetZoneModulators().size());
  XCTAssertEqual(235, file.instruments().size());
  XCTAssertEqual(1498, file.instrumentZones().size());
  XCTAssertEqual(26537, file.instrumentZoneGenerators().size());
  XCTAssertEqual(0, file.instrumentZoneModulators().size());
  XCTAssertEqual(495, file.sampleHeaders().size());

  std::cout << url.path.UTF8String << '\n';
  file.patchReleaseTimes(5.0);
}

- (void)testParsing2 {
  NSURL* url = [urls objectAtIndex:1];
  int fd = ::open(url.path.UTF8String, O_RDONLY);
  auto file = IO::File(fd);

  XCTAssertEqual(270, file.presets().size());
  XCTAssertEqual(2616, file.presetZones().size());
  XCTAssertEqual(17936, file.presetZoneGenerators().size());
  XCTAssertEqual(363, file.presetZoneModulators().size());
  XCTAssertEqual(310, file.instruments().size());
  XCTAssertEqual(2165, file.instrumentZones().size());
  XCTAssertEqual(18942, file.instrumentZoneGenerators().size());
  XCTAssertEqual(2151, file.instrumentZoneModulators().size());
  XCTAssertEqual(864, file.sampleHeaders().size());

  std::cout << url.path.UTF8String << '\n';
  file.patchReleaseTimes(5.0);
}

- (void)testParsing3 {
  NSURL* url = [urls objectAtIndex:2];
  int fd = ::open(url.path.UTF8String, O_RDONLY);
  auto file = IO::File(fd);

  XCTAssertEqual(189, file.presets().size());
  XCTAssertEqual(1054, file.presetZones().size());
  XCTAssertEqual(3059, file.presetZoneGenerators().size());
  XCTAssertEqual(0, file.presetZoneModulators().size());
  XCTAssertEqual(193, file.instruments().size());
  XCTAssertEqual(2818, file.instrumentZones().size());
  XCTAssertEqual(22463, file.instrumentZoneGenerators().size());
  XCTAssertEqual(746, file.instrumentZoneModulators().size());
  XCTAssertEqual(1418, file.sampleHeaders().size());

  std::cout << url.path.UTF8String << '\n';
  file.patchReleaseTimes(5.0);
}

- (void)testParsing4 {
  NSURL* url = [urls objectAtIndex:3];
  int fd = ::open(url.path.UTF8String, O_RDONLY);
  auto file = IO::File(fd);

  XCTAssertEqual(1, file.presets().size());
  XCTAssertEqual(6, file.presetZones().size());
  XCTAssertEqual(12, file.presetZoneGenerators().size());
  XCTAssertEqual(0, file.presetZoneModulators().size());
  XCTAssertEqual(6, file.instruments().size());
  XCTAssertEqual(150, file.instrumentZones().size());
  XCTAssertEqual(443, file.instrumentZoneGenerators().size());
  XCTAssertEqual(0, file.instrumentZoneModulators().size());
  XCTAssertEqual(24, file.sampleHeaders().size());

  std::cout << url.path.UTF8String << '\n';
  file.patchReleaseTimes(5.0);

  auto samples = file.sampleSource(0);
  samples.load();
  XCTAssertEqual(samples.size(), 115458);

  XCTAssertEqualWithAccuracy(samples[0], -0.00103759765625, 0.000001);
}

- (void)testSamples {
  NSURL* url = [urls objectAtIndex:3];
  int fd = ::open(url.path.UTF8String, O_RDONLY);
  auto file = IO::File(fd, true);

  auto samples = file.sampleSource(0);
  samples.load();

  double epsilon = 1e-6;

  off_t sampleOffset = 246;
  XCTAssertEqual(samples.size(), 115458);
  XCTAssertEqualWithAccuracy(samples[0], -0.00103759765625, epsilon);

  off_t pos = ::lseek(fd, sampleOffset, SEEK_SET);
  XCTAssertEqual(pos, sampleOffset);

  int16_t rawSamples[4];
  ::read(fd, &rawSamples, sizeof(rawSamples));
  XCTAssertEqualWithAccuracy(rawSamples[0] * Render::NormalizedSampleSource::normalizationScale, samples[0], epsilon);
  XCTAssertEqualWithAccuracy(rawSamples[1] * Render::NormalizedSampleSource::normalizationScale, samples[1], epsilon);
  XCTAssertEqualWithAccuracy(rawSamples[2] * Render::NormalizedSampleSource::normalizationScale, samples[2], epsilon);
  XCTAssertEqualWithAccuracy(rawSamples[3] * Render::NormalizedSampleSource::normalizationScale, samples[3], epsilon);
}

@end

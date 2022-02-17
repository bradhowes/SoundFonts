// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#include "Render/Engine/Engine.hpp"

using namespace SF2::Render::Engine;

@interface EngineTests : XCTestCase

@end

@implementation EngineTests

static SF2::IO::File loadFile() {
  NSArray<NSURL*>* urls = SF2Files.allResources;
  NSURL* url = [urls objectAtIndex: 0];
  return SF2::IO::File(::open(url.path.UTF8String, O_RDONLY));
}

SF2::IO::File file = loadFile();

- (void)testInit {
  Engine engine(44100.0, 32);
  XCTAssertEqual(engine.maxVoiceCount(), 32);
  XCTAssertEqual(engine.activeVoiceCount(), 32);
}

- (void)testLoad {
  Engine engine(44100.0, 32);
  engine.load(file);
  XCTAssertEqual(engine.presetCount(), 235);
}

- (void)testUsePreset {
  Engine engine(44100.0, 32);
}

@end

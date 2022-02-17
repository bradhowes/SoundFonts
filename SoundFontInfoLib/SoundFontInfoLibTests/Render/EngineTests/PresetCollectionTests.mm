// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#include "Render/Engine/PresetCollection.hpp"

using namespace SF2::Render::Engine;

@interface PresetCollectionTests : XCTestCase

@end

@implementation PresetCollectionTests

static SF2::IO::File loadFile() {
  NSArray<NSURL*>* urls = SF2Files.allResources;
  NSURL* url = [urls objectAtIndex: 0];
  return SF2::IO::File(::open(url.path.UTF8String, O_RDONLY));
}

static SF2::IO::File file = loadFile();

- (void)testInit {
  PresetCollection presets;
  XCTAssertEqual(presets.size(), 0);
}

- (void)testLoad {
  PresetCollection presets;
  presets.build(file);
  XCTAssertEqual(presets.size(), 235);
  XCTAssertEqual(presets[0].name(), "Piano 1");
  XCTAssertEqual(presets[1].name(), "Piano 2");
  XCTAssertEqual(presets[2].name(), "Piano 3");
  XCTAssertEqual(presets[presets.size() - 1].name(), "SFX");
}

@end

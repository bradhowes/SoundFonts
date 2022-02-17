// Copyright © 2020 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>

#include "Render/Engine/OldestActiveVoiceCache.hpp"

using namespace SF2::Render::Engine;

@interface OldestVoiceCacheTests : XCTestCase

@end

@implementation OldestVoiceCacheTests

- (void)testCache {
  OldestActiveVoiceCache cache{8};
  XCTAssertTrue(cache.empty());
  cache.add(0);
  XCTAssertFalse(cache.empty());
  cache.add(1);
  XCTAssertEqual(0, cache.takeOldest());
  XCTAssertFalse(cache.empty());
  XCTAssertEqual(1, cache.takeOldest());
  XCTAssertTrue(cache.empty());
}

- (void)testDuplicateAddThrows {
  OldestActiveVoiceCache cache{8};
  XCTAssertTrue(cache.empty());
  cache.add(0);
  XCTAssertThrows(cache.add(0));
}

- (void)testRemoveMissingThrows {
  OldestActiveVoiceCache cache{8};
  XCTAssertThrows(cache.remove(0));
}

- (void)testInvalidVoiceIndexThrows {
  OldestActiveVoiceCache cache{8};
  XCTAssertThrows(cache.add(10));
  XCTAssertThrows(cache.remove(10));
}

- (void)testEmptyTakeOldestThrows {
  OldestActiveVoiceCache cache{8};
  XCTAssertThrows(cache.takeOldest());
}


@end

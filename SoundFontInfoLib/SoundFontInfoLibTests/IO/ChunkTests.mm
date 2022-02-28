// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include <XCTest/XCTest.h>

#include "IO/Chunk.hpp"

using namespace SF2::IO;

@interface ChunkTests : XCTestCase
@end

@implementation ChunkTests

off_t mockSeek(int fd, off_t offset, int whence) { return offset; }

ssize_t mockRead(int fd, void* buffer, size_t count) {
  const char* source = "hello";
  memcpy(buffer, source, std::min(count, strlen(source)));
  return count;
}

- (void)testInit {
  Chunk chunk(Tags::riff, 10, Pos(-1, 0, 10));
  XCTAssertEqual(Tag(Tags::riff), chunk.tag());
  XCTAssertEqual(10, chunk.size());
  XCTAssertEqual(chunk.end().offset(), chunk.advance().offset());
  XCTAssertEqual(10, chunk.begin().available());
  XCTAssertEqual(0, chunk.end().available());
}

- (void)testExtract {
  Pos::Mockery mock{&mockSeek, &mockRead};
  Chunk chunk(Tags::riff, 6, Pos(-1, 0, 10));
  std::string extracted = chunk.extract();
  XCTAssertEqual(std::string("hello"), extracted);
}

- (void)testAdvancePadding {
  Chunk chunk(Tags::riff, 3, Pos(-1, 0, 7));
  XCTAssertEqual(3, chunk.size());
  XCTAssertEqual(chunk.end().offset() + 1, chunk.advance().offset());
}

- (void)testCheckValidity {
  XCTAssertTrue(Pos(-1, 0, 10));
  XCTAssertTrue(Pos(0, 11, 10));
}

@end

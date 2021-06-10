// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "Render/DelayBuffer.hpp"

@interface DelayBufferTests : XCTestCase

@end

@implementation DelayBufferTests

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSizing {
  XCTAssertEqual(1, SF2::Render::DelayBuffer<float>(-1.0).size());
  XCTAssertEqual(2, SF2::Render::DelayBuffer<float>(1.2).size());
  XCTAssertEqual(128, SF2::Render::DelayBuffer<float>(123.4).size());
  XCTAssertEqual(1024, SF2::Render::DelayBuffer<float>(1024.0).size());
}

- (void)testReadFromOffset{
  auto buffer = SF2::Render::DelayBuffer<float>(8);
  XCTAssertEqual(8, buffer.size());
  buffer.write(1.2);
  buffer.write(2.4);
  buffer.write(3.6);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(1), 3.6, 0.001);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(2), 2.4, 0.001);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(3), 1.2, 0.001);
}

- (void)testReadInterpolated {
  auto buffer = SF2::Render::DelayBuffer<float>(8);
  XCTAssertEqual(8, buffer.size());
  buffer.write(1.2);
  buffer.write(2.4);
  buffer.write(3.6);
  XCTAssertEqualWithAccuracy(buffer.read(1.0), 3.6, 0.001);
  XCTAssertEqualWithAccuracy(buffer.read(2.0), 2.4, 0.001);
  XCTAssertEqualWithAccuracy(buffer.read(3.0), 1.2, 0.001);
  XCTAssertEqualWithAccuracy(buffer.read(1.1), 3.48, 0.001);
  XCTAssertEqualWithAccuracy(buffer.read(1.2), 3.36, 0.001);
  XCTAssertEqualWithAccuracy(buffer.read(1.5), 3.0, 0.001);
  XCTAssertEqualWithAccuracy(buffer.read(1.8), 2.64, 0.001);
  XCTAssertEqualWithAccuracy(buffer.read(1.9), 2.52, 0.001);
}

- (void)testWrapping {
  auto buffer = SF2::Render::DelayBuffer<float>(4);
  XCTAssertEqual(4, buffer.size());
  buffer.write(1.2);
  buffer.write(2.4);
  buffer.write(3.6);
  buffer.write(4.8);
  buffer.write(5.0);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(0), 2.4, 0.001);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(1), 5.0, 0.001);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(2), 4.8, 0.001);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(3), 3.6, 0.001);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(4), 2.4, 0.001);
}

@end


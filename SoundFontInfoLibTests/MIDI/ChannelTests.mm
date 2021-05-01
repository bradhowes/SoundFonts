// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "MIDI/Channel.hpp"

using namespace SF2::MIDI;

@interface ChannelTests : XCTestCase
@property (nonatomic, assign) double epsilon;
@end

@implementation ChannelTests

- (void)testChannelKeyPressureValues {
    Channel channel;
    for (int key = 0; key < 128; ++key) XCTAssertEqual(0, channel.keyPressure(Note(key)));

    channel.setKeyPressure(64, 3);
    XCTAssertEqual(3, channel.keyPressure(64));

    for (int key = 0; key < 128; ++key) channel.setKeyPressure(key, 121);
    for (int key = 0; key < 128; ++key) XCTAssertEqual(121, channel.keyPressure(key));
}

- (void)testChannelPressureValue {
    Channel channel;
    XCTAssertEqual(0, channel.channelPressure());

    channel.setChannelPressure(123);
    XCTAssertEqual(123, channel.channelPressure());
}

- (void)testChannelPitchWheelValue {
    Channel channel;
    XCTAssertEqual(0, channel.pitchWheelValue());

    channel.setPitchWheelValue(123);
    XCTAssertEqual(123, channel.pitchWheelValue());
}

- (void)testChannelPitchWheelSensitivity {
    Channel channel;
    XCTAssertEqual(200, channel.pitchWheelSensitivity());

    channel.setPitchWheelSensitivity(123);
    XCTAssertEqual(123, channel.pitchWheelSensitivity());
}

- (void)testChannelContinuousControllerValues {
    Channel channel;
    for (int index = 0; index < 127; index += 10) XCTAssertEqual(0, channel.continuousControllerValue(index));

    channel.setContinuousControllerValue(0, 123);
    XCTAssertEqual(123, channel.continuousControllerValue(0));

    channel.setContinuousControllerValue(0, 456);
    XCTAssertEqual(456, channel.continuousControllerValue(0));

    for (int index = 0; index < 127; index += 10) {
        channel.setContinuousControllerValue(index, -50 + index);
    }

    for (int index = 0; index < 127; index += 10) {
        XCTAssertEqual(-50 + index, channel.continuousControllerValue(index));
    }
}

@end

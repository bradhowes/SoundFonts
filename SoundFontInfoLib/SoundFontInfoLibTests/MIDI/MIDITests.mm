// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include <XCTest/XCTest.h>

#include "MIDI/MIDI.hpp"

using namespace SF2;
using namespace SF2::MIDI;

@interface MIDITests : XCTestCase
@property (nonatomic, assign) Float epsilon;
@end

//@implementation MIDITests
//
//- (void)setUp {
//  self.epsilon = 0.0000001;
//}
//
//@end

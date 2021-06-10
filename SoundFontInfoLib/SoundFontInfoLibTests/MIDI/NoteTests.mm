// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "MIDI/Note.hpp"

using namespace SF2::MIDI;

@interface NoteTests : XCTestCase
@end

@implementation NoteTests

- (void)testNoteLabels {
  XCTAssertEqual(std::string("C-1"), Note(0).label());
  XCTAssertEqual(std::string("A4"), Note(69).label());
  XCTAssertEqual(std::string("A4♯"), Note(70).label());
}

- (void)testNoteValues {
  XCTAssertEqual(Note(0), Note(0));
  XCTAssertEqual(Note(69), Note(69));
}

- (void)testNoteEquality {
  XCTAssertTrue(Note(69) == Note(69));
  XCTAssertTrue(69 == Note(69));
}

- (void)testNoteInequality {
  XCTAssertTrue(Note(69) != Note(70));
  XCTAssertTrue(69 != Note(70));
}

- (void)testNoteOrdering {
  XCTAssertTrue(Note(69) < Note(70));
  XCTAssertTrue(Note(69) <= Note(70));
  XCTAssertTrue(Note(70) <= Note(70));
  XCTAssertTrue(Note(79) > Note(70));
  XCTAssertTrue(Note(78) >= Note(70));
  XCTAssertTrue(Note(70) >= Note(70));
}

@end

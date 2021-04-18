// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "Render/Note.hpp"

using namespace SF2::Render;

@interface NoteTests : XCTestCase
@end

@implementation NoteTests

- (void)testNoteLabels {
    XCTAssertEqual(std::string("C-1"), Note(0).label());
    XCTAssertEqual(std::string("A4"), Note(69).label());
    XCTAssertEqual(std::string("A4♯"), Note(70).label());
}

- (void)testNoteValues {
    XCTAssertEqual(0, Note(0));
    XCTAssertEqual(69, Note(69));
}

- (void)testNoteEquality {
    XCTAssertTrue(Note(69) == Note(69));
    XCTAssertTrue(Note(69) == 69);
    XCTAssertTrue(69 == Note(69));
}

- (void)testNoteInequality {
    XCTAssertTrue(Note(69) != Note(70));
    XCTAssertTrue(Note(69) != 70);
    XCTAssertTrue(69 != Note(70));
}

@end

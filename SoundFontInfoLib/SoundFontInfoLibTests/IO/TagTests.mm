// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "IO/Tag.hpp"

using namespace SF2::IO;

@interface TagsTests : XCTestCase
@end

@implementation TagsTests

- (void)testPack4Chars {
    uint32_t value = Pack4Chars("abcd");
    XCTAssertEqual(1684234849, value);
}

- (void)testRiff {
    XCTAssertEqual(1179011410, riff);
}

@end

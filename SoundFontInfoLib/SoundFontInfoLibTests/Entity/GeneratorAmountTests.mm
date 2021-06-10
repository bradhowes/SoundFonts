// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "Entity/Generator/Amount.hpp"

using namespace SF2::Entity::Generator;

@interface GeneratorAmountTests : XCTestCase
@end

@implementation GeneratorAmountTests

- (void)testEntityAmount {
  Amount amount(0);
  XCTAssertEqual(0, amount.low());
  XCTAssertEqual(0, amount.high());
  
  amount = Amount(0x7F7F);
  XCTAssertEqual(127, amount.low());
  XCTAssertEqual(127, amount.high());
  
  amount = Amount(0x7F00);
  XCTAssertEqual(0, amount.low());
  XCTAssertEqual(127, amount.high());
  
  amount = Amount(0xFF80);
  XCTAssertEqual(128, amount.low());
  XCTAssertEqual(255, amount.high());
}
@end

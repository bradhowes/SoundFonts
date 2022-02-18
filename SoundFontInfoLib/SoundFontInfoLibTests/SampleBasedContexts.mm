// Copyright © 2021 Brad Howes. All rights reserved.
//

#import <SF2Files/SF2Files-Swift.h>

#import "SampleBasedContexts.h"

using namespace SF2;
using namespace SF2::Render;

SF2::IO::File PresetTestContextBase::makeFile(int urlIndex)
{
  NSArray<NSURL*>* urls = SF2Files.allResources;
  NSURL* url = [urls objectAtIndex:urlIndex];
  return IO::File(::open(url.path.UTF8String, O_RDONLY));
}

@implementation XCTestCase (SampleComparison)

- (void)sample:(Float)A equals:(Float)B {
  XCTAssertEqualWithAccuracy(A, B, PresetTestContextBase::epsilon);
}

@end

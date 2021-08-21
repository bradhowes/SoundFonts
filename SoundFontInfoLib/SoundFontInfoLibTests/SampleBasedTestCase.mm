// Copyright © 2021 Brad Howes. All rights reserved.
//

#import <SF2Files/SF2Files-Swift.h>

#import "SampleBasedTestCase.h"

using namespace SF2;
using namespace SF2::Render;

@implementation SampleBasedTestCase

SF2::IO::File RolandPianoPresetTestContext::makeFile()
{
  NSArray<NSURL*>* urls = SF2Files.allResources;
  NSURL* url = [urls objectAtIndex:3];
  uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
  int fd = ::open(url.path.UTF8String, O_RDONLY);
  return IO::File(fd, fileSize);
}

- (void)sample:(double)A equals:(double)B {
  XCTAssertEqualWithAccuracy(A, B, context.epsilon);
}

@end

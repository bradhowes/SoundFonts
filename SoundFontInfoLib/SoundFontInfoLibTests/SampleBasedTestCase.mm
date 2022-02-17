//// Copyright © 2021 Brad Howes. All rights reserved.
////
//
//#import <SF2Files/SF2Files-Swift.h>
//
//#import "SampleBasedTestCase.h"
//
//using namespace SF2;
//using namespace SF2::Render;
//
//SF2::IO::File PresetTestContextBase::makeFile(int urlIndex)
//{
//  NSArray<NSURL*>* urls = SF2Files.allResources;
//  NSURL* url = [urls objectAtIndex:urlIndex];
//  uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
//  int fd = ::open(url.path.UTF8String, O_RDONLY);
//  return IO::File(fd, fileSize);
//}
//
//@implementation SampleBasedTestCase
//
//- (void)sample:(double)A equals:(double)B {
//  XCTAssertEqualWithAccuracy(A, B, context0.epsilon);
//}
//
//@end

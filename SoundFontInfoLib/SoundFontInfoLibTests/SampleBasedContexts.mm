// Copyright © 2021 Brad Howes. All rights reserved.
//

#import <SF2Files/SF2Files-Swift.h>

#import "SampleBasedContexts.hpp"

using namespace SF2;
using namespace SF2::Render;

NSURL* PresetTestContextBase::getUrl(int urlIndex)
{
  NSArray<NSURL*>* urls = SF2Files.allResources;
  return [urls objectAtIndex:urlIndex];
}

@implementation XCTestCase (SampleComparison)

@end

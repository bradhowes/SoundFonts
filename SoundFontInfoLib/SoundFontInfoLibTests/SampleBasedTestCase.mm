// Copyright © 2021 Brad Howes. All rights reserved.
//

#import <SF2Files/SF2Files-Swift.h>

#import "SampleBasedTestCase.h"

using namespace SF2;
using namespace SF2::Render;

@implementation SampleBasedTestCase

@synthesize epsilon;

double RolandPianoPresetTestContext::epsilon = 0.0001;

RolandPianoPresetTestContext::RolandPianoPresetTestContext() :
file_{RolandPianoPresetTestContext::makeFile()},
preset_{file_, InstrumentCollection(file_), file_.presets()[0]},
channel_{}
{}

- (void)sample:(double)A equals:(double)B {
  XCTAssertEqualWithAccuracy(A, B, context.epsilon);
}

@end

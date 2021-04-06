// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "Render/LFO.hpp"

#define SamplesEqual(A, B) XCTAssertEqualWithAccuracy(A, B, _epsilon)

@interface LFOTests : XCTestCase
@property float epsilon;
@end

@implementation LFOTests

- (void)setUp {
    _epsilon = 0.0001;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSinusoidSamples {
    SF2::Render::LFO<float> osc(4.0, 1.0, SF2::Render::LFOWaveform::sinusoid);
    SamplesEqual(osc.valueAndIncrement(),  0.0);
    SamplesEqual(osc.valueAndIncrement(),  1.0);
    SamplesEqual(osc.valueAndIncrement(),  0.0);
    SamplesEqual(osc.valueAndIncrement(), -1.0);
    SamplesEqual(osc.valueAndIncrement(),  0.0);
    SamplesEqual(osc.valueAndIncrement(),  1.0);
    SamplesEqual(osc.valueAndIncrement(),  0.0);
    SamplesEqual(osc.valueAndIncrement(), -1.0);
}

- (void)testSawtoothSamples {
    SF2::Render::LFO<float> osc(8.0, 1.0, SF2::Render::LFOWaveform::sawtooth);
    SamplesEqual(osc.valueAndIncrement(), -1.00);
    SamplesEqual(osc.valueAndIncrement(), -0.75);
    SamplesEqual(osc.valueAndIncrement(), -0.50);
    SamplesEqual(osc.valueAndIncrement(), -0.25);
    SamplesEqual(osc.valueAndIncrement(),  0.00);
    SamplesEqual(osc.valueAndIncrement(),  0.25);
    SamplesEqual(osc.valueAndIncrement(),  0.50);
    SamplesEqual(osc.valueAndIncrement(),  0.75);
    SamplesEqual(osc.valueAndIncrement(), -1.00);
}

- (void)testTriangleSamples {
    SF2::Render::LFO<float> osc(8.0, 1.0, SF2::Render::LFOWaveform::triangle);
    SamplesEqual(osc.valueAndIncrement(),  1.0);
    SamplesEqual(osc.valueAndIncrement(),  0.5);
    SamplesEqual(osc.valueAndIncrement(),  0.0);
    SamplesEqual(osc.valueAndIncrement(), -0.5);
    SamplesEqual(osc.valueAndIncrement(), -1.0);
    SamplesEqual(osc.valueAndIncrement(), -0.5);
    SamplesEqual(osc.valueAndIncrement(),  0.0);
    SamplesEqual(osc.valueAndIncrement(),  0.5);
    SamplesEqual(osc.valueAndIncrement(),  1.0);
}

- (void)testQuadPhaseSamples {
    SF2::Render::LFO<float> osc(8.0, 1.0, SF2::Render::LFOWaveform::sawtooth);
    SamplesEqual(osc.valueAndIncrement(), -1.00);
    SamplesEqual(osc.quadPhaseValue(), -0.50);
    SamplesEqual(osc.quadPhaseValue(), -0.50);
    SamplesEqual(osc.valueAndIncrement(), -0.75);
    SamplesEqual(osc.quadPhaseValue(), -0.25);
    SamplesEqual(osc.valueAndIncrement(), -0.50);
    SamplesEqual(osc.quadPhaseValue(),  0.00);
    SamplesEqual(osc.valueAndIncrement(), -0.25);
    SamplesEqual(osc.quadPhaseValue(),  0.25);
    SamplesEqual(osc.valueAndIncrement(),  0.00);
    SamplesEqual(osc.quadPhaseValue(),  0.50);
    SamplesEqual(osc.valueAndIncrement(),  0.25);
    SamplesEqual(osc.quadPhaseValue(),  0.75);
    SamplesEqual(osc.valueAndIncrement(),  0.50);
    SamplesEqual(osc.quadPhaseValue(), -1.00);
    SamplesEqual(osc.valueAndIncrement(),  0.75);
    SamplesEqual(osc.quadPhaseValue(), -0.75);
    SamplesEqual(osc.valueAndIncrement(), -1.00);
    SamplesEqual(osc.quadPhaseValue(), -0.50);
}

- (void)testSaveRestore {
    SF2::Render::LFO<float> osc(8.0, 1.0, SF2::Render::LFOWaveform::sawtooth);
    SamplesEqual(osc.valueAndIncrement(), -1.00);
    SamplesEqual(osc.quadPhaseValue(), -0.50);
    SamplesEqual(osc.valueAndIncrement(), -0.75);
    SamplesEqual(osc.quadPhaseValue(), -0.25);
    float state = osc.saveState();
    SamplesEqual(osc.valueAndIncrement(), -0.50);
    SamplesEqual(osc.quadPhaseValue(),  0.00);
    SamplesEqual(osc.valueAndIncrement(), -0.25);
    SamplesEqual(osc.quadPhaseValue(),  0.25);
    osc.restoreState(state);
    SamplesEqual(osc.valueAndIncrement(), -0.50);
    SamplesEqual(osc.quadPhaseValue(),  0.00);
    SamplesEqual(osc.valueAndIncrement(), -0.25);
    SamplesEqual(osc.quadPhaseValue(),  0.25);
}

@end

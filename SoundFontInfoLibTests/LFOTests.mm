// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "Render/LFO.hpp"

#define SamplesEqual(A, B) XCTAssertEqualWithAccuracy(A, B, _epsilon)

using namespace SF2::Render;

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
    LFO<float> osc(8.0, 1.0, 0.0, SF2::Render::LFOWaveform::sinusoid);
    SamplesEqual(osc.valueAndIncrement(), 0.0);
    SamplesEqual(osc.valueAndIncrement(), 0.146447);
    SamplesEqual(osc.valueAndIncrement(), 0.5);
    SamplesEqual(osc.valueAndIncrement(), 0.853553);
    SamplesEqual(osc.valueAndIncrement(), 1.0);
    SamplesEqual(osc.valueAndIncrement(), 0.853553);
    SamplesEqual(osc.valueAndIncrement(), 0.5);
    SamplesEqual(osc.valueAndIncrement(), 0.146447);
    SamplesEqual(osc.valueAndIncrement(), 0.0);
}

- (void)testSawtoothSamples {
    LFO<float> osc(8.0, 1.0, 0.0, SF2::Render::LFOWaveform::sawtooth);
    SamplesEqual(osc.valueAndIncrement(), 0.00);
    SamplesEqual(osc.valueAndIncrement(), 0.125);
    SamplesEqual(osc.valueAndIncrement(), 0.25);
    SamplesEqual(osc.valueAndIncrement(), 0.375);
    SamplesEqual(osc.valueAndIncrement(), 0.5);
    SamplesEqual(osc.valueAndIncrement(), 0.625);
    SamplesEqual(osc.valueAndIncrement(), 0.750);
    SamplesEqual(osc.valueAndIncrement(), 0.875);
    SamplesEqual(osc.valueAndIncrement(), 0.00);
}

- (void)testTriangleSamples {
    LFO<float> osc(8.0, 1.0, 0.0, SF2::Render::LFOWaveform::triangle);
    SamplesEqual(osc.valueAndIncrement(), 0.0);
    SamplesEqual(osc.valueAndIncrement(), 0.25);
    SamplesEqual(osc.valueAndIncrement(), 0.5);
    SamplesEqual(osc.valueAndIncrement(), 0.75);
    SamplesEqual(osc.valueAndIncrement(), 1.0);
    SamplesEqual(osc.valueAndIncrement(), 0.75);
    SamplesEqual(osc.valueAndIncrement(), 0.5);
    SamplesEqual(osc.valueAndIncrement(), 0.25);
    SamplesEqual(osc.valueAndIncrement(), 0.0);
}

- (void)testQuadPhaseSamples {
    LFO<float> osc(8.0, 1.0, 0.0, SF2::Render::LFOWaveform::sawtooth);
    SamplesEqual(osc.valueAndIncrement(), 0.00);
    SamplesEqual(osc.quadPhaseValue(), 0.25);
    SamplesEqual(osc.quadPhaseValue(), 0.25);
    SamplesEqual(osc.valueAndIncrement(), 0.125);
    SamplesEqual(osc.quadPhaseValue(), 0.375);
    SamplesEqual(osc.valueAndIncrement(), 0.25);
    SamplesEqual(osc.quadPhaseValue(), 0.5);
    SamplesEqual(osc.valueAndIncrement(), 0.375);
    SamplesEqual(osc.quadPhaseValue(), 0.625);
    SamplesEqual(osc.valueAndIncrement(), 0.5);
    SamplesEqual(osc.quadPhaseValue(), 0.75);
    SamplesEqual(osc.valueAndIncrement(), 0.625);
    SamplesEqual(osc.quadPhaseValue(), 0.875);
    SamplesEqual(osc.valueAndIncrement(), 0.75);
    SamplesEqual(osc.quadPhaseValue(), 0.00);
    SamplesEqual(osc.valueAndIncrement(), 0.875);
    SamplesEqual(osc.quadPhaseValue(), 0.125);
    SamplesEqual(osc.valueAndIncrement(), 0.0);
    SamplesEqual(osc.quadPhaseValue(), 0.250);
}

- (void)testSaveRestore {
    LFO<float> osc(8.0, 1.0, 0.0, SF2::Render::LFOWaveform::sawtooth);
    SamplesEqual(osc.valueAndIncrement(), 0.0);
    SamplesEqual(osc.quadPhaseValue(), 0.25);
    SamplesEqual(osc.valueAndIncrement(), 0.125);
    SamplesEqual(osc.quadPhaseValue(), 0.375);
    auto state = osc.saveState();
    SamplesEqual(osc.valueAndIncrement(), 0.25);
    SamplesEqual(osc.quadPhaseValue(), 0.5);
    SamplesEqual(osc.valueAndIncrement(), 0.375);
    SamplesEqual(osc.quadPhaseValue(), 0.625);
    osc.restoreState(state);
    SamplesEqual(osc.valueAndIncrement(), 0.25);
    SamplesEqual(osc.quadPhaseValue(), 0.5);
    SamplesEqual(osc.valueAndIncrement(), 0.375);
    SamplesEqual(osc.quadPhaseValue(), 0.625);
}

- (void)testDelay {
    LFO<float> osc(8.0, 1.0, 0.125, SF2::Render::LFOWaveform::sawtooth);
    SamplesEqual(osc.valueAndIncrement(), 0.0);
    SamplesEqual(osc.valueAndIncrement(), 0.0);
    SamplesEqual(osc.valueAndIncrement(), 0.125);
    osc.setDelay(0.25);
    SamplesEqual(osc.valueAndIncrement(), 0.0);
    SamplesEqual(osc.valueAndIncrement(), 0.0);
    SamplesEqual(osc.valueAndIncrement(), 0.0);
    SamplesEqual(osc.valueAndIncrement(), 0.125);
}

- (void)testConfig {
    auto osc = LFO<double>::Config(8.0).frequency(1.0).delay(0.125).waveform(SF2::Render::LFOWaveform::sawtooth).make();
    SamplesEqual(osc.valueAndIncrement(), 0.0);
    SamplesEqual(osc.valueAndIncrement(), 0.0);
    SamplesEqual(osc.valueAndIncrement(), 0.125);
    osc = LFO<double>::Config(8.0).frequency(1.0).delay(0.0).waveform(SF2::Render::LFOWaveform::sawtooth).make();
    SamplesEqual(osc.valueAndIncrement(), 0.0);
    SamplesEqual(osc.valueAndIncrement(), 0.125);
    osc = LFO<double>::Config(8.0).frequency(2.0).waveform(SF2::Render::LFOWaveform::sawtooth).make();
    SamplesEqual(osc.valueAndIncrement(),  0.0);
    SamplesEqual(osc.valueAndIncrement(),  0.25);
    osc = LFO<double>::Config(8.0).frequency(1.0).waveform(SF2::Render::LFOWaveform::sinusoid).make();
    SamplesEqual(osc.valueAndIncrement(), 0.0);
    SamplesEqual(osc.valueAndIncrement(), 0.146446609407);
    SamplesEqual(osc.valueAndIncrement(), 0.5);
    osc = LFO<double>::Config(8.0).frequency(1.0).waveform(SF2::Render::LFOWaveform::triangle).make();
    SamplesEqual(osc.valueAndIncrement(), 0.0);
    SamplesEqual(osc.valueAndIncrement(), 0.25);
    SamplesEqual(osc.valueAndIncrement(), 0.5);
}

@end

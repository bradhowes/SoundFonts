// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "SFManager.hpp"

using namespace SF2;

@interface SFManagerTests : XCTestCase
@property (nonatomic, assign) double epsilon;
@property (nonatomic, retain) NSBundle* bundle;
@end

@implementation SFManagerTests

- (void)setUp {
    self.epsilon = 0.0000001;
    self.bundle = [NSBundle bundleForClass:[self class]];
}

- (void)tearDown {
}

- (NSString*)soundFontPath:(NSString*)name {
    return [self.bundle pathForResource:name ofType:@"sf2"];
}

SFManager makeManager(NSString* path)
{
    return SFManager(path.fileSystemRepresentation);
}

SF2::Preset::Matches getMatches(SFManager const& mgr)
{
    auto const& preset = mgr.presets().at(0);
    return preset.find(69, 64);
}

- (void)testFluidR3 {
    auto mgr = makeManager([self soundFontPath:@"FluidR3_GM"]);
    auto zones = getMatches(mgr);
    XCTAssertEqual(1, zones.size());
}

- (void)testFreeFont {
    auto mgr = makeManager([self soundFontPath:@"FreeFont"]);
    mgr.fileData().dump();
    auto zones = getMatches(mgr);
    XCTAssertEqual(1, zones.size());
}

- (void)testMuseScore {
    auto mgr = makeManager([self soundFontPath:@"GeneralUser GS MuseScore v1.442"]);
    auto zones = getMatches(mgr);
    XCTAssertEqual(1, zones.size());
}

- (void)testNicePiano {
    auto mgr = makeManager([self soundFontPath:@"RolandNicePiano"]);
    auto zones = getMatches(mgr);

    XCTAssertEqual(2, zones.size());
    auto const& pair0 = zones.at(0);
    PresetZone const& presetZone0 = pair0.first;

    XCTAssertEqual(false, presetZone0.isGlobal());
    XCTAssertEqual("Instrument4", presetZone0.instrument().configuration().name());
    XCTAssertEqual(0, presetZone0.keyRange().low());
    XCTAssertEqual(127, presetZone0.keyRange().high());
    XCTAssertEqual(64, presetZone0.velocityRange().low());
    XCTAssertEqual(77, presetZone0.velocityRange().high());
    XCTAssertEqual(2, presetZone0.generators().size());
    XCTAssertEqual(SFGenIndex::velRange, presetZone0.generators()[0].get().index());
    XCTAssertEqual(SFGenIndex::instrument, presetZone0.generators()[1].get().index());

    XCTAssertEqual(0, presetZone0.modulators().size());

    auto const& instrumentZone0 = pair0.second.get();
    XCTAssertEqual(68, instrumentZone0.keyRange().low());
    XCTAssertEqual(72, instrumentZone0.keyRange().high());
}

@end

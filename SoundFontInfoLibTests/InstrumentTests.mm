// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#include "IO/File.hpp"
#include "Render/Preset.hpp"
#include "Render/Voice/Setup.hpp"
#include "Render/Voice/State.hpp"

using namespace SF2;

static NSArray<NSURL*>* urls = SF2Files.allResources;

using namespace SF2::Render;

@interface InstrumentTests : XCTestCase
@end

@implementation InstrumentTests

- (void)testRolandPianoInstrument {
    double epsilon = 0.000001;
    NSURL* url = [urls objectAtIndex:3];
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
    int fd = ::open(url.path.UTF8String, O_RDONLY);
    auto file = IO::File(fd, fileSize);

    Instrument instrument(file, file.instruments()[0]);
    XCTAssertTrue(instrument.hasGlobalZone());
    const InstrumentZone* globalZone = instrument.globalZone();
    XCTAssertTrue(globalZone != nullptr);
    XCTAssertEqual(nullptr, globalZone->sampleBuffer());

    auto zones = instrument.filter(64, 10);
    XCTAssertEqual(2, zones.size());
    XCTAssertFalse(zones[0].get().isGlobal());
    XCTAssertNotEqual(nullptr, zones[0].get().sampleBuffer());

    InstrumentCollection instruments(file);
    Preset preset(file, instruments, file.presets()[0]);
    auto found = preset.find(64, 64);

    Voice::State left{44100.0, found[0]};
    XCTAssertEqual(-50, left[Entity::Generator::Index::pan]);
    XCTAssertEqualWithAccuracy(3.25088682907, left[Entity::Generator::Index::releaseVolumeEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(1499.77085765, left[Entity::Generator::Index::initialFilterCutoff], epsilon);
    XCTAssertEqual(23, left[Entity::Generator::Index::sampleID]);

    Voice::State right{44100.0, found[1]};
    XCTAssertEqual(50, right[Entity::Generator::Index::pan]);
    XCTAssertEqualWithAccuracy(3.25088682907, right[Entity::Generator::Index::releaseVolumeEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(1499.77085765, right[Entity::Generator::Index::initialFilterCutoff], epsilon);
    XCTAssertEqual(22, right[Entity::Generator::Index::sampleID]);
}

@end

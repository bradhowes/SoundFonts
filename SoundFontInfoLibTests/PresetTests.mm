// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#include "IO/File.hpp"
#include "Render/Preset.hpp"

using namespace SF2;

static NSArray<NSURL*>* urls = SF2Files.allResources;

using namespace SF2::Render;

@interface PresetTests : XCTestCase
@end

@implementation PresetTests

- (void)testRolandPianoPreset {
    double epsilon = 0.000001;
    NSURL* url = [urls objectAtIndex:3];
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
    int fd = ::open(url.path.UTF8String, O_RDONLY);
    auto file = IO::File(fd, fileSize);

    XCTAssertEqual(1, file.presets().size());

    InstrumentCollection instruments(file);
    Preset preset(file, instruments, file.presets()[0]);
    XCTAssertEqual(6, preset.zones().size());

    XCTAssertFalse(preset.hasGlobalZone());

    auto found = preset.find(64, 10);
    XCTAssertEqual(2, found.size());

    VoiceState left;
    found[0].apply(left);
    XCTAssertEqual(-50, left[Entity::Generator::Index::pan]);
    XCTAssertEqualWithAccuracy(3.00007797857, left[Entity::Generator::Index::releaseVolumeEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(600.017061241, left[Entity::Generator::Index::initialFilterCutoff], epsilon);
    XCTAssertEqual(23, left[Entity::Generator::Index::sampleID]);
    XCTAssertEqual(0, left[Entity::Generator::Index::startAddressOffset]);
    XCTAssertEqual(0, left[Entity::Generator::Index::startAddressCoarseOffset]);
    XCTAssertEqual(0, left[Entity::Generator::Index::endAddressOffset]);
    XCTAssertEqual(0, left[Entity::Generator::Index::endAddressCoarseOffset]);

    VoiceState right;
    found[1].apply(right);
    XCTAssertEqual(50, right[Entity::Generator::Index::pan]);
    XCTAssertEqualWithAccuracy(3.00007797857, right[Entity::Generator::Index::releaseVolumeEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(600.017061241, right[Entity::Generator::Index::initialFilterCutoff], epsilon);
    XCTAssertEqual(22, right[Entity::Generator::Index::sampleID]);
    XCTAssertEqual(0, right[Entity::Generator::Index::startAddressOffset]);
    XCTAssertEqual(0, right[Entity::Generator::Index::startAddressCoarseOffset]);
    XCTAssertEqual(0, right[Entity::Generator::Index::endAddressOffset]);
    XCTAssertEqual(0, right[Entity::Generator::Index::endAddressCoarseOffset]);
}

@end

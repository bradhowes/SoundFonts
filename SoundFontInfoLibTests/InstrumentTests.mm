// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#include "IO/File.hpp"
#include "Render/Instrument.hpp"

using namespace SF2;

static NSArray<NSURL*>* urls = SF2Files.allResources;

using namespace SF2::Render;

@interface InstrumentTests : XCTestCase
@end

@implementation InstrumentTests

- (void)testRolandPianoInstrument {
    NSURL* url = [urls objectAtIndex:3];
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
    int fd = ::open(url.path.UTF8String, O_RDONLY);
    auto file = IO::File(fd, fileSize);

    Instrument instrument(file, file.instruments()[0]);
    XCTAssertTrue(instrument.hasGlobalZone());
    const InstrumentZone* globalZone = instrument.globalZone();
    XCTAssertEqual(nullptr, globalZone->sampleBuffer());

    auto found = instrument.filter(64, 0);
    XCTAssertEqual(2, found.size());

    VoiceState left;
    globalZone->apply(left);
    XCTAssertEqual(0, left[Entity::Generator::Index::pan].amount());
    XCTAssertEqual(1902, left[Entity::Generator::Index::releaseVolumeEnvelope].amount());
    XCTAssertEqual(7437, left[Entity::Generator::Index::initialFilterCutoff].amount());
    XCTAssertEqual(0, left[Entity::Generator::Index::sampleID].amount());

    found[0].get().apply(left);
    XCTAssertNotEqual(nullptr, found[0].get().sampleBuffer());

    // The Roland Piano SF2 file seems to have swapped left/right
    // XCTAssertTrue(found[0].get().sampleBuffer()->header().isLeft());
    XCTAssertEqual(-500, left[Entity::Generator::Index::pan].amount());
    XCTAssertEqual(1902, left[Entity::Generator::Index::releaseVolumeEnvelope].amount());
    XCTAssertEqual(7437, left[Entity::Generator::Index::initialFilterCutoff].amount());
    XCTAssertEqual(23, left[Entity::Generator::Index::sampleID].amount());

    VoiceState right;
    globalZone->apply(right);
    XCTAssertEqual(0, right[Entity::Generator::Index::pan].amount());
    XCTAssertEqual(1902, right[Entity::Generator::Index::releaseVolumeEnvelope].amount());
    XCTAssertEqual(7437, right[Entity::Generator::Index::initialFilterCutoff].amount());
    XCTAssertEqual(0, right[Entity::Generator::Index::sampleID].amount());

    found[1].get().apply(right);
    XCTAssertNotEqual(nullptr, found[1].get().sampleBuffer());
    // The Roland Piano SF2 file seems to have swapped left/right
    // XCTAssertTrue(found[1].get().sampleBuffer()->header().isRight());
    XCTAssertEqual(500, right[Entity::Generator::Index::pan].amount());
    XCTAssertEqual(1902, right[Entity::Generator::Index::releaseVolumeEnvelope].amount());
    XCTAssertEqual(7437, right[Entity::Generator::Index::initialFilterCutoff].amount());
    XCTAssertEqual(22, right[Entity::Generator::Index::sampleID].amount());
}

@end

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
    NSURL* url = [urls objectAtIndex:3];
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
    int fd = ::open(url.path.UTF8String, O_RDONLY);
    auto file = IO::File(fd, fileSize);

    XCTAssertEqual(1, file.presets().size());
    file.dump();

    InstrumentCollection instruments(file);
    Preset preset(file, instruments, file.presets()[0]);
    XCTAssertEqual(6, preset.zones().size());

    XCTAssertFalse(preset.hasGlobalZone());

    auto found = preset.find(64, 10);
    XCTAssertEqual(2, found.size());

    VoiceState left;
    found[0].apply(left);
    XCTAssertEqual(-500, left[Entity::Generator::Index::pan].amount());
    XCTAssertEqual(1902, left[Entity::Generator::Index::releaseVolumeEnvelope].amount());
    XCTAssertEqual(7437, left[Entity::Generator::Index::initialFilterCutoff].amount());
    XCTAssertEqual(23, left[Entity::Generator::Index::sampleID].amount());

    VoiceState right;
    found[1].apply(right);
    XCTAssertEqual(500, right[Entity::Generator::Index::pan].amount());
    XCTAssertEqual(1902, right[Entity::Generator::Index::releaseVolumeEnvelope].amount());
    XCTAssertEqual(7437, right[Entity::Generator::Index::initialFilterCutoff].amount());
    XCTAssertEqual(22, right[Entity::Generator::Index::sampleID].amount());
}

@end

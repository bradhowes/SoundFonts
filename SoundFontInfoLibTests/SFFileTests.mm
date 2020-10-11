// Copyright © 2020 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#import "File.hpp"

using namespace SF2;

static NSArray<NSURL*>* urls = SF2Files.allResources;

@interface FileTests : XCTestCase

@end

@implementation FileTests

- (void)testParsing1 {
    NSURL* url = [urls objectAtIndex:0];
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
    int fd = ::open(url.path.UTF8String, O_RDONLY);
    auto file = IO::File(fd, fileSize);

    XCTAssertEqual(235, file.presets().size());
    XCTAssertEqual(235, file.presetZones().size());
    XCTAssertEqual(705, file.presetZoneGenerators().size());
    XCTAssertEqual(0, file.presetZoneModulators().size());
    XCTAssertEqual(235, file.instruments().size());
    XCTAssertEqual(1498, file.instrumentZones().size());
    XCTAssertEqual(26537, file.instrumentZoneGenerators().size());
    XCTAssertEqual(0, file.instrumentZoneModulators().size());
    XCTAssertEqual(495, file.samples().size());
}

- (void)testParsing2 {
    NSURL* url = [urls objectAtIndex:1];
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
    int fd = ::open(url.path.UTF8String, O_RDONLY);
    auto file = IO::File(fd, fileSize);

    XCTAssertEqual(270, file.presets().size());
    XCTAssertEqual(2616, file.presetZones().size());
    XCTAssertEqual(17936, file.presetZoneGenerators().size());
    XCTAssertEqual(363, file.presetZoneModulators().size());
    XCTAssertEqual(310, file.instruments().size());
    XCTAssertEqual(2165, file.instrumentZones().size());
    XCTAssertEqual(18942, file.instrumentZoneGenerators().size());
    XCTAssertEqual(2151, file.instrumentZoneModulators().size());
    XCTAssertEqual(864, file.samples().size());
}

- (void)testParsing3 {
    NSURL* url = [urls objectAtIndex:2];
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
    int fd = ::open(url.path.UTF8String, O_RDONLY);
    auto file = IO::File(fd, fileSize);

    XCTAssertEqual(189, file.presets().size());
    XCTAssertEqual(1054, file.presetZones().size());
    XCTAssertEqual(3059, file.presetZoneGenerators().size());
    XCTAssertEqual(0, file.presetZoneModulators().size());
    XCTAssertEqual(193, file.instruments().size());
    XCTAssertEqual(2818, file.instrumentZones().size());
    XCTAssertEqual(22463, file.instrumentZoneGenerators().size());
    XCTAssertEqual(746, file.instrumentZoneModulators().size());
    XCTAssertEqual(1418, file.samples().size());
}

- (void)testParsing4 {
    NSURL* url = [urls objectAtIndex:3];
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
    int fd = ::open(url.path.UTF8String, O_RDONLY);
    auto file = IO::File(fd, fileSize);

    XCTAssertEqual(1, file.presets().size());
    XCTAssertEqual(6, file.presetZones().size());
    XCTAssertEqual(12, file.presetZoneGenerators().size());
    XCTAssertEqual(0, file.presetZoneModulators().size());
    XCTAssertEqual(6, file.instruments().size());
    XCTAssertEqual(150, file.instrumentZones().size());
    XCTAssertEqual(443, file.instrumentZoneGenerators().size());
    XCTAssertEqual(0, file.instrumentZoneModulators().size());
    XCTAssertEqual(24, file.samples().size());
}

@end

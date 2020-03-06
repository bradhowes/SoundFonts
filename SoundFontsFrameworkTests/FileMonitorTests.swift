// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

class FileMonitorTests: XCTestCase {

    private func makeFileToMonitor() -> URL {
        let url = try! FileManager.default.newTemporaryFile()
        let outputStream = try! FileHandle(forWritingTo: url)
        outputStream.write("testing".data(using: .ascii)!)
        if #available(iOSApplicationExtension 13.0, *) {
            try! outputStream.close()
        } else {
            outputStream.closeFile()
        }
        return url
    }

    func testtNilOnBadUrl() {
        let url = try? FileManager.default.newTemporaryFile().appendingPathComponent("doesNotExist")
        let mon = FileMonitor(url: url!) {z in }
        XCTAssertNil(mon)
    }

    func testSeesChange() {
        let url = makeFileToMonitor()
        let expectation = self.expectation(description: "detected changed in file")
        let mon = FileMonitor(url: url) {location in expectation.fulfill() }
        XCTAssertNotNil(mon)

        let outputStream = try! FileHandle(forWritingTo: url)
        outputStream.write("blah".data(using: .ascii)!)

        if #available(iOSApplicationExtension 13.0, *) {
            try! outputStream.truncate(atOffset: outputStream.offsetInFile)
            try! outputStream.close()
        } else {
            outputStream.truncateFile(atOffset: outputStream.offsetInFile)
            outputStream.closeFile()
        }

        wait(for: [expectation], timeout: 1.0)

        let s = try! String(contentsOf: url)
        XCTAssertEqual("blah", s)
    }

    func testStopsMonitoringWhenOutOfScope() {
        let url = makeFileToMonitor()
        let expectation = self.expectation(description: "detected changed in file")
        expectation.isInverted = true
        
        var mon = FileMonitor(url: url) {location in expectation.fulfill() }
        XCTAssertNotNil(mon)

        mon = nil

        let outputStream = try! FileHandle(forWritingTo: url)
        outputStream.write("blah".data(using: .ascii)!)

        if #available(iOSApplicationExtension 13.0, *) {
            try! outputStream.truncate(atOffset: outputStream.offsetInFile)
            try! outputStream.close()
        } else {
            outputStream.truncateFile(atOffset: outputStream.offsetInFile)
            outputStream.closeFile()
        }


        wait(for: [expectation], timeout: 1.0)
    }
}

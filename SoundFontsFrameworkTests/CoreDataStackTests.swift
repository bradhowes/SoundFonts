// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework
import CoreData

extension PersistentContainer {
    public func configureInMemory() {
        let psd = NSPersistentStoreDescription()
        psd.type = NSInMemoryStoreType
        self.persistentStoreDescriptions = [psd]
    }
}

class CoreDataStackTests: XCTestCase {

    func testAnnounceWhenReady() {
        let container = PersistentContainer(name: "SoundFonts")
        container.configureInMemory()

        let stack = CoreDataStack<PersistentContainer>(container: container)
        let exp = expectation(description: "testing")
        let registration = stack.availableNotification.registerOnAny { _ in exp.fulfill() }
        waitForExpectations(timeout: 5.0) { XCTAssertNil($0) }
        registration.forget()
    }

    func testAddSoundFont() {
    }


//    func testPerformanceExample() {
//        self.measure {
//        }
//    }
}

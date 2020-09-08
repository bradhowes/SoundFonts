// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework
import SoundFontInfoLib
import CoreData

class CoreDataStackTests: XCTestCase {

    let stack: CoreDataStack<PersistentContainer> = {
        let container = PersistentContainer(kind: .temporary)
        return CoreDataStack<PersistentContainer>(container: container)
    }()

    let sf1 = SoundFontInfo("one", url: URL(fileURLWithPath: "SF1.sf2"), presets: [
        SoundFontInfoPreset("One", bank: 1, preset: 1),
        SoundFontInfoPreset("Two", bank: 1, preset: 2),
        SoundFontInfoPreset("Three", bank: 1, preset: 3),
        SoundFontInfoPreset("Four", bank: 1, preset: 4),
    ])!

    let sf2 = SoundFontInfo("two", url: URL(fileURLWithPath: "SF2.sf2"), presets: [
        SoundFontInfoPreset("A", bank: 1, preset: 1),
        SoundFontInfoPreset("B", bank: 1, preset: 2),
        SoundFontInfoPreset("C", bank: 1, preset: 3),
        SoundFontInfoPreset("D", bank: 1, preset: 4),
    ])!

    func getSoundFonts(_ context: NSManagedObjectContext) -> [SoundFontEntity]? {
        return try? context.fetch(SoundFontEntity.sortedFetchRequest)
    }

    func testAnnounceWhenReady() {
        let exp = expectation(description: "testing")
        let registration = stack.availableNotification.registerOnAny { _ in exp.fulfill() }
        waitForExpectations(timeout: 5.0) { XCTAssertNil($0) }
        registration.forget()
    }

    func testAddSoundFont() {
        let exp = expectation(description: "testing")
        _ = stack.availableNotification.registerOnAny { _ in
            let context = self.stack.newDerivedContext()
            _ = SoundFontEntity(context: context, config: self.sf1)
            self.stack.saveDerivedContext(context)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5.0) { XCTAssertNil($0) }
    }

    func testRootContextIsSavedAfterCreating() {
        let exp = expectation(description: "testing")
        expectation(forNotification: .NSManagedObjectContextDidSave, object: stack.mainContext) { _ in return true }
        _ = stack.availableNotification.registerOnAny { _ in
            let context = self.stack.newDerivedContext()
            context.perform {
                _ = SoundFontEntity(context: context, config: self.sf1)
                self.stack.saveDerivedContext(context)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 5.0) { error in XCTAssertNil(error, "Save did not occur") }
    }

    func FLAKY_testQuery() {
        let exp = expectation(description: "testing")
        _ = stack.availableNotification.registerOnAny { _ in
            let context = self.stack.newDerivedContext()
            _ = SoundFontEntity(context: context, config: self.sf1)
            _ = SoundFontEntity(context: context, config: self.sf2)
            self.stack.saveDerivedContext(context)
            let soundFonts = self.getSoundFonts(context)
            XCTAssertNotNil(soundFonts)
            XCTAssertEqual(soundFonts?.count, 2)
//            let sf1 = soundFonts![0]
//            XCTAssertEqual(sf1.name, "one")
//            XCTAssertEqual(sf1.presets.count, 4)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5.0) { XCTAssertNil($0) }
    }
}

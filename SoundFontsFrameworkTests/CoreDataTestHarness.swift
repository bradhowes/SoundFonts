// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework
import SoundFontInfoLib
import CoreData

public extension XCTestCase {

    typealias TestBlock = (CoreDataTestHarness, NSManagedObjectContext) -> Void

    func doWhenCoreDataReady(_ name: String, block: @escaping TestBlock) {
        let cdth = CoreDataTestHarness()
        let executed = XCTestExpectation(description: name)
        _ = cdth.stack.availableNotification.registerOnMain { _ in
            block(cdth, cdth.context)
            executed.fulfill()
        }
        wait(for: [executed], timeout: 1.0)
    }
}

public class TemporaryPersistentContainer: PersistentContainer {

    /// Just to be safe, store any files in a unique temporary directory
    override public static func defaultDirectoryURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    override public init() {
        super.init()
        let psd = NSPersistentStoreDescription()
        psd.type = NSInMemoryStoreType
        persistentStoreDescriptions = [psd]
    }
}

public class CoreDataTestHarness {

    let container: TemporaryPersistentContainer
    let stack: CoreDataStack<TemporaryPersistentContainer>
    var context: NSManagedObjectContext { stack.mainContext }

    public init() {
        let container = TemporaryPersistentContainer()
        self.container = container
        self.stack = CoreDataStack<TemporaryPersistentContainer>(container: container)
    }

    deinit {
        stack.mainContext.reset()
        try? container.removeStores()
    }
}

extension CoreDataTestHarness {

    var sf1: SoundFontInfo {
        SoundFontInfo("one", url: URL(fileURLWithPath: "SF1.sf2"), presets: [
            SoundFontInfoPreset("One", bank: 1, preset: 1),
            SoundFontInfoPreset("Two", bank: 1, preset: 2),
            SoundFontInfoPreset("Three", bank: 1, preset: 3),
            SoundFontInfoPreset("Four", bank: 1, preset: 4),
        ])!
    }

    var sf2: SoundFontInfo {
        SoundFontInfo("two", url: URL(fileURLWithPath: "SF2.sf2"), presets: [
            SoundFontInfoPreset("A", bank: 1, preset: 1),
            SoundFontInfoPreset("B", bank: 1, preset: 2),
            SoundFontInfoPreset("C", bank: 1, preset: 3),
            SoundFontInfoPreset("D", bank: 1, preset: 4),
        ])!
    }

    var sf3: SoundFontInfo {
        SoundFontInfo("three", url: URL(fileURLWithPath: "SF3.sf2"), presets: [
            SoundFontInfoPreset("Arnold", bank: 1, preset: 1),
            SoundFontInfoPreset("Bach", bank: 1, preset: 2),
            SoundFontInfoPreset("Chris", bank: 1, preset: 3),
            SoundFontInfoPreset("Dallas", bank: 1, preset: 4),
        ])!
    }

    func fetchSoundFonts() -> [SoundFontEntity]? {
        let fetchRequest = SoundFontEntity.sortedFetchRequest
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.resultType = .managedObjectResultType
        return try? context.fetch(fetchRequest)
    }
}

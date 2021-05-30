// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework
import SoundFontInfoLib
import CoreData

public extension XCTestCase {

    typealias TestBlock = (CoreDataTestHarness, NSManagedObjectContext) -> Void

    func doWhenCoreDataReady(_ name: String, createAppState: Bool = true, block: @escaping TestBlock) {
        let testHarness = CoreDataTestHarness()
        let executed = XCTestExpectation(description: name)
        _ = testHarness.stack.availableNotification.registerOnMain { _ in
            if createAppState {
                _ = ManagedAppState.get(context: testHarness.context)
            }
            block(testHarness, testHarness.context)
            executed.fulfill()
        }
        wait(for: [executed], timeout: 1.0)
    }
}

public class TemporaryPersistentContainer: PersistentContainer {

    public enum Kind {
        case on_disk
        case in_memory
    }

    /// Just to be safe, store any files in a unique temporary directory. The can be per-test if configured correctly.
    override public static func defaultDirectoryURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    public init(_ kind: Kind = .in_memory) {
        super.init(modelName: "SoundFonts")
        if kind == .in_memory {
            let psd = NSPersistentStoreDescription()
            psd.type = NSInMemoryStoreType
            persistentStoreDescriptions = [psd]
        }
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

public extension CoreDataTestHarness {

    func fetchEntities<T>() -> [T]? where T: Managed {
        let fetchRequest = T.sortedFetchRequest
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.resultType = .managedObjectResultType
        return try? context.fetch(fetchRequest)
    }

}

public struct CoreDataTestData {

    static let sf1: SoundFontInfo = SoundFontInfo(
        "One", url: URL(fileURLWithPath: "SF1.sf2"),
        author: "Author",
        comment: "Comment",
        copyright: "Copyright",
        presets: [
            SoundFontInfoPreset("One", bank: 1, preset: 1),
            SoundFontInfoPreset("Two", bank: 1, preset: 2),
            SoundFontInfoPreset("Three", bank: 1, preset: 3),
            SoundFontInfoPreset("Four", bank: 1, preset: 4),
            SoundFontInfoPreset("Five", bank: 2, preset: 1),
        ])!

    static let sf2: SoundFontInfo = SoundFontInfo(
        "Two", url: URL(fileURLWithPath: "SF2.sf2"),
        author: "Author",
        comment: "Comment",
        copyright: "Copyright",
        presets: [
            SoundFontInfoPreset("A", bank: 1, preset: 11),
            SoundFontInfoPreset("B", bank: 2, preset: 11),
            SoundFontInfoPreset("C", bank: 3, preset: 11),
        ])!

    static let sf3: SoundFontInfo = SoundFontInfo(
        "Three", url: URL(fileURLWithPath: "SF3.sf2"),
        author: "Author",
        comment: "Comment",
        copyright: "Copyright",
        presets: [
            SoundFontInfoPreset("Arnold", bank: 10, preset: 1),
            SoundFontInfoPreset("Bach", bank: 10, preset: 2),
            SoundFontInfoPreset("Chris", bank: 10, preset: 3),
            SoundFontInfoPreset("Dallas", bank: 10, preset: 4),
        ])!

    static func make(_ name: String) -> SoundFontInfo {
        SoundFontInfo(name, url: URL(fileURLWithPath: "SF3.sf2"),
                      author: "Author",
                      comment: "Comment",
                      copyright: "Copyright",
                      presets: [
                        SoundFontInfoPreset("One", bank: 1, preset: 1),
                        SoundFontInfoPreset("Two", bank: 1, preset: 2),
                        SoundFontInfoPreset("Three", bank: 1, preset: 3),
                        SoundFontInfoPreset("Four", bank: 1, preset: 4),
                      ])!
    }
}

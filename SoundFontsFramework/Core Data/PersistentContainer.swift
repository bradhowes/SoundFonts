// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData

/**
 Customized NSPersistentContainer that knows how to locate and load the managed object model (MOM) resource. It then
 caches this value for future use -- basically useful for unit tests.
 */
public final class PersistentContainer: NSPersistentContainer {

    private static let modelName: String = "SoundFonts"
    private static let bundle = Bundle(for: PersistentContainer.self)
    private static let momUrl = bundle.url(forResource: modelName, withExtension: "momd")!
    private static let mom = NSManagedObjectModel(contentsOf: momUrl)!

    /// Type of persistency we want -- permanent for on-disk, temporary for in-memory
    public enum Kind {
        case permanent
        case temporary
    }

    public init(kind: Kind = .permanent) {
        super.init(name: Self.modelName, managedObjectModel: Self.mom)
        if kind == .temporary {
            let psd = NSPersistentStoreDescription()
            psd.type = NSInMemoryStoreType
            persistentStoreDescriptions = [psd]
        }
    }
}

// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData

/**
 Customized NSPersistentContainer that knows how to locate and load the managed object model (MOM) resource. It then
 caches this value for future use -- basically useful for unit tests.
 */
open class PersistentContainer: NSPersistentContainer {

    private static let modelName: String = "SoundFonts"
    private static let bundle = Bundle(for: PersistentContainer.self)
    private static let momUrl = bundle.url(forResource: modelName, withExtension: "momd")!
    private static let mom = NSManagedObjectModel(contentsOf: momUrl)!

    public init() {
        super.init(name: Self.modelName, managedObjectModel: Self.mom)
    }
}

public extension PersistentContainer {

    typealias LoadStoreError = (NSPersistentStoreDescription, Error)

    func destroyPersistentStores() throws {
        try persistentStoreCoordinator.destroyPersistentStores(persistentStoreDescriptions)
    }

    func removeStores() throws {
        try persistentStoreCoordinator.removeStores()
    }

    func loadPersistentStoresSync() throws {
        persistentStoreDescriptions.forEach { $0.shouldAddStoreAsynchronously = false }

        var errors: [LoadStoreError] = []
        loadPersistentStores { desc, error in
            error.map {errors.append(LoadStoreError(desc, $0))}
        }
        guard errors.isEmpty else { throw CodePointInfo(errors) }
    }

    func loadPersistentStoresAsync(_ block: @escaping (Error?) -> Void) {
        let dg = DispatchGroup()
        persistentStoreDescriptions.forEach {
            dg.enter()
            $0.shouldAddStoreAsynchronously = true
        }

        var errors: [LoadStoreError] = []
        loadPersistentStores { desc, error in
            error.map {errors.append(LoadStoreError(desc, $0))}
            dg.leave()
        }

        dg.notify(queue: .main) {
            let error = errors.isEmpty ? nil : CodePointInfo(errors)
            block(error)
        }
    }
}

extension NSPersistentStoreCoordinator {

    func destroyPersistentStores(_ descriptions: [NSPersistentStoreDescription]) throws {
        try descriptions.forEach { desc in
            try desc.url.map {try destroyPersistentStore(at: $0, ofType: desc.type)}
        }
    }

    func removeStores() throws {
        try persistentStores.forEach { try remove($0) }
    }
}

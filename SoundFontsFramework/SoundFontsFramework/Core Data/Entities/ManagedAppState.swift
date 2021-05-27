// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData

@objc(AppState)
public final class ManagedAppState: NSManagedObject, Managed {

    static var fetchRequest: FetchRequest {
        let request = typedFetchRequest
        request.returnsObjectsAsFaults = false
        request.resultType = .managedObjectResultType
        return request
    }

    @NSManaged private var lastUpdated: Date?
    @NSManaged private var favoritesSet: NSOrderedSet
    @NSManaged public private(set) var soundFonts: NSOrderedSet
}

extension ManagedAppState {

    public static func get(context: NSManagedObjectContext) -> ManagedAppState {
        if let appState: ManagedAppState = context.object(forSingleObjectCacheKey: "AppState") { return appState }
        let appState = findOrCreate(in: context, request: typedFetchRequest) { _ in }
        context.set(appState, forSingleObjectCacheKey: "AppState")
        context.saveChangesAsync()
        return appState
    }
}

extension ManagedAppState {

    public var favorites: EntityCollection<ManagedFavorite> { EntityCollection<ManagedFavorite>(favoritesSet) }

    public func createFavorite(preset: ManagedPreset) -> ManagedFavorite {
        guard let context = managedObjectContext else { fatalError() }
        let fav = ManagedFavorite(in: context, preset: preset)
        self.addToOrderedFavorites(fav)
        context.saveChangesAsync()
        return fav
    }

    public func deleteFavorite(favorite: ManagedFavorite) {
        guard let context = managedObjectContext else { fatalError() }
        self.removeFromFavorites(favorite)
        favorite.delete()
        context.saveChangesAsync()
    }

    public func move(favorite: ManagedFavorite, to newIndex: Int) {
        guard let context = managedObjectContext else { fatalError() }
        let oldIndex = self.favoritesSet.index(of: favorite)
        guard oldIndex >= 0 else { fatalError("favorite is not in collection") }
        guard oldIndex != newIndex else { return }
        guard let mutableFavorites = self.favoritesSet.mutableCopy() as? NSMutableOrderedSet else { fatalError() }
        mutableFavorites.moveObjects(at: IndexSet(integer: oldIndex), to: newIndex)
        self.favoritesSet = mutableFavorites
        context.saveChangesAsync()
    }
}

extension ManagedAppState {

//    public func setActive(preset: ManagedPreset?) {
//        guard let context = managedObjectContext else { fatalError() }
//        self.activePreset?.setActivated(nil)
//        self.activePreset = preset
//        preset?.setActivated(self)
//        context.saveChangesAsync()
//    }
}

private extension ManagedAppState {

    @objc(insertObject:inOrderedFavoritesAtIndex:)
    @NSManaged func insertIntoOrderedFavorites(_ value: ManagedFavorite, at idx: Int)

    @objc(removeObjectFromOrderedFavoritesAtIndex:)
    @NSManaged func removeFromOrderedFavorites(at idx: Int)

    @objc(insertOrderedFavorites:atIndexes:)
    @NSManaged func insertIntoOrderedFavorites(_ values: [ManagedFavorite], at indexes: NSIndexSet)

    @objc(removeOrderedFavoritesAtIndexes:)
    @NSManaged func removeFromOrderedFavorites(at indexes: NSIndexSet)

    @objc(replaceObjectInOrderedFavoritesAtIndex:withObject:)
    @NSManaged func replaceOrderedFavorites(at idx: Int, with value: ManagedFavorite)

    @objc(replaceOrderedFavoritesAtIndexes:withFavorites:)
    @NSManaged func replaceOrderedFavorites(at indexes: NSIndexSet, with values: [ManagedFavorite])

    @objc(addOrderedFavoritesObject:)
    @NSManaged func addToOrderedFavorites(_ value: ManagedFavorite)

    @objc(removeOrderedFavoritesObject:)
    @NSManaged func removeFromFavorites(_ value: ManagedFavorite)

    @objc(addOrderedFavorites:)
    @NSManaged func addToOrderedFavorites(_ values: NSOrderedSet)

    @objc(removeOrderedFavorites:)
    @NSManaged func removeFromFavorites(_ values: NSOrderedSet)
}

// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData

@objc(AppState)
public final class AppState: NSManagedObject, Managed {

    static var fetchRequest: FetchRequest {
        let request = typedFetchRequest
        request.returnsObjectsAsFaults = false
        request.resultType = .managedObjectResultType
        return request
    }

    @NSManaged private var lastUpdated: Date?
    @NSManaged private var orderedFavorites: NSOrderedSet
    @NSManaged public private(set) var activePreset: Preset?
}

extension AppState {
    public static func get(context: NSManagedObjectContext) -> AppState {
        if let appState: AppState = context.object(forSingleObjectCacheKey: "AppState") { return appState }
        let appState = findOrCreate(in: context, request: typedFetchRequest) { _ in }
        context.set(appState, forSingleObjectCacheKey: "AppState")
        context.saveChangesAsync()
        return appState
    }
}

extension AppState {
    public var favorites: EntityCollection<Favorite> { EntityCollection<Favorite>(orderedFavorites) }

    public func createFavorite(preset: Preset, keyboardLowestNote: Int) -> Favorite {
        guard let context = managedObjectContext else { fatalError() }
        let fav = Favorite(in: context, preset: preset, keyboardLowestNote: keyboardLowestNote)
        self.addToOrderedFavorites(fav)
        context.saveChangesAsync()
        return fav
    }

    public func deleteFavorite(favorite: Favorite) {
        guard let context = managedObjectContext else { fatalError() }
        self.removeFromFavorites(favorite)
        favorite.delete()
        context.saveChangesAsync()
    }

    public func move(favorite: Favorite, to newIndex: Int) {
        guard let context = managedObjectContext else { fatalError() }
        let oldIndex = self.orderedFavorites.index(of: favorite)
        guard oldIndex != newIndex else { return }
        let mutableFavorites = self.orderedFavorites.mutableCopy() as! NSMutableOrderedSet
        mutableFavorites.moveObjects(at: IndexSet(integer: oldIndex), to: newIndex)
        self.orderedFavorites = mutableFavorites
        context.saveChangesAsync()
    }
}

extension AppState {
    public func setActive(preset: Preset?) {
        guard let context = managedObjectContext else { fatalError() }
        self.activePreset?.setActivated(nil)
        self.activePreset = preset
        preset?.setActivated(self)
        context.saveChangesAsync()
    }
}

private extension AppState {

    @objc(insertObject:inOrderedFavoritesAtIndex:)
    @NSManaged func insertIntoOrderedFavorites(_ value: Favorite, at idx: Int)

    @objc(removeObjectFromOrderedFavoritesAtIndex:)
    @NSManaged func removeFromOrderedFavorites(at idx: Int)

    @objc(insertOrderedFavorites:atIndexes:)
    @NSManaged func insertIntoOrderedFavorites(_ values: [Favorite], at indexes: NSIndexSet)

    @objc(removeOrderedFavoritesAtIndexes:)
    @NSManaged func removeFromOrderedFavorites(at indexes: NSIndexSet)

    @objc(replaceObjectInOrderedFavoritesAtIndex:withObject:)
    @NSManaged func replaceOrderedFavorites(at idx: Int, with value: Favorite)

    @objc(replaceOrderedFavoritesAtIndexes:withFavorites:)
    @NSManaged func replaceOrderedFavorites(at indexes: NSIndexSet, with values: [Favorite])

    @objc(addOrderedFavoritesObject:)
    @NSManaged func addToOrderedFavorites(_ value: Favorite)

    @objc(removeOrderedFavoritesObject:)
    @NSManaged func removeFromFavorites(_ value: Favorite)

    @objc(addOrderedFavorites:)
    @NSManaged func addToOrderedFavorites(_ values: NSOrderedSet)

    @objc(removeOrderedFavorites:)
    @NSManaged func removeFromFavorites(_ values: NSOrderedSet)
}

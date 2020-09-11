// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData

@objc(AppState)
public final class AppState: NSManagedObject, Managed {

    static var fetchRequest: FetchRequest {
        let fetchRequest = FetchRequest(entityName: entityName)
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.resultType = .managedObjectResultType
        return fetchRequest
    }

    @NSManaged private var lastUpdated: Date?
    @NSManaged private var favorites: NSOrderedSet
    @NSManaged private var activePreset: Preset?
}

extension AppState {

    public static func get(context: NSManagedObjectContext) -> AppState {

        // Use `useInfo` as a cache for the AppState singleton. NOTE: will cause issues when trying to delete it.
        if let appState: AppState = context.object(forSingleObjectCacheKey: "AppState") { return appState }
        let appState = Self.findOrCreate(in: context, matching: nil) {_ in }
        context.set(appState, forSingleObjectCacheKey: "AppState")
        return appState
    }

    public var favoritesCount: Int { favorites.count }

    public func createFavorite(context: NSManagedObjectContext, preset: Preset,
                               keyboardLowestNote: Int) -> Favorite {
        let fav = Favorite(context: context, preset: preset, keyboardLowestNote: keyboardLowestNote)
        addToFavorites(fav)
        return fav
    }

    public func deleteFavorite(favorite: Favorite) {
        removeFromFavorites(favorite)
        favorite.delete()
    }

    public var ordering: EntityCollection<Favorite> { EntityCollection<Favorite>(favorites) }

    public func move(favorite: Favorite, to newIndex: Int) {
        let oldIndex = self.favorites.index(of: favorite)
        guard oldIndex != newIndex else { return }
        let mutableFavorites = favorites.mutableCopy() as! NSMutableOrderedSet
        mutableFavorites.moveObjects(at: IndexSet(integer: oldIndex), to: newIndex)
        self.favorites = mutableFavorites
    }

    public func setActive(preset: Preset) {
        self.activePreset?.setActivated(nil)
        self.activePreset = preset
        preset.setActivated(self)
    }
}

private extension AppState {

    @objc(insertObject:inFavoritesAtIndex:)
    @NSManaged func insertIntoFavorites(_ value: Favorite, at idx: Int)

    @objc(removeObjectFromFavoritesAtIndex:)
    @NSManaged func removeFromFavorites(at idx: Int)

    @objc(insertFavorites:atIndexes:)
    @NSManaged func insertIntoFavorites(_ values: [Favorite], at indexes: NSIndexSet)

    @objc(removeFavoritesAtIndexes:)
    @NSManaged func removeFromFavorites(at indexes: NSIndexSet)

    @objc(replaceObjectInFavoritesAtIndex:withObject:)
    @NSManaged func replaceFavorites(at idx: Int, with value: Favorite)

    @objc(replaceFavoritesAtIndexes:withFavorites:)
    @NSManaged func replaceFavorites(at indexes: NSIndexSet, with values: [Favorite])

    @objc(addFavoritesObject:)
    @NSManaged func addToFavorites(_ value: Favorite)

    @objc(removeFavoritesObject:)
    @NSManaged func removeFromFavorites(_ value: Favorite)

    @objc(addFavorites:)
    @NSManaged func addToFavorites(_ values: NSOrderedSet)

    @objc(removeFavorites:)
    @NSManaged func removeFromFavorites(_ values: NSOrderedSet)
}

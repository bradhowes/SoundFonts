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
    @NSManaged private var activePreset: PresetEntity?
}

extension AppState {

    public static func get(context: NSManagedObjectContext) -> AppState {
        Self.findOrCreate(in: context, matching: nil) {_ in }
    }

    public var favoritesCount: Int { favorites.count }

    public func createFavorite(context: NSManagedObjectContext, preset: PresetEntity,
                               keyboardLowestNote: Int) -> FavoriteEntity {
        let fav = FavoriteEntity(context: context, preset: preset, keyboardLowestNote: keyboardLowestNote)
        addToFavorites(fav)
        return fav
    }

    public func deleteFavorite(favorite: FavoriteEntity) {
        removeFromFavorites(favorite)
        favorite.delete()
    }

    public var ordering: EntityCollection<FavoriteEntity> { EntityCollection(favorites) }

    public func move(favorite: FavoriteEntity, to newIndex: Int) {
        let oldIndex = self.favorites.index(of: favorite)
        guard oldIndex != newIndex else { return }
        let mutableFavorites = favorites.mutableCopy() as! NSMutableOrderedSet
        mutableFavorites.moveObjects(at: IndexSet(integer: oldIndex), to: newIndex)
        self.favorites = mutableFavorites
    }

    public func setActive(preset: PresetEntity) {
        self.activePreset?.setActivated(nil)
        self.activePreset = preset
        preset.setActivated(self)
    }
}

extension AppState {

    @objc(insertObject:inFavoritesAtIndex:)
    @NSManaged private func insertIntoFavorites(_ value: FavoriteEntity, at idx: Int)

    @objc(removeObjectFromFavoritesAtIndex:)
    @NSManaged private func removeFromFavorites(at idx: Int)

    @objc(insertFavorites:atIndexes:)
    @NSManaged private func insertIntoFavorites(_ values: [FavoriteEntity], at indexes: NSIndexSet)

    @objc(removeFavoritesAtIndexes:)
    @NSManaged private func removeFromFavorites(at indexes: NSIndexSet)

    @objc(replaceObjectInFavoritesAtIndex:withObject:)
    @NSManaged private func replaceFavorites(at idx: Int, with value: FavoriteEntity)

    @objc(replaceFavoritesAtIndexes:withFavorites:)
    @NSManaged private func replaceFavorites(at indexes: NSIndexSet, with values: [FavoriteEntity])

    @objc(addFavoritesObject:)
    @NSManaged private func addToFavorites(_ value: FavoriteEntity)

    @objc(removeFavoritesObject:)
    @NSManaged private func removeFromFavorites(_ value: FavoriteEntity)

    @objc(addFavorites:)
    @NSManaged private func addToFavorites(_ values: NSOrderedSet)

    @objc(removeFavorites:)
    @NSManaged private func removeFromFavorites(_ values: NSOrderedSet)

}

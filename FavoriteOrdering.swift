// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData

@objc(FavoriteOrdering)
public final class FavoriteOrdering: NSManagedObject, Managed {

    static var fetchRequest: NSFetchRequest<FavoriteOrdering> {
        let fetchRequest = NSFetchRequest<FavoriteOrdering>(entityName: entityName)
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.resultType = .managedObjectResultType
        return fetchRequest
    }

    @NSManaged private var lastUpdated: Date?
    @NSManaged private var favorites: NSOrderedSet

}

extension FavoriteOrdering {

    public static func get(context: NSManagedObjectContext) -> FavoriteOrdering {
        if let s = try? context.fetch(Self.fetchRequest), !s.isEmpty {
            return s[0]
        }

        return FavoriteOrdering(context: context)
    }

    public var count: Int { favorites.count }

    public func create(context: NSManagedObjectContext, preset: PresetEntity, keyboardLowestNote: Int) -> FavoriteEntity {
        let fav = FavoriteEntity(context: context, preset: preset, keyboardLowestNote: keyboardLowestNote)
        addToFavorites(fav)
        return fav
    }

    public func delete(favorite: FavoriteEntity) {
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
}

extension FavoriteOrdering {

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

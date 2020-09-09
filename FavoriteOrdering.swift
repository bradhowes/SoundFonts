// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData

@objc(FavoriteOrdering)
public final class FavoriteOrdering: NSManagedObject, Managed {

    private static var singleton: FavoriteOrdering?

    @NSManaged private var lastUpdated: Date?
    @NSManaged private var favorites: NSOrderedSet
}

extension FavoriteOrdering {

    public static func get(context: NSManagedObjectContext) -> FavoriteOrdering {
        if let s = Self.singleton { return s }
        if let s = try? context.fetch(Self.fetchRequest), !s.isEmpty {
            Self.singleton = s[0]
            return s[0]
        }

        let s = FavoriteOrdering(context: context)
        Self.singleton = s
        return s
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
    @NSManaged public func insertIntoFavorites(_ value: FavoriteEntity, at idx: Int)

    @objc(removeObjectFromFavoritesAtIndex:)
    @NSManaged public func removeFromFavorites(at idx: Int)

    @objc(insertFavorites:atIndexes:)
    @NSManaged public func insertIntoFavorites(_ values: [FavoriteEntity], at indexes: NSIndexSet)

    @objc(removeFavoritesAtIndexes:)
    @NSManaged public func removeFromFavorites(at indexes: NSIndexSet)

    @objc(replaceObjectInFavoritesAtIndex:withObject:)
    @NSManaged public func replaceFavorites(at idx: Int, with value: FavoriteEntity)

    @objc(replaceFavoritesAtIndexes:withFavorites:)
    @NSManaged public func replaceFavorites(at indexes: NSIndexSet, with values: [FavoriteEntity])

    @objc(addFavoritesObject:)
    @NSManaged public func addToFavorites(_ value: FavoriteEntity)

    @objc(removeFavoritesObject:)
    @NSManaged public func removeFromFavorites(_ value: FavoriteEntity)

    @objc(addFavorites:)
    @NSManaged public func addToFavorites(_ values: NSOrderedSet)

    @objc(removeFavorites:)
    @NSManaged public func removeFromFavorites(_ values: NSOrderedSet)

}

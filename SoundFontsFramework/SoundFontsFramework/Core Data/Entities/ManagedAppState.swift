// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData
import Foundation

@objc(ManagedAppState)
final class ManagedAppState: NSManagedObject, Managed {

  @NSManaged public private(set) var lastUpdated: Date
  @NSManaged private var favorites: NSOrderedSet
  @NSManaged private var soundFonts: NSSet
  @NSManaged private var tags: NSOrderedSet

  static var fetchRequest: FetchRequest {
    let request = typedFetchRequest
    request.returnsObjectsAsFaults = false
    request.resultType = .managedObjectResultType
    return request
  }
}

extension ManagedAppState {

  /// Obtain the ordered collection of favorites
  var favoritesCollection: EntityCollection<ManagedFavorite> { EntityCollection(favorites) }

  /// Obtain the ordered collection of tags
  var tagsCollection: EntityCollection<ManagedTag> { EntityCollection(tags) }

  // swiftlint:disable force_cast
  /// Obtain the set of installed sound fonts. NOTE: that this is unordered.
  var soundFontsSet: Set<ManagedSoundFont> { soundFonts as! Set<ManagedSoundFont> }
  // swiftlint:enable force_cast

  var allTag: ManagedTag { tagsCollection[0] }

  var builtInTag: ManagedTag { tagsCollection[1] }
}

extension ManagedAppState {

  /**
   Fetch the ManagedAppState singleton.

   - parameter context: the Core Data context to work in
   - returns: the ManagedAppState instance
   */
  static func get(context: NSManagedObjectContext) -> ManagedAppState {
    if let appState: ManagedAppState = context.object(forSingleObjectCacheKey: "ManagedAppState") {
      return appState
    }

    let appState = findOrCreate(in: context, request: typedFetchRequest) { appState in
      appState.addToTags(ManagedTag(in: context, name: "All"))
      appState.addToTags(ManagedTag(in: context, name: "Built-In"))
    }

    context.set(appState, forSingleObjectCacheKey: "ManagedAppState")
    context.saveChangesAsync()

    return appState
  }
}

// MARK: Generated accessors for favorites
extension ManagedAppState {

  @objc(insertObject:inFavoritesAtIndex:)
  @NSManaged func insertIntoFavorites(_ value: ManagedFavorite, at idx: Int)

  @objc(removeObjectFromFavoritesAtIndex:)
  @NSManaged func removeFromFavorites(at idx: Int)

  @objc(addFavoritesObject:)
  @NSManaged func addToFavorites(_ value: ManagedFavorite)

  @objc(removeFavoritesObject:)
  @NSManaged func removeFromFavorites(_ value: ManagedFavorite)
}

// MARK: Generated accessors for soundFonts
extension ManagedAppState {

  @objc(addSoundFontsObject:)
  @NSManaged func addToSoundFonts(_ value: ManagedSoundFont)

  @objc(removeSoundFontsObject:)
  @NSManaged func removeFromSoundFonts(_ value: ManagedSoundFont)
}

// MARK: Generated accessors for tags
extension ManagedAppState {

  @objc(insertObject:inTagsAtIndex:)
  @NSManaged func insertIntoTags(_ value: ManagedTag, at idx: Int)

  @objc(removeObjectFromTagsAtIndex:)
  @NSManaged func removeFromTags(at idx: Int)

  @objc(addTagsObject:)
  @NSManaged func addToTags(_ value: ManagedTag)

  @objc(removeTagsObject:)
  @NSManaged func removeFromTags(_ value: ManagedTag)
}

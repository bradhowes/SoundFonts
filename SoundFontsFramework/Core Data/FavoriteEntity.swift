// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData

@objc(FavoriteEntity)
public class FavoriteEntity: NSManagedObject {

}

extension FavoriteEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FavoriteEntity> {
        return NSFetchRequest<FavoriteEntity>(entityName: "Favorite")
    }

    @NSManaged public var gain: Float
    @NSManaged public var keyboardLowestNote: Int16
    @NSManaged public var name: String?
    @NSManaged public var pan: Float
    @NSManaged public var key: UUID?
    @NSManaged public var patch: PatchEntity?
}

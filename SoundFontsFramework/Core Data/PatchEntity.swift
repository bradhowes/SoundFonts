// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData
import SoundFontInfoLib

@objc(PatchEntity)
public class PatchEntity: NSManagedObject {

}

extension PatchEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PatchEntity> {
        return NSFetchRequest<PatchEntity>(entityName: "Patch")
    }

    @NSManaged public var bank: Int16
    @NSManaged public var embeddedName: String
    @NSManaged public var preset: Int16
    @NSManaged public var visible: Bool
    @NSManaged public var displayName: String
    @NSManaged public var alias: FavoriteEntity?
    @NSManaged public var soundFont: SoundFontEntity
}

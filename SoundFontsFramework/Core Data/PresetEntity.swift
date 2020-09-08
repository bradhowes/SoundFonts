// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData
import SoundFontInfoLib

@objc(PatchEntity)
public class PresetEntity: NSManagedObject {

}

extension PresetEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PresetEntity> {
        NSFetchRequest<PresetEntity>(entityName: "Preset")
    }

    public convenience init(context: NSManagedObjectContext, config: SoundFontInfoPreset) {
        self.init(context: context)
        name = config.name
        originalName = config.name
        bank = Int16(config.bank)
        preset = Int16(config.preset)
        visible = true
        alias = nil
    }

    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var originalName: String
    @NSManaged public private(set) var bank: Int16
    @NSManaged public private(set) var preset: Int16
    @NSManaged public private(set) var visible: Bool
    @NSManaged public private(set) var alias: FavoriteEntity?
    @NSManaged public private(set) var soundFont: SoundFontEntity?
}

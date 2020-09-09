// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData
import SoundFontInfoLib

@objc(PatchEntity)
public class PresetEntity: NSManagedObject, Managed {
    public static let defaultSortDescriptors: [NSSortDescriptor] = {
        let sortDescriptor = NSSortDescriptor(key: "orderIndex", ascending: true)
        return [sortDescriptor]
    }()
}

extension PresetEntity {

    @NSManaged public private(set) var orderIndex: Int16
    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var originalName: String
    @NSManaged public private(set) var bank: Int16
    @NSManaged public private(set) var preset: Int16
    @NSManaged public private(set) var visible: Bool
    @NSManaged public private(set) var alias: FavoriteEntity?
    @NSManaged public private(set) var soundFont: SoundFontEntity

    public convenience init(context: NSManagedObjectContext, index: Int, config: SoundFontInfoPreset) {
        self.init(context: context)
        self.orderIndex = Int16(index)
        self.name = config.name
        self.originalName = config.name
        self.bank = Int16(config.bank)
        self.preset = Int16(config.preset)
        self.visible = true
        self.alias = nil
    }

    public func setName(_ name: String) {
        self.name = name
    }

    public func setVisibility(_ value: Bool) {
        self.visible = value
    }
}

// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData
import SoundFontInfoLib

@objc(SoundFontEntity)
public final class SoundFontEntity: NSManagedObject {

}

extension SoundFontEntity: Managed {

    public static var defaultSortDescriptors: [NSSortDescriptor] = {
        let sortDescriptor = NSSortDescriptor(key: "displayName", ascending: true,
                                              selector: #selector(NSString.localizedCaseInsensitiveCompare))
        return [sortDescriptor]
    }()

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SoundFontEntity> {
        return NSFetchRequest<SoundFontEntity>(entityName: "SoundFont")
    }

    public convenience init(context: NSManagedObjectContext, config: SoundFontInfo) {
        self.init(context: context)

        soundFontKey = UUID()
        name = config.embeddedName
        embeddedName = config.embeddedName
        path = config.path

        config.presets.forEach { config in
            addToPresets(PresetEntity(context: context, config: config))
        }
    }

    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var path: URL
    @NSManaged public private(set) var soundFontKey: UUID
    @NSManaged public private(set) var embeddedName: String
    @NSManaged public private(set) var presets: NSOrderedSet
}

extension SoundFontEntity {

    @objc(addPresetsObject:)
    @NSManaged private func addToPresets(_ value: PresetEntity)
}

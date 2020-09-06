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

    convenience init(context: NSManagedObjectContext, config: SoundFontInfo) {
        self.init(context: context)

        let key = UUID()
        soundFontKey = key
        displayName = config.embeddedName
        embeddedName = config.embeddedName
        
        config.patches.forEach { config in
            let patch = PatchEntity(context: context)
            patch.bank = Int16(config.bank)
            patch.preset = Int16(config.preset)
            patch.embeddedName = config.name
            patch.displayName = config.name
            patch.alias = nil
            addToPatches(patch)
        }
    }

    @NSManaged private(set) var displayName: String
    @NSManaged private(set) var path: URL
    @NSManaged private(set) var soundFontKey: UUID
    @NSManaged private(set) var embeddedName: String
    @NSManaged private(set) var patches: NSOrderedSet
}

extension SoundFontEntity {

    @objc(addPatchesObject:)
    @NSManaged private func addToPatches(_ value: PatchEntity)
}

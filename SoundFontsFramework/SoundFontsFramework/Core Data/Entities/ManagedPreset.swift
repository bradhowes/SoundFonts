// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData
import SoundFontInfoLib

@objc(Preset)
public final class ManagedPreset: NSManagedObject, Managed {
    @NSManaged public private(set) var displayName: String?
    @NSManaged public private(set) var embeddedName: String?
    @NSManaged public private(set) var bank: Int16
    @NSManaged public private(set) var patch: Int16
    @NSManaged public private(set) var index: Int16
    @NSManaged public private(set) var configuration: ManagedPresetConfig
    @NSManaged public private(set) var alias: NSSet
    @NSManaged public private(set) var parent: ManagedSoundFont
}

extension ManagedPreset {

    @discardableResult
    public convenience init(in context: NSManagedObjectContext, owner: ManagedSoundFont, index: Int,
                            config: SoundFontInfoPreset) {
        self.init(context: context)
        self.displayName = config.name
        self.embeddedName = config.name
        self.bank = Int16(config.bank)
        self.patch = Int16(config.preset)
        self.index = Int16(index)
        self.configuration = ManagedPresetConfig(context: context)
        self.configuration.ownedByPreset = self
        self.alias = NSSet()
        self.parent = owner

        context.saveChangesAsync()
    }

    public func setName(_ value: String) { displayName = value }

    // swiftlint:disable empty_count
    public var hasFavorite: Bool { alias.count != 0 }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedPreset> {
        return NSFetchRequest<ManagedPreset>(entityName: "Preset")
    }

    @objc(addAliasObject:)
    @NSManaged public func addToAlias(_ value: ManagedFavorite)

    @objc(removeAliasObject:)
    @NSManaged public func removeFromAlias(_ value: ManagedFavorite)

    @objc(addAlias:)
    @NSManaged public func addToAlias(_ values: NSSet)

    @objc(removeAlias:)
    @NSManaged public func removeFromAlias(_ values: NSSet)
}

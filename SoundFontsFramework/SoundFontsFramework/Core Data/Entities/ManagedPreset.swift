// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData
import Foundation
import SoundFontInfoLib

@objc(ManagedPreset)
public final class ManagedPreset: NSManagedObject, Managed {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedPreset> {
    return NSFetchRequest<ManagedPreset>(entityName: "ManagedPreset")
  }

  @NSManaged public var displayName: String
  @NSManaged public private(set) var embeddedName: String
  @NSManaged public private(set) var bank: Int16
  @NSManaged public private(set) var patch: Int16
  @NSManaged public private(set) var aliases: NSSet
  @NSManaged public private(set) var configuration: ManagedPresetConfig
  @NSManaged public private(set) var parent: ManagedSoundFont

  @discardableResult
  public convenience init(
    in context: NSManagedObjectContext, owner: ManagedSoundFont, config: SoundFontInfoPreset
  ) {
    self.init(context: context)
    self.displayName = config.name
    self.embeddedName = config.name
    self.bank = Int16(config.bank)
    self.patch = Int16(config.preset)
    self.configuration = ManagedPresetConfig(context: context)
    self.configuration.ownedByPreset = self
    self.aliases = NSSet()
    self.parent = owner

    context.saveChangesAsync()
  }
}

// MARK: Generated accessors for alias
extension ManagedPreset {

  @objc(addAliasesObject:)
  @NSManaged public func addToAliases(_ value: ManagedFavorite)

  @objc(removeAliasesObject:)
  @NSManaged public func removeFromAliases(_ value: ManagedFavorite)

  @objc(addAliases:)
  @NSManaged public func addToAliases(_ values: NSSet)

  @objc(removeAliases:)
  @NSManaged public func removeFromAliases(_ values: NSSet)

}

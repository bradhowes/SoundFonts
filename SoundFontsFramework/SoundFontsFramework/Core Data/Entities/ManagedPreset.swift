// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData
import Foundation
import SoundFontInfoLib

@objc(ManagedPreset)
final class ManagedPreset: NSManagedObject, Managed {

  @nonobjc class func fetchRequest() -> NSFetchRequest<ManagedPreset> {
    return NSFetchRequest<ManagedPreset>(entityName: "ManagedPreset")
  }

  @NSManaged var displayName: String
  @NSManaged private(set) var embeddedName: String
  @NSManaged private(set) var bank: Int16
  @NSManaged private(set) var program: Int16
  @NSManaged private(set) var aliases: NSSet
  @NSManaged private(set) var configuration: ManagedPresetConfig
  @NSManaged private(set) var parent: ManagedSoundFont

  @discardableResult
  convenience init(
    in context: NSManagedObjectContext, owner: ManagedSoundFont, config: SoundFontInfoPreset
  ) {
    self.init(context: context)
    self.displayName = config.name
    self.embeddedName = config.name
    self.bank = Int16(config.bank)
    self.program = Int16(config.program)
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
  @NSManaged func addToAliases(_ value: ManagedFavorite)

  @objc(removeAliasesObject:)
  @NSManaged func removeFromAliases(_ value: ManagedFavorite)

  @objc(addAliases:)
  @NSManaged func addToAliases(_ values: NSSet)

  @objc(removeAliases:)
  @NSManaged func removeFromAliases(_ values: NSSet)

}

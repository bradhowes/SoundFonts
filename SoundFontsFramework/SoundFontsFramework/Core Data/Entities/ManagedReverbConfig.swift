//
//  ReverbConfig+CoreDataClass.swift
//  SoundFontsFramework
//
//  Created by Brad Howes on 26/5/21.
//  Copyright © 2021 Brad Howes. All rights reserved.
//
//

import CoreData
import Foundation

@objc(ManagedReverbConfig)
class ManagedReverbConfig: NSManagedObject, Managed {

  @nonobjc class func fetchRequest() -> NSFetchRequest<ManagedReverbConfig> {
    return NSFetchRequest<ManagedReverbConfig>(entityName: "ManagedReverbConfig")
  }

  @NSManaged var enabled: Bool
  @NSManaged var presetIndex: Int16
  @NSManaged var wetDryMix: Float
  @NSManaged var ownedBy: ManagedPresetConfig?

  @discardableResult
  convenience init(
    in context: NSManagedObjectContext, owner: ManagedPresetConfig,
    basis: ManagedReverbConfig
  ) {
    self.init(context: context)
    self.presetIndex = basis.presetIndex
    self.wetDryMix = basis.wetDryMix
    self.enabled = basis.enabled
    self.ownedBy = owner
  }
}

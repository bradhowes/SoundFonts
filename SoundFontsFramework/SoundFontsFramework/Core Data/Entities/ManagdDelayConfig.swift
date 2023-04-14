// Copyright © 2021 Brad Howes. All rights reserved.

import CoreData
import Foundation

@objc(ManagedDelayConfig)
final class ManagedDelayConfig: NSManagedObject, Managed {

  @NSManaged var time: Float
  @NSManaged var feedback: Float
  @NSManaged var cutoff: Float
  @NSManaged var wetDryMix: Float
  @NSManaged var enabled: Bool
  @NSManaged var ownedBy: ManagedPresetConfig

  @nonobjc class func fetchRequest() -> NSFetchRequest<ManagedDelayConfig> {
    return NSFetchRequest<ManagedDelayConfig>(entityName: "ManagedDelayConfig")
  }

  @discardableResult
  convenience init(
    in context: NSManagedObjectContext, owner: ManagedPresetConfig,
    basis: ManagedDelayConfig
  ) {
    self.init(context: context)
    self.time = basis.time
    self.feedback = basis.feedback
    self.cutoff = basis.cutoff
    self.wetDryMix = basis.wetDryMix
    self.enabled = basis.enabled
    self.ownedBy = owner
  }

  @discardableResult
  convenience init(
    in context: NSManagedObjectContext, owner: ManagedPresetConfig,
    time: Float, feedback: Float, cutoff: Float, wetDryMix: Float,
    enabled: Bool
  ) {
    self.init(context: context)
    self.time = time
    self.feedback = feedback
    self.cutoff = cutoff
    self.wetDryMix = wetDryMix
    self.enabled = enabled
    self.ownedBy = owner
  }
}

// Copyright © 2021 Brad Howes. All rights reserved.

import CoreData
import Foundation

@objc(ManagedDelayConfig)
public final class ManagedDelayConfig: NSManagedObject, Managed {

  @NSManaged public var time: Float
  @NSManaged public var feedback: Float
  @NSManaged public var cutoff: Float
  @NSManaged public var wetDryMix: Float
  @NSManaged public var enabled: Bool
  @NSManaged public var ownedBy: ManagedPresetConfig

  @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedDelayConfig> {
    return NSFetchRequest<ManagedDelayConfig>(entityName: "ManagedDelayConfig")
  }

  @discardableResult
  internal convenience init(
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
  internal convenience init(
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

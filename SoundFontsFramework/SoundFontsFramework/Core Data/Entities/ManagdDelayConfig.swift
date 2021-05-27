// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation
import CoreData

@objc(DelayConfig)
public final class ManagedDelayConfig: NSManagedObject, Managed {

    @NSManaged public var time: Float
    @NSManaged public var feedback: Float
    @NSManaged public var cutoff: Float
    @NSManaged public var wetDryMix: Float
    @NSManaged public var enabled: Bool
    @NSManaged public var ownedBy: ManagedPresetConfig

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedDelayConfig> {
        return NSFetchRequest<ManagedDelayConfig>(entityName: "DelayConfig")
    }

    @discardableResult
    internal convenience init(in context: NSManagedObjectContext, owner: ManagedPresetConfig,
                              basis: ManagedDelayConfig) {
        self.init(context: context)
        self.time = basis.time
        self.feedback = basis.feedback
        self.cutoff = basis.cutoff
        self.wetDryMix = basis.wetDryMix
        self.enabled = basis.enabled
        self.ownedBy = owner
    }
}

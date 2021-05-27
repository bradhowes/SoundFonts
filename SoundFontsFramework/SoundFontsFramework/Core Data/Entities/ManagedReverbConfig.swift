//
//  ReverbConfig+CoreDataClass.swift
//  SoundFontsFramework
//
//  Created by Brad Howes on 26/5/21.
//  Copyright © 2021 Brad Howes. All rights reserved.
//
//

import Foundation
import CoreData

@objc(ReverbConfig)
public class ManagedReverbConfig: NSManagedObject, Managed {
    @NSManaged public var presetIndex: Int16
    @NSManaged public var wetDryMix: Float
    @NSManaged public var enabled: Bool
    @NSManaged public var ownedBy: ManagedPresetConfig

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedReverbConfig> {
        return NSFetchRequest<ManagedReverbConfig>(entityName: "ReverbConfig")
    }

    @discardableResult
    internal convenience init(in context: NSManagedObjectContext, owner: ManagedPresetConfig,
                              basis: ManagedReverbConfig) {
        self.init(context: context)
        self.presetIndex = basis.presetIndex
        self.wetDryMix = basis.wetDryMix
        self.enabled = basis.enabled
        self.ownedBy = owner
    }
}

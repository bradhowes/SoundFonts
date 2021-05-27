//
//  PresetConfig+CoreDataClass.swift
//  SoundFontsFramework
//
//  Created by Brad Howes on 26/5/21.
//  Copyright © 2021 Brad Howes. All rights reserved.
//
//

import Foundation
import CoreData

@objc(PresetConfig)
public class ManagedPresetConfig: NSManagedObject, Managed {
    @NSManaged public var gain: Float
    @NSManaged public var pan: Float
    @NSManaged public var hidden: Bool
    @NSManaged public var keyboardLowestNote: Int16
    @NSManaged public var keyboardLowestNoteEnabled: Bool
    @NSManaged public var pitchBendRange: Int16
    @NSManaged public var tuning: Float
    @NSManaged public var tuningEnabled: Bool
    @NSManaged public var userNotes: String?
    @NSManaged public var delayConfig: ManagedDelayConfig?
    @NSManaged public var reverbConfig: ManagedReverbConfig?
    @NSManaged public var ownedByFavorite: ManagedFavorite?
    @NSManaged public var ownedByPreset: ManagedPreset?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedPresetConfig> {
        return NSFetchRequest<ManagedPresetConfig>(entityName: "PresetConfig")
    }

    @discardableResult
    internal convenience init(in context: NSManagedObjectContext, basis: ManagedPresetConfig) {
        self.init(context: context)
        self.gain = basis.gain
        self.pan = basis.pan
        self.hidden = false
        self.keyboardLowestNote = basis.keyboardLowestNote
        self.keyboardLowestNoteEnabled = basis.keyboardLowestNoteEnabled
        self.pitchBendRange = basis.pitchBendRange
        self.tuning = basis.tuning
        self.tuningEnabled = basis.tuningEnabled
        self.userNotes = ""

        if let delayConfig = basis.delayConfig {
            self.delayConfig = ManagedDelayConfig(in: context, owner: self, basis: delayConfig)
        }

        if let reverbConfig = basis.reverbConfig {
            self.reverbConfig = ManagedReverbConfig(in: context, owner: self, basis: reverbConfig)
        }

        context.saveChangesAsync()
    }
}

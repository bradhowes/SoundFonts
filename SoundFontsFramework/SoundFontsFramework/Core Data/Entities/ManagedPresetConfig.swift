//
//  PresetConfig+CoreDataClass.swift
//  SoundFontsFramework
//
//  Created by Brad Howes on 26/5/21.
//  Copyright © 2021 Brad Howes. All rights reserved.
//
//

import CoreData
import Foundation

@objc(ManagedPresetConfig)
class ManagedPresetConfig: NSManagedObject, Managed {

  static var fetchRequest: FetchRequest {
    let request = typedFetchRequest
    request.returnsObjectsAsFaults = false
    request.resultType = .managedObjectResultType
    return request
  }

  @NSManaged var gain: Float
  @NSManaged var hidden: Bool
  @NSManaged var keyboardLowestNote: Int16
  @NSManaged var keyboardLowestNoteEnabled: Bool
  @NSManaged var pan: Float
  @NSManaged var pitchBendRange: Int16
  @NSManaged var tuning: Float
  @NSManaged var tuningEnabled: Bool
  @NSManaged var userNotes: String?
  @NSManaged var delayConfig: ManagedDelayConfig?
  @NSManaged var ownedByFavorite: ManagedFavorite?
  @NSManaged var ownedByPreset: ManagedPreset?
  @NSManaged var reverbConfig: ManagedReverbConfig?

  @discardableResult
  convenience init(
    in context: NSManagedObjectContext, basis: ManagedPresetConfig, owner: ManagedPreset
  ) {
    self.init(context: context)
    self.ownedByPreset = owner
    self.initialize(in: context, with: basis)
  }

  @discardableResult
  convenience init(
    in context: NSManagedObjectContext, basis: ManagedPresetConfig, owner: ManagedFavorite
  ) {
    self.init(context: context)
    self.ownedByFavorite = owner
    self.initialize(in: context, with: basis)
  }

  private func initialize(in context: NSManagedObjectContext, with basis: ManagedPresetConfig) {
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

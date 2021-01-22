// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData
import SoundFontInfoLib

@objc(Favorite)
public final class Favorite: NSManagedObject, Managed {
    @NSManaged public private(set) var uuid: UUID
    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var gain: Float
    @NSManaged public private(set) var pan: Float
    @NSManaged public private(set) var keyboardLowestNote: Int16
    @NSManaged public private(set) var preset: Preset
    @NSManaged public private(set) var orderedBy: AppState
}

extension Favorite {

    @discardableResult
    internal convenience init(in context: NSManagedObjectContext, preset: Preset, keyboardLowestNote: Int) {
        self.init(context: context)
        self.uuid = UUID()
        self.name = preset.name
        self.keyboardLowestNote = Int16(keyboardLowestNote)
        self.preset = preset
        self.gain = 0.0
        self.pan = 0.0
        context.saveChangesAsync()
    }

    @discardableResult
    internal convenience init(in context: NSManagedObjectContext, import legacyFavorite: LegacyFavorite,
                              preset: Preset) {
        self.init(context: context)
        self.uuid = legacyFavorite.key
        self.name = legacyFavorite.name
        self.keyboardLowestNote = Int16(legacyFavorite.presetConfig.keyboardLowestNote?.midiNoteValue ?? 64)
        self.preset = preset
        self.gain = legacyFavorite.presetConfig.gain
        self.pan = legacyFavorite.presetConfig.pan
        context.saveChangesAsync()
    }

    public func setName(_ value: String) { name = value }
    public func setGain(_ value: Float) { gain = value }
    public func setPan(_ value: Float) { pan = value }
    public func setKeyboardLowestNote(_ value: Int) { keyboardLowestNote = Int16(value) }
}

// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData
import SoundFontInfoLib

@objc(FavoriteEntity)
public final class FavoriteEntity: NSManagedObject, Managed {
}

extension FavoriteEntity {

    @NSManaged public private(set) var key: UUID
    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var gain: Float
    @NSManaged public private(set) var pan: Float
    @NSManaged public private(set) var keyboardLowestNote: Int16
    @NSManaged public private(set) var preset: PresetEntity
    @NSManaged public private(set) var orderedBy: AppState

    @discardableResult
    internal convenience init(context: NSManagedObjectContext, preset: PresetEntity, keyboardLowestNote: Int) {
        self.init(context: context)
        self.key = UUID()
        self.name = preset.name
        self.keyboardLowestNote = Int16(keyboardLowestNote)
        self.preset = preset
        self.gain = 0.0
        self.pan = 0.0
    }

    public func setName(_ value: String) { name = value }
    public func setGain(_ value: Float) { gain = value }
    public func setPan(_ value: Float) { pan = value }
    public func setKeyboardLowestNote(_ value: Int) { keyboardLowestNote = Int16(value) }
}

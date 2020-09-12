// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData
import SoundFontInfoLib

@objc(Preset)
public final class Preset: NSManagedObject, Managed {
    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var embeddedName: String
    @NSManaged public private(set) var bank: Int16
    @NSManaged public private(set) var preset: Int16
    @NSManaged public private(set) var visible: Bool
    @NSManaged public private(set) var alias: Favorite?
    @NSManaged public private(set) var parent: SoundFont
    @NSManaged public private(set) var activated: AppState?
}

extension Preset {

    @discardableResult
    public convenience init(in context: NSManagedObjectContext, config: SoundFontInfoPreset) {
        self.init(context: context)
        self.name = config.name
        self.embeddedName = config.name
        self.bank = Int16(config.bank)
        self.preset = Int16(config.preset)
        self.visible = true
        self.alias = nil
        context.saveChangesAsync()
    }

    @discardableResult
    public convenience init(in context: NSManagedObjectContext, import patch: LegacyPatch) {
        self.init(context: context)
        self.name = patch.name
        self.embeddedName = patch.name
        self.bank = Int16(patch.bank)
        self.preset = Int16(patch.program)
        self.visible = true
        self.alias = nil
        context.saveChangesAsync()
    }

    public func setName(_ value: String) { name = value }
    public func setVisibility(_ value: Bool) { visible = value }
    public func setActivated(_ value: AppState?) { activated = value }
    public var hasFavorite: Bool { alias != nil }
}

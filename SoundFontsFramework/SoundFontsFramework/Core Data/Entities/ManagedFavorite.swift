// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData
import SoundFontInfoLib

@objc(Favorite)
public final class ManagedFavorite: NSManagedObject, Managed {
    @NSManaged public var displayName: String?
    @NSManaged public var configuration: ManagedPresetConfig?
    @NSManaged public var orderedBy: ManagedAppState
    @NSManaged public var preset: ManagedPreset
}

extension ManagedFavorite {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedFavorite> {
        return NSFetchRequest<ManagedFavorite>(entityName: "Favorite")
    }

    @discardableResult
    internal convenience init(in context: NSManagedObjectContext, preset: ManagedPreset) {
        self.init(context: context)
        self.displayName = preset.displayName
        self.preset = preset
        self.configuration = ManagedPresetConfig(in: context, basis: preset.configuration)
        self.configuration?.ownedByFavorite = self
        context.saveChangesAsync()
    }

    public func setName(_ value: String) { displayName = value }
}

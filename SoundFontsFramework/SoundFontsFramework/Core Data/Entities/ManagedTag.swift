// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData
import SoundFontInfoLib

@objc(Tag)
public final class ManagedTag: NSManagedObject, Managed {
    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var tagged: NSSet
}

extension ManagedTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedTag> {
        return NSFetchRequest<ManagedTag>(entityName: "Tag")
    }

    @discardableResult
    internal convenience init(in context: NSManagedObjectContext, name: String) {
        self.init(context: context)
        self.name = name
        context.saveChangesAsync()
    }

    @discardableResult
    internal convenience init(in context: NSManagedObjectContext, import legacyTag: LegacyTag) {
        self.init(context: context)
        self.name = legacyTag.name
        context.saveChangesAsync()
    }

    public func setName(_ value: String) { name = value }
}

extension ManagedTag {
    @objc(addTaggedObject:)
    @NSManaged public func addToTagged(_ value: ManagedSoundFont)

    @objc(removeTaggedObject:)
    @NSManaged public func removeFromTagged(_ value: ManagedSoundFont)

    @objc(addTagged:)
    @NSManaged public func addToTagged(_ values: NSSet)

    @objc(removeTagged:)
    @NSManaged public func removeFromTagged(_ values: NSSet)
}

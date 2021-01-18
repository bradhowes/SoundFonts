// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData
import SoundFontInfoLib

@objc(Tag)
public final class Tag: NSManagedObject, Managed {
    @NSManaged public private(set) var uuid: UUID
    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var tagged: NSSet
}

extension Tag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    @discardableResult
    internal convenience init(in context: NSManagedObjectContext, name: String) {
        self.init(context: context)
        self.uuid = UUID()
        self.name = name
        context.saveChangesAsync()
    }

    @discardableResult
    internal convenience init(in context: NSManagedObjectContext, import legacyTag: LegacyTag) {
        self.init(context: context)
        self.uuid = legacyTag.key
        self.name = legacyTag.name
        context.saveChangesAsync()
    }

    public func setName(_ value: String) { name = value }
}

extension Tag {
    @objc(addTaggedObject:)
    @NSManaged public func addToTagged(_ value: SoundFont)

    @objc(removeTaggedObject:)
    @NSManaged public func removeFromTagged(_ value: SoundFont)

    @objc(addTagged:)
    @NSManaged public func addToTagged(_ values: NSSet)

    @objc(removeTagged:)
    @NSManaged public func removeFromTagged(_ values: NSSet)
}

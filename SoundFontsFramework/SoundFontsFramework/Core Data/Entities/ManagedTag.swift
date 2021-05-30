// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData
import Foundation
import SoundFontInfoLib

@objc(ManagedTag)
public final class ManagedTag: NSManagedObject, Managed {
  @NSManaged public var name: String
  @NSManaged public var tagged: NSSet
}

extension ManagedTag {

  public static var defaultSortDescriptors: [NSSortDescriptor] = {
    let sortDescriptor = NSSortDescriptor(
      key: "name", ascending: true,
      selector: #selector(NSString.localizedCaseInsensitiveCompare))
    return [sortDescriptor]
  }()

  public static var fetchRequestForRows: FetchRequest { typedFetchRequest }

  @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedTag> {
    return NSFetchRequest<ManagedTag>(entityName: "ManagedTag")
  }

  @discardableResult
  public convenience init(in context: NSManagedObjectContext, name: String) {
    self.init(context: context)
    self.name = name
    context.saveChangesAsync()
  }

  public static func countRows(in context: NSManagedObjectContext) -> Int {
    return count(in: context, request: fetchRequestForRows)
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

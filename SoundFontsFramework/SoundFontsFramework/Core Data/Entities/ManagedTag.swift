// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData
import Foundation
import SoundFontInfoLib

@objc(ManagedTag)
final class ManagedTag: NSManagedObject, Managed {
  @NSManaged public var name: String
  @NSManaged public var tagged: NSSet
}

extension ManagedTag {

  static var defaultSortDescriptors: [NSSortDescriptor] = {
    let sortDescriptor = NSSortDescriptor(
      key: "name", ascending: true,
      selector: #selector(NSString.localizedCaseInsensitiveCompare))
    return [sortDescriptor]
  }()

  static var fetchRequestForRows: FetchRequest { typedFetchRequest }

  @nonobjc class func fetchRequest() -> NSFetchRequest<ManagedTag> {
    return NSFetchRequest<ManagedTag>(entityName: "ManagedTag")
  }

  @discardableResult
  convenience init(in context: NSManagedObjectContext, name: String) {
    self.init(context: context)
    self.name = name
    context.saveChangesAsync()
  }

  static func countRows(in context: NSManagedObjectContext) -> Int {
    return count(in: context, request: fetchRequestForRows)
  }

  func setName(_ value: String) { name = value }
}

extension ManagedTag {
  @objc(addTaggedObject:)
  @NSManaged func addToTagged(_ value: ManagedSoundFont)

  @objc(removeTaggedObject:)
  @NSManaged func removeFromTagged(_ value: ManagedSoundFont)

  @objc(addTagged:)
  @NSManaged func addToTagged(_ values: NSSet)

  @objc(removeTagged:)
  @NSManaged func removeFromTagged(_ values: NSSet)
}

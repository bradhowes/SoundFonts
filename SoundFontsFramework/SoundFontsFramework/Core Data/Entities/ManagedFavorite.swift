// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData
import Foundation
import SoundFontInfoLib

@objc(ManagedFavorite)
final class ManagedFavorite: NSManagedObject, Managed {

  static var fetchRequest: FetchRequest {
    let request = typedFetchRequest
    request.returnsObjectsAsFaults = false
    request.resultType = .managedObjectResultType
    return request
  }

  @NSManaged var displayName: String?
  @NSManaged var configuration: ManagedPresetConfig
  @NSManaged var orderedBy: ManagedAppState
  @NSManaged var preset: ManagedPreset
}

extension ManagedFavorite {

  @discardableResult
  convenience init(in context: NSManagedObjectContext, preset: ManagedPreset) {
    self.init(context: context)
    self.displayName = preset.displayName
    self.preset = preset
    self.configuration = ManagedPresetConfig(in: context, basis: preset.configuration, owner: self)
    context.saveChangesAsync()
  }

  static var fetchRequestForRows: FetchRequest {
    typedFetchRequest
  }

  static func countRows(in context: NSManagedObjectContext) -> Int {
    return count(in: context, request: fetchRequestForRows)
  }
}

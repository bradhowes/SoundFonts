// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData
import Foundation
import SoundFontInfoLib

@objc(ManagedFavorite)
public final class ManagedFavorite: NSManagedObject, Managed {

  static var fetchRequest: FetchRequest {
    let request = typedFetchRequest
    request.returnsObjectsAsFaults = false
    request.resultType = .managedObjectResultType
    return request
  }

  @NSManaged public var displayName: String?
  @NSManaged public var configuration: ManagedPresetConfig
  @NSManaged public var orderedBy: ManagedAppState
  @NSManaged public var preset: ManagedPreset
}

extension ManagedFavorite {

  @discardableResult
  public convenience init(in context: NSManagedObjectContext, preset: ManagedPreset) {
    self.init(context: context)
    self.displayName = preset.displayName
    self.preset = preset
    self.configuration = ManagedPresetConfig(in: context, basis: preset.configuration, owner: self)
    context.saveChangesAsync()
  }

  public static var fetchRequestForRows: FetchRequest {
    typedFetchRequest
  }

  public static func countRows(in context: NSManagedObjectContext) -> Int {
    return count(in: context, request: fetchRequestForRows)
  }
}

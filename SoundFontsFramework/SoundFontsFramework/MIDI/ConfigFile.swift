// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import os

enum ConfigFileError: Error {
  case nilManager
}

internal protocol ConfigFileManager: AnyObject {
  var filename: String { get }
  func configurationData() throws -> Any
  func loadConfigurationData(contents: Any) throws
}

internal class ConfigFile<T>: UIDocument where T: ConfigFileManager {
  private weak var manager: ConfigFileManager?

  internal init(manager: ConfigFileManager) {
    self.manager = manager
    let sharedArchivePath = FileManager.default.sharedPath(for: manager.filename)
    super.init(fileURL: sharedArchivePath)
    initialize(sharedArchivePath)
  }

  private func initialize(_ sharedArchivePath: URL) {
    self.open { ok in
      if !ok {
        self.save(to: sharedArchivePath, for: .forCreating)
      }
    }
  }

  override public func contents(forType typeName: String) throws -> Any {
    guard let manager = manager else { throw ConfigFileError.nilManager }
    return try manager.configurationData()
  }

  override public func load(fromContents contents: Any, ofType typeName: String?) throws {
    guard let manager = manager else { throw ConfigFileError.nilManager }
    try manager.loadConfigurationData(contents: contents)
  }

  override public func revert(toContentsOf url: URL, completionHandler: ((Bool) -> Void)? = nil) {
    completionHandler?(false)
  }
}

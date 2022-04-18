// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import os

private let log = Logging.logger("LegacyConfigFileLoader")

/**
 Represents a config file loader for the old way of storing soundfont configurations.
 */
struct LegacyConfigFileLoader<T> where T: Decodable & CustomStringConvertible {

  /**
   Attempts to load a legacy config file.

   - parameter filename: the path of the file to load
   - parameter removeWhenDone: if true then the legacy file is deleted after being used
   */
  static func load(filename: String, removeWhenDone: Bool = false) -> T? {
    os_log(.debug, log: log, "init - %{public}s", filename)
    let sharedArchivePath = FileManager.default.sharedPath(for: filename)
    os_log(.debug, log: log, "path - %{public}s", sharedArchivePath.path)
    guard FileManager.default.fileExists(atPath: sharedArchivePath.path) else { return nil }
    os_log(.debug, log: log, "path exists")

    defer {
      if removeWhenDone {
        try? FileManager.default.removeItem(at: sharedArchivePath)
      }
    }

    guard let data = try? Data(contentsOf: sharedArchivePath) else { return nil }
    os_log(.debug, log: log, "fetched data from file")

    guard let contents = try? PropertyListDecoder().decode(T.self, from: data) else { return nil }
    os_log(.debug, log: log, "restored from data - %{public}s", contents.description)

    return contents
  }
}

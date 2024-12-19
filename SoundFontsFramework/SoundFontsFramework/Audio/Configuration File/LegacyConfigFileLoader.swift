// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import os

private let log: Logger = Logging.logger("LegacyConfigFileLoader")

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
    log.debug("init - \(filename, privacy: .public)")
    let sharedArchivePath = FileManager.default.sharedPath(for: filename)
    log.debug("path - \(sharedArchivePath.path)")
    guard FileManager.default.fileExists(atPath: sharedArchivePath.path) else { return nil }
    log.debug("path exists")

    defer {
      if removeWhenDone {
        try? FileManager.default.removeItem(at: sharedArchivePath)
      }
    }

    guard let data = try? Data(contentsOf: sharedArchivePath) else { return nil }
    log.debug("fetched data from file")

    guard let contents = try? PropertyListDecoder().decode(T.self, from: data) else { return nil }
    log.debug("restored from data - \(contents.description, privacy: .public)")

    return contents
  }
}

// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os

private let log = Logging.logger("FileManager")

public extension FileManager {
  var groupIdentifier: String { "group.com.braysoftware.SoundFontsShare" }
  /**
   Obtain the URL for a new, temporary file. The file will exist on the system but will be empty.

   - returns: the location of the temporary file.
   - throws: exceptions encountered by FileManager while locating location for temporary file
   */
  func newTemporaryFile() throws -> URL {
    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(
      ProcessInfo().globallyUniqueString)
    precondition(self.createFile(atPath: temporaryFileURL.path, contents: nil))
    os_log(.info, log: log, "newTemporaryFile - %{public}@", temporaryFileURL.absoluteString)
    return temporaryFileURL
  }

  /// Location of app documents that we want to keep private but backed-up. We need to create it if it does not
  /// exist, so this could be a high latency call.
  var privateDocumentsDirectory: URL {
    let url = urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    if !self.fileExists(atPath: url.path) {
      DispatchQueue.global(qos: .userInitiated).async {
        try? self.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
      }
    }
    return url
  }

  /// Location of shared documents between app and extension
  var sharedDocumentsDirectory: URL {
    guard let url = self.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
      os_log(.error, log: log, "unable to obtain container URL for '%{public}@'", groupIdentifier)
      return localDocumentsDirectory
    }

    if !self.fileExists(atPath: url.path) {
      DispatchQueue.global(qos: .userInitiated).async {
        try? self.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
      }
    }
    return url
  }

  func sharedPath(for component: String) -> URL {
    sharedDocumentsDirectory.appendingPathComponent(component)
  }

  var sharedFileNames: [String] {
    (try? contentsOfDirectory(atPath: sharedDocumentsDirectory.path)) ?? [String]()
  }

  /// True if the user has an iCloud container available to use
  var hasCloudDirectory: Bool { return self.ubiquityIdentityToken != nil }

  /// Location of documents on device that can be backed-up to iCloud if enabled.
  var localDocumentsDirectory: URL {
    let path = self.urls(for: .documentDirectory, in: .userDomainMask).last!
    os_log(.info, log: log, "localDocumentsDirectory - %@", path.path)
    return path
  }

  /// Location of app documents in iCloud (if enabled). NOTE: this should not be accessed from the main thread as
  /// it can take some time before it will return a value.
  var cloudDocumentsDirectory: URL? {
    precondition(Thread.current.isMainThread == false)
    guard let loc = self.url(forUbiquityContainerIdentifier: nil) else {
      os_log(.info, log: log, "cloudDocumentsDirectory - nil")
      return nil
    }
    let dir = loc.appendingPathComponent("Documents")
    if !self.fileExists(atPath: dir.path) {
      try? self.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
    }

    os_log(.info, log: log, "cloudDocumentsDirectory - %{public}@", dir.absoluteString)
    return dir
  }

  /**
   Try to obtain the size of a given file.

   - parameter url: the location of the file to measure
   - returns: size in bytes or 0 if there was a problem getting the size
   */
  func fileSizeOf(url: URL) -> UInt64 {
    let fileSize = try? (self.attributesOfItem(atPath: url.path) as NSDictionary).fileSize()
    os_log(.info, log: log, "fileSizeOf %{public}@: %d", url.absoluteString, fileSize ?? 0)
    return fileSize ?? 0
  }
}
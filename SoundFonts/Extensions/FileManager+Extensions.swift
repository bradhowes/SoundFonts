// Copyright © 2019 Brad Howes. All rights reserved.

import os
import Foundation

private let log = Logging.logger("filem")

extension FileManager {

    /**
     Obtain the URL for a new, temporary file. The file will exist on the system but will be empty.

     - returns: the location of the temporary file.
     - throws: exceptions encountered by FileManager while locating location for temporary file
     */
    func newTemporaryFile() throws -> URL {
        let temporaryDirectoryURL = try self.url(for: .itemReplacementDirectory, in: .userDomainMask,
                                                 appropriateFor: URL(fileURLWithPath: ""), create: true)
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(ProcessInfo().globallyUniqueString)
        precondition(self.createFile(atPath: temporaryFileURL.path, contents: nil))
        os_log(.info, log: log, "newTemporaryFile - %@", temporaryFileURL.absoluteString)
        return temporaryFileURL
    }

    /// Location of app documents that we want to keep private but backed-up
    var privateDocumentsDirectory: URL { urls(for: .applicationSupportDirectory, in: .userDomainMask).first! }

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

        os_log(.info, log: log, "cloudDocumentsDirectory - %@", dir.absoluteString)
        return dir
    }

    /**
     Try to obtain the size of a given file.

     - parameter url: the location of the file to measure
     - returns: size in bytes or 0 if there was a problem getting the size
     */
    func fileSizeOf(url: URL) -> UInt64 {
        let fileSize = try? (self.attributesOfItem(atPath: url.path) as NSDictionary).fileSize()
        os_log(.info, log: log, "fileSizeOf %@: %d", url.absoluteString, fileSize ?? 0)
        return fileSize ?? 0
    }
}

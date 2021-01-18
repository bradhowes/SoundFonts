// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import os

enum TagsConfigFileError: Error {
    case nilTagsManager
}

public final class TagsConfigFile: UIDocument {

    private let log = Logging.logger("TagsCfg")
    private let sharedArchivePath = FileManager.default.sharedPath(for: "Tags.plist")
    private weak var tagsManager: LegacyTagsManager?

    public init(tagsManager: LegacyTagsManager) {
        self.tagsManager = tagsManager
        super.init(fileURL: sharedArchivePath)
        initialize()
    }

    public func initialize() {
        self.open { ok in
            if !ok {
                self.save(to: self.sharedArchivePath, for: .forCreating)
            }
        }
    }

    override public func contents(forType typeName: String) throws -> Any {
        guard let tagsManager = tagsManager else { throw TagsConfigFileError.nilTagsManager }
        return try tagsManager.configurationData()
    }

    override public func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let tagsManager = tagsManager else { throw TagsConfigFileError.nilTagsManager }
        try tagsManager.loadConfigurationData(contents: contents)
    }

    override public func revert(toContentsOf url: URL, completionHandler: ((Bool) -> Void)? = nil) {
        os_log(.info, log: log, "revert url: '%{public}s' - ignoring", url.path)
        completionHandler?(false)
    }
}

// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import os

enum FavoritesConfigFileError: Error {
    case failedToCreate
}

public final class FavoritesConfigFile: UIDocument {
    private let log = Logging.logger("FavCfg")
    private let sharedArchivePath = FileManager.default.sharedDocumentsDirectory.appendingPathComponent("Favorites.plist")
    private weak var favoritesManager: LegacyFavoritesManager?

    public init() {
        super.init(fileURL: sharedArchivePath)
    }

    public func initialize(favoritesManager: LegacyFavoritesManager) {
        self.favoritesManager = favoritesManager
        self.open { ok in
            if !ok {
                do {
                    let data = try PropertyListEncoder().encode(LegacyFavoriteCollection())
                    try favoritesManager.loadConfigurationData(contents: data)
                    self.save(to: self.sharedArchivePath, for: .forCreating)
                } catch let error as NSError {
                    fatalError("Failed to initialize new collection: \(error.localizedDescription)")
                }
            }
        }
    }

    override public func contents(forType typeName: String) throws -> Any {
        guard let favoritesManager = self.favoritesManager else { fatalError() }
        return try favoritesManager.configurationData()
    }

    override public func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let favoritesManager = self.favoritesManager else { fatalError() }
        try favoritesManager.loadConfigurationData(contents: contents)
    }

    override public func revert(toContentsOf url: URL, completionHandler: ((Bool) -> Void)? = nil) {
        os_log(.info, log: log, "revert url: '%{public}s' - ignoring", url.path)
        completionHandler?(false)
    }
}

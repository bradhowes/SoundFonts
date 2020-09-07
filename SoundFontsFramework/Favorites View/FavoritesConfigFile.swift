// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import os

enum FavoritesConfigFileError: Error {
    case failedToCreate
}

public final class FavoritesConfigFile: UIDocument {
    private let log = Logging.logger("FavCfg")

    private let sharedArchivePath = FileManager.default.sharedDocumentsDirectory
        .appendingPathComponent("Favorites.plist")

    private let favoritesManager: FavoritesManager

    public init(favoritesManager: FavoritesManager) {
        self.favoritesManager = favoritesManager
        super.init(fileURL: sharedArchivePath)
        self.open { ok in
            if !ok {
                let data = try! PropertyListEncoder().encode(FavoriteCollection())
                try! favoritesManager.loadConfigurationData(contents: data)
                self.save(to: self.sharedArchivePath, for: .forCreating)
            }
        }

        favoritesManager.subscribe(self, notifier: favoritesChanged)
    }

    override public func contents(forType typeName: String) throws -> Any {
        try favoritesManager.configurationData()
    }

    override public func load(fromContents contents: Any, ofType typeName: String?) throws {
        try favoritesManager.loadConfigurationData(contents: contents)
    }

    private func favoritesChanged(_ event: FavoritesEvent) {
        os_log(.info, log: log, "favoritesChanged")
        updateChangeCount(.done)
    }
}

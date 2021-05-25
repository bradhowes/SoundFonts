// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os

public struct ConsolidatedConfig: Codable {
    private static let log = Logging.logger("ConsolidatedConfig")

    public var soundFonts: LegacySoundFontCollection
    public var favorites: LegacyFavoriteCollection
    public var tags: LegacyTagCollection
}

extension ConsolidatedConfig {
    public init() {
        os_log(.info, log: Self.log, "creating default collection")
        soundFonts = LegacySoundFontsManager.defaultCollection
        favorites = LegacyFavoritesManager.defaultCollection
        tags = LegacyTagsManager.defaultCollection
    }
}

extension ConsolidatedConfig: CustomStringConvertible {
    public var description: String { "<Config \(soundFonts), \(favorites), \(tags)>" }
}

public final class ConsolidatedConfigFile: UIDocument {
    private static let log = Logging.logger("ConsolidatedConfigFile")
    private var log: OSLog { Self.log }

    static let filename = "Consolidated.plist"

    public lazy var config: ConsolidatedConfig = ConsolidatedConfig()
    @objc dynamic public private(set) var restored: Bool = false {
        didSet {
            self.updateChangeCount(.done)
            self.autosave(completionHandler: nil)
        }
    }

    public init() {
        os_log(.info, log: Self.log, "init")
        let sharedArchivePath = FileManager.default.sharedPath(for: Self.filename)
        super.init(fileURL: sharedArchivePath)
        initialize(sharedArchivePath)
    }

    private func initialize(_ sharedArchivePath: URL) {
        os_log(.info, log: Self.log, "initialize - %{public}s", sharedArchivePath.path)
        self.open { ok in
            if !ok {
                os_log(.info, log: Self.log, "failed to open - attempting legacy loading")
                // We are back on the main thread so do the loading in the background.
                DispatchQueue.global(qos: .userInitiated).async {
                    self.attemptLegacyLoad(sharedArchivePath)
                }
            }
        }
    }

    override public func contents(forType typeName: String) throws -> Any {
        os_log(.info, log: log, "contents - typeName: %{public}s", typeName)
        let contents = try PropertyListEncoder().encode(config)
        os_log(.info, log: log, "-- pending save of %d bytes", contents.count)
        return contents
    }

    override public func load(fromContents contents: Any, ofType typeName: String?) throws {
        os_log(.info, log: log, "load - typeName: %{public}s", typeName ?? "nil")
        guard let data = contents as? Data else {
            os_log(.error, log: log, "failed to convert contents to Data")
            restoreConfig(ConsolidatedConfig())
            NotificationCenter.default.post(Notification(name: .configLoadFailure, object: nil))
            return
        }

        guard let config = try? PropertyListDecoder().decode(ConsolidatedConfig.self, from: data) else {
            os_log(.error, log: log, "failed to decode Data contents")
            restoreConfig(ConsolidatedConfig())
            NotificationCenter.default.post(Notification(name: .configLoadFailure, object: nil))
            return
        }

        os_log(.info, log: log, "decoded contents: %{public}s", config.description)
        restoreConfig(config)
    }

    override public func revert(toContentsOf url: URL, completionHandler: ((Bool) -> Void)? = nil) {
        completionHandler?(false)
    }
}

extension ConsolidatedConfigFile {

    private func attemptLegacyLoad(_ sharedArchivePath: URL) {
        os_log(.info, log: log, "attemptLegacyLoad")
        guard
            let soundFonts = LegacyConfigFileLoader<LegacySoundFontCollection>.load(filename: "SoundFontLibrary.plist"),
            let favorites = LegacyConfigFileLoader<LegacyFavoriteCollection>.load(filename: "Favorites.plist"),
            let tags = LegacyConfigFileLoader<LegacyTagCollection>.load(filename: "Tags.plist")
        else {
            os_log(.info, log: log, "failed to load one or more legacy files")
            initializeCollections()
            return
        }

        os_log(.info, log: log, "using legacy contents")
        restoreConfig(ConsolidatedConfig(soundFonts: soundFonts, favorites: favorites, tags: tags))
    }

    private func restoreConfig(_ config: ConsolidatedConfig) {
        os_log(.info, log: log, "restoreConfig")
        self.config = config
        self.restored = true
    }

    private func initializeCollections() {
        os_log(.info, log: log, "initializeCollections")

        let tag = config.tags.getBy(index: 0)
        for each in config.soundFonts.soundFonts {
            each.tags.insert(tag.key)
        }

        self.restored = true
    }
}

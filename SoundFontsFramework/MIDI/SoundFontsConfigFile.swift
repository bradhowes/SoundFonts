// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import os

enum SoundFontsConfigFileError: Error {
    case failedToCreate
}

public final class SoundFontsConfigFile: UIDocument {
    private let log = Logging.logger("SFCfg")

    private let sharedArchivePath = FileManager.default.sharedDocumentsDirectory.appendingPathComponent("SoundFontLibrary.plist")
    private weak var soundFontsManager: LegacySoundFontsManager?

    public init() {
        super.init(fileURL: sharedArchivePath)
    }

    public func initialize(soundFontsManager: LegacySoundFontsManager) {
        soundFontsManager.subscribe(self, notifier: soundFontsChanged)
        self.soundFontsManager = soundFontsManager
        self.open { ok in
            if !ok {
                do {
                    let data = try PropertyListEncoder().encode(LegacySoundFontsManager.create())
                    try soundFontsManager.loadConfigurationData(contents: data)
                    self.save(to: self.sharedArchivePath, for: .forCreating)
                } catch let error as NSError {
                    fatalError("Failed to initialize empty collection: \(error.localizedDescription)")
                }
            }
        }
    }

    public func save() {
        super.save(to: sharedArchivePath, for: .forOverwriting)
    }

    override public func contents(forType typeName: String) throws -> Any {
        guard let soundFontsManager = self.soundFontsManager else { fatalError() }
        return try soundFontsManager.configurationData()
    }

    override public func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let soundFontsManager = self.soundFontsManager else { fatalError() }
        try soundFontsManager.loadConfigurationData(contents: contents)
    }

    private func soundFontsChanged(_ event: SoundFontsEvent) {
        os_log(.info, log: log, "soundFontsChanged")
        switch event {
        case .restored:
            break
        default:
            updateChangeCount(.done)
        }
    }
}

// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import os

enum SoundFontsConfigFileError: Error {
    case failedToCreate
}

public final class SoundFontsConfigFile: UIDocument {
    private let log = Logging.logger("SFCfg")

    private let sharedArchivePath = FileManager.default.sharedDocumentsDirectory
        .appendingPathComponent("SoundFontLibrary.plist")

    private let soundFontsManager: LegacySoundFontsManager

    public init(soundFontsManager: LegacySoundFontsManager) {
        self.soundFontsManager = soundFontsManager
        super.init(fileURL: sharedArchivePath)
        self.open { ok in
            if !ok {
                do {
                    let data = try PropertyListEncoder().encode(LegacySoundFontCollection(soundFonts: []))
                    try soundFontsManager.loadConfigurationData(contents: data)
                    self.save(to: self.sharedArchivePath, for: .forCreating)
                } catch let error as NSError {
                    fatalError("Failed to initialize empty collection: \(error.localizedDescription)")
                }
            }
        }

        soundFontsManager.subscribe(self, notifier: soundFontsChanged)
    }

    override public func contents(forType typeName: String) throws -> Any {
        try soundFontsManager.configurationData()
    }

    override public func load(fromContents contents: Any, ofType typeName: String?) throws {
        try soundFontsManager.loadConfigurationData(contents: contents)
    }

    private func soundFontsChanged(_ event: SoundFontsEvent) {
        os_log(.info, log: log, "soundFontsChanged")
        updateChangeCount(.done)
    }
}

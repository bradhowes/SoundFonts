// SoundFontLibrary.swift
// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os

public final class SoundFontLibrary: Codable {

    private static let logger = Logging.logger("SFLib")

    private static let archivePath = FileManager.default.localDocumentsDirectory
        .appendingPathComponent("SoundFontLibrary.plist")

    private var map = [String:SoundFont]()
    public private(set) var keys = [String]()

    public static let shared = builder()

    private static func builder() -> SoundFontLibrary {
        do {
            os_log(.info, log: logger, "attempting to restore library")
            let data = try Data(contentsOf: Self.archivePath, options: .dataReadingMapped)
            os_log(.info, log: logger, "loaded data")
            return try PropertyListDecoder().decode(SoundFontLibrary.self, from: data)
        } catch {
            os_log(.info, log: logger, "creating initial library")
            let library = SoundFontLibrary()
            library.save()
            return library
        }
    }

    private init() {
        let bundle = Bundle(for: SoundFontLibrary.self)
        let paths = bundle.paths(forResourcesOfType: "sf2", inDirectory: nil)
        paths.forEach { add(soundFont: URL(fileURLWithPath: $0)) }
        keys = map.keys.sorted()
    }

    /**
     Obtain a SoundFont using an index into the `keys` name array. If the index is out-of-bounds this will return the
     first sound font in alphabetical order.
     - parameter index: the key to use
     - returns: found SoundFont object
     */
    public func getByIndex(_ index: Int) -> SoundFont {
        guard index >= 0 && index < keys.count else { return map[keys[0]]! }
        let key = keys[index]
        return map[key]!
    }

    /**
     Obtain a SoundFont by name.
     - parameter key: the key to use
     - returns: found SoundFont object
     */
    public func getByName(_ name: String) -> SoundFont? {
        return map[name]
    }

    /**
     Obtain the index in `keys` for the given sound font name. If not found, return 0
     - parameter name: the name to look for
     - returns: found index or zero
     */
    public func indexForName(_ name: String) -> Int { keys.firstIndex(of: name) ?? 0 }

    public func add(soundFont: URL) {
        os_log(.info, log: Self.logger, "adding '%s' to library", soundFont.path)
        guard let data = try? Data(contentsOf: soundFont, options: .dataReadingMapped) else {
            os_log(.error, log: Self.logger, "failed to get SF2 data")
            return
        }

        let info = GetSoundFontInfo(data: data)
        if info.name.isEmpty || info.patches.isEmpty {
            os_log(.error, log: Self.logger, "failed to parse SF2 data")
            return
        }

        let soundFont = SoundFont(info)
        map[info.name] = soundFont
        DispatchQueue.global(qos: .background).async {
            os_log(.info, log: Self.logger, "creating SF2 file at '%s'", soundFont.fileURL.path)
            let result = FileManager.default.createFile(atPath: soundFont.fileURL.path, contents: data, attributes: nil)
            if result {
                os_log(.info, log: Self.logger, "created OK")
            }
            else {
                os_log(.error, log: Self.logger, "created FAILED")
            }
        }
    }
}

extension SoundFontLibrary {
    /**
     Save the current collection to disk.
     */
    func save() {
        do {
            os_log(.info, log: Self.logger, "archiving")
            let data = try PropertyListEncoder().encode(self)
            DispatchQueue.global(qos: .background).async {
                os_log(.info, log: Self.logger, "obtained archive")
                do {
                    os_log(.info, log: Self.logger, "trying to save to disk")
                    try data.write(to: Self.archivePath, options: [.atomicWrite, .completeFileProtection])
                    os_log(.info, log: Self.logger, "saving OK")
                } catch {
                    os_log(.error, log: Self.logger, "saving FAILED")
                }
            }
        } catch {
            os_log(.error, log: Self.logger, "archiving FAILED")
        }
    }
}

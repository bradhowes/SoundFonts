// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os

public final class SoundFontsManager: SubscriptionManager<SoundFontsEvent> {

    private static let log = Logging.logger("SFLib")

    private static let appArchivePath = FileManager.default.privateDocumentsDirectory
        .appendingPathComponent("SoundFontLibrary.plist")
    private static let sharedArchivePath = FileManager.default.sharedDocumentsDirectory
        .appendingPathComponent("SoundFontLibrary.plist")

    private var log: OSLog { Self.log }
    private let sharedStateMonitor: SharedStateMonitor
    private var collection: SoundFontCollection

    public static func restore() -> SoundFontCollection? {
        os_log(.info, log: log, "attempting to restore collection")
        for url in [Self.sharedArchivePath, Self.appArchivePath] {
            os_log(.info, log: log, "trying to read from '%s'", url.path)
            if let data = try? Data(contentsOf: url, options: .dataReadingMapped) {
                os_log(.info, log: log, "restoring from '%s'", url.path)
                if let collection = try? PropertyListDecoder().decode(SoundFontCollection.self, from: data) {
                    os_log(.info, log: log, "restored")
                    return collection
                }
            }
        }

        return nil
    }

    public static func create() -> SoundFontCollection {
        os_log(.info, log: log, "creating new collection")
        let bundle = Bundle(for: SoundFontsManager.self)
        let urls = bundle.paths(forResourcesOfType: "sf2", inDirectory: nil).map { URL(fileURLWithPath: $0) }
        if urls.count == 0 { fatalError("no SF2 files in bundle") }
        return SoundFontCollection(soundFonts: urls.map { addFromBundle(url: $0) })
    }

    public init(sharedStateMonitor: SharedStateMonitor) {
        self.sharedStateMonitor = sharedStateMonitor
        self.collection = Self.restore() ?? Self.create()
        super.init()
        save()
        os_log(.info, log: log, "collection size: %d", collection.count)
    }

    public func reload() {
        os_log(.info, log: log, "reload")
        if let collection = Self.restore() {
            os_log(.info, log: log, "updating collection")
            self.collection = collection
        }
    }
}

extension SoundFontsManager: SoundFonts {

    public var count: Int { collection.count }

    public func index(of uuid: UUID) -> Int? { collection.index(of: uuid) }

    public func getBy(index: Int) -> SoundFont { collection.getBy(index: index) }

    public func getBy(key: SoundFont.Key) -> SoundFont? { collection.getBy(key: key) }

    @discardableResult
    public func add(url: URL) -> (Int, SoundFont)? {
        guard let soundFont = SoundFont.makeSoundFont(from: url, saveToDisk: true) else { return nil }
        let index = collection.add(soundFont)
        save()
        notify(.added(new: index, font: soundFont))
        return (index, soundFont)
    }

    public func remove(index: Int) {
        guard let soundFont = collection.remove(index) else { return }
        save()
        notify(.removed(old: index, font: soundFont))
    }

    public func rename(index: Int, name: String) {
        let (newIndex, soundFont) = collection.rename(index, name: name)
        save()
        notify(.moved(old: index, new: newIndex, font: soundFont))
    }
}

extension SoundFontsManager {

    private static let niceNames = [
        "Fluid": "Fluid R3", "Free Font": "FreeFont", "GeneralUser": "MuseScore", "User": "Roland"
    ]

    @discardableResult
    private static func addFromBundle(url: URL) -> SoundFont {
        guard let data = try? Data(contentsOf: url, options: .dataReadingMapped) else { fatalError() }
        let info = GetSoundFontInfo(data: data)
        if info.name.isEmpty || info.patches.isEmpty { fatalError() }
        let displayName = niceNames.first { (key, _) in info.name.hasPrefix(key) }?.value ?? info.name
        return SoundFont(displayName, soundFontInfo: info, resource: url)
    }

    /**
     Save the current collection to disk.
     */
    private func save() {
        do {
            let data = try PropertyListEncoder().encode(collection)
            let log = self.log
            os_log(.info, log: log, "archiving")
            DispatchQueue.global(qos: .userInitiated).async {
                os_log(.info, log: log, "obtained archive")
                do {
                    os_log(.info, log: log, "trying to save to '%s'", Self.sharedArchivePath.path)
                    try data.write(to: Self.sharedArchivePath, options: [.atomicWrite, .completeFileProtection])
                    self.sharedStateMonitor.notifySoundFontsChanged()
                    os_log(.info, log: log, "saving OK")
                } catch {
                    os_log(.error, log: log, "saving FAILED")
                }
            }
        } catch {
            os_log(.error, log: log, "archiving FAILED")
        }
    }
}

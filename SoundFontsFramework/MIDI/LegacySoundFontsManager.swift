// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os
import SoundFontInfoLib
import SF2Files

/**
 Manages a collection of SoundFont instances. Changes to the collection are communicated as a SoundFontsEvent event.
 */
public final class LegacySoundFontsManager: SubscriptionManager<SoundFontsEvent> {

    private static let log = Logging.logger("SFLib")
    private static let sharedArchivePath = FileManager.default.sharedDocumentsDirectory.appendingPathComponent("SoundFontLibrary.plist")

    private var log: OSLog { Self.log }
    private var collection: LegacySoundFontCollection

    /**
     Attempt to restore the last saved collection.

     - returns: restored SoundFont collection or nil if unable to do so
     */
    private static func restore() -> LegacySoundFontCollection? {
        os_log(.info, log: log, "attempting to restore collection")
        // return nil
        let url = Self.sharedArchivePath
        os_log(.info, log: log, "trying to read from '%s'", url.path)
        if let data = try? Data(contentsOf: url, options: .dataReadingMapped) {
            os_log(.info, log: log, "restoring from '%s'", url.path)
            if let collection = try? PropertyListDecoder().decode(LegacySoundFontCollection.self, from: data) {
                os_log(.info, log: log, "restored")
                return collection
            }
            else {
                NotificationCenter.default.post(name: .soundFontsCollectionLoadFailure, object: url)
            }
        }
        return nil
    }

    /**
     Create a new collection using the embedded SoundFont files.

     - returns: new SoundFontCollection
     */
    private static func create() -> LegacySoundFontCollection {
        os_log(.info, log: log, "creating new collection")
        let bundleUrls: [URL] = SF2Files.allResources
        let fileNames = (try? FileManager.default.contentsOfDirectory(atPath:
            FileManager.default.sharedDocumentsDirectory.path)) ?? [String]()
        let fileUrls = fileNames.map { FileManager.default.sharedDocumentsDirectory.appendingPathComponent($0) }
        return LegacySoundFontCollection(soundFonts: (bundleUrls.compactMap { addFromBundle(url: $0) }) +
            (fileUrls.compactMap { addFromSharedFolder(url: $0) }))
    }

    /**
     Create a new manager for a collection of SoundFonts. Attempts to load from disk a saved collection, and if that
     fails then creates a new one containing SoundFont instances embedded in the app.
     */
    public init() {
        self.collection = Self.restore() ?? Self.create()
        super.init()
        save()
        validate()
        os_log(.info, log: log, "collection size: %d", collection.count)
    }

    public func validate(_ soundFontAndPatch: SoundFontAndPatch) -> Bool { collection.validate(soundFontAndPatch) }

    /**
     Look to see if there are any files that are not part of the collection.
     */
    private func validate() {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: fm.sharedDocumentsDirectory.path) else {
            return
        }

        var found = 0
        for path in contents {
            let src = fm.sharedDocumentsDirectory.appendingPathComponent(path)
            guard src.pathExtension == SF2Files.sf2Extension else { continue }
            let (stripped, uuid) = path.stripEmbeddedUUID()
            if let uuid = uuid, collection.getBy(key: uuid) != nil { continue }
            let dst = fm.localDocumentsDirectory.appendingPathComponent(stripped)
            os_log(.info, log: Self.log, "removing '%s' if it exists", dst.path)
            try? fm.removeItem(at: dst)
            os_log(.info, log: Self.log, "copying '%s' to '%s'", src.path, dst.path)
            do {
                try fm.copyItem(at: src, to: dst)
            } catch let error as NSError {
                os_log(.error, log: Self.log, "%s", error.localizedDescription)
            }
            os_log(.info, log: Self.log, "removing '%s'", src.path)
            try? fm.removeItem(at: src)
            found += 1
        }

        if found > 0 {
            NotificationCenter.default.post(name: .soundFontsCollectionOrphans, object: NSNumber(value: found))
        }
    }

    /**
     Reload from disk the managed collection of SoundFonts due to a change made by another process.
     */
    public func reload() {
        os_log(.info, log: log, "reload")
        if let collection = Self.restore() {
            os_log(.info, log: log, "updating collection")
            self.collection = collection
        }
    }
}

// MARK: - SoundFonts Protocol

extension LegacySoundFontsManager: SoundFonts {

    public var isEmpty: Bool { collection.isEmpty }
    public var count: Int { collection.count }

    public func index(of uuid: UUID) -> Int? { collection.index(of: uuid) }

    public func getBy(index: Int) -> LegacySoundFont { collection.getBy(index: index) }

    public func getBy(key: LegacySoundFont.Key) -> LegacySoundFont? { collection.getBy(key: key) }

    @discardableResult
    public func add(url: URL) -> Result<(Int, LegacySoundFont), SoundFontFileLoadFailure> {
        switch LegacySoundFont.makeSoundFont(from: url, saveToDisk: true) {
        case .failure(let failure): return .failure(failure)
        case.success(let soundFont):
            let index = collection.add(soundFont)
            save()
            notify(.added(new: index, font: soundFont))
            return .success((index, soundFont))
        }
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

    public func setVisibility(key: LegacySoundFont.Key, index: Int, state: Bool) {
        guard let soundFont = getBy(key: key) else { return }
        let patch = soundFont.patches[index]
        guard state != patch.isVisible else { return }
        os_log(.debug, log: log, "setVisibility %s - %d %d", patch.name, patch.isVisible, state)
        patch.isVisible = state
        save()
    }

    public var hasAnyBundled: Bool {
        let urls = SF2Files.allResources
        let found = urls.first { collection.index(of: $0) != nil }
        return found != nil
    }

    public var hasAllBundled: Bool {
        let urls = SF2Files.allResources
        let found = urls.filter { collection.index(of: $0) != nil }
        return found.count == urls.count
    }

    public func removeBundled() {
        os_log(.info, log: log, "removeBundled")
        for url in SF2Files.allResources {
            if let index = collection.index(of: url) {
                os_log(.info, log: log, "removing %s", url.absoluteString)
                remove(index: index)
            }
        }
        save()
    }

    public func restoreBundled() {
        os_log(.info, log: log, "restoreBundled")
        for url in SF2Files.allResources {
            if collection.index(of: url) == nil {
                os_log(.info, log: log, "restoring %s", url.absoluteString)
                if let soundFont = Self.addFromBundle(url: url) {
                    let index = collection.add(soundFont)
                    notify(.added(new: index, font: soundFont))
                }
            }
        }
        save()
    }

    /**
     Copy one file to the local document directory.
     */
    public func copyToLocalDocumentsDirectory(name: String) -> Bool {
        let fm = FileManager.default
        let src = fm.sharedDocumentsDirectory.appendingPathComponent(name)
        let dst = fm.localDocumentsDirectory.appendingPathComponent(name)
        do {
            os_log(.info, log: Self.log, "removing '%s' if it exists", dst.path)
            try? fm.removeItem(at: dst)
            os_log(.info, log: Self.log, "copying '%s' to '%s'", src.path, dst.path)
            try fm.copyItem(at: src, to: dst)
            return true
        } catch let error as NSError {
            os_log(.error, log: Self.log, "%s", error.localizedDescription)
        }
        return false
    }

    /**
     Copy all of the known SF2 files to the local document directory.
     */
    public func exportToLocalDocumentsDirectory() -> (good: Int, total: Int) {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: fm.sharedDocumentsDirectory.path) else {
            return (good: 0, total: 0)
        }

        var good = 0
        var bad = 0
        for path in contents {
            let src = fm.sharedDocumentsDirectory.appendingPathComponent(path)
            guard let attrs = try? fm.attributesOfItem(atPath: src.path) else { continue }
            guard let fileType = attrs[.type] as? String else { continue }
            guard fileType == "NSFileTypeRegular" else { continue }
            let (stripped, _) = path.stripEmbeddedUUID()
            guard stripped.first != "." else { continue }

            let dst = fm.localDocumentsDirectory.appendingPathComponent(stripped)
            do {
                os_log(.info, log: Self.log, "removing '%s' if it exists", dst.path)
                try? fm.removeItem(at: dst)
                os_log(.info, log: Self.log, "copying '%s' to '%s'", src.path, dst.path)
                try fm.copyItem(at: src, to: dst)
                good += 1
            } catch let error as NSError {
                os_log(.error, log: Self.log, "%s", error.localizedDescription)
                bad += 1
            }
        }
        return (good: good, total: good + bad)
    }

    /**
     Import all SF2 files from the local documents directory that is visible to the user.
     */
    public func importFromLocalDocumentsDirectory() -> (good: Int, total: Int) {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: fm.localDocumentsDirectory.path) else {
            return (good: 0, total: 0)
        }

        var good = 0
        var bad = 0
        for path in contents {
            guard path.hasSuffix(SF2Files.sf2DottedExtension) else { continue }
            let src = fm.localDocumentsDirectory.appendingPathComponent(path)
            switch add(url: src) {
            case .success: good += 1
            case .failure: bad += 1
            }
        }

        return (good: good, total: good + bad)
    }
}

extension LegacySoundFontsManager {

    private static let niceNames = [
        "Fluid": "Fluid R3", "Free Font": "FreeFont", "GeneralUser": "MuseScore", "User": "Roland"
    ]

    @discardableResult
    fileprivate static func addFromBundle(url: URL) -> LegacySoundFont? {
        guard let info = SoundFontInfo.load(url) else { return nil }
        guard let infoName = info.embeddedName else { return nil }
        guard !(infoName.isEmpty || info.presets.isEmpty) else { return nil }
        let displayName = niceNames.first { (key, _) in info.embeddedName.hasPrefix(key) }?.value ?? infoName
        return LegacySoundFont(displayName, soundFontInfo: info, resource: url)
    }

    @discardableResult
    fileprivate static func addFromSharedFolder(url: URL) -> LegacySoundFont? {
        switch LegacySoundFont.makeSoundFont(from: url, saveToDisk: false) {
        case .success(let soundFont): return soundFont
        case .failure: return nil
        }
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
                do {
                    os_log(.info, log: log, "trying to save to '%s'", Self.sharedArchivePath.path)
                    try data.write(to: Self.sharedArchivePath, options: [.atomicWrite])
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

extension LegacySoundFontsManager {

    internal func configurationData() throws -> Data {
        os_log(.info, log: log, "archiving")
        let data = try PropertyListEncoder().encode(collection)
        os_log(.info, log: log, "done - %d", data.count)
        return data
    }

    internal func loadConfigurationData(contents: Any) throws {
        os_log(.info, log: log, "loading configuration")
        if let data = contents as? Data {
            os_log(.info, log: log, "has Data")
            if let collection = try? PropertyListDecoder().decode(LegacySoundFontCollection.self, from: data) {
                os_log(.info, log: log, "properly decoded")
                self.collection = collection
                notify(.restored)
                return
            }
        }
        NotificationCenter.default.post(Notification(name: .soundFontsCollectionLoadFailure, object: nil))
    }
}

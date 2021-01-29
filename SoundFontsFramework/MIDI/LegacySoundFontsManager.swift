// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit
import os
import SoundFontInfoLib
import SF2Files

/**
 Manages a collection of SoundFont instances. Changes to the collection are communicated as a SoundFontsEvent event.
 */
public final class LegacySoundFontsManager: SubscriptionManager<SoundFontsEvent> {

    private static let log = Logging.logger("SFMan")
    private var log: OSLog { Self.log }

    private var configFile: UIDocument?

    private var _collection: LegacySoundFontCollection! = nil {
        didSet { os_log(.debug, log: log, "collection changed: %{public}s", _collection.description) }
    }

    private var collection: LegacySoundFontCollection {
        get {
            if self._collection == nil {
                self._collection = Self.defaultCollection
            }
            return self._collection
        }
        set {
            self._collection = newValue
        }
    }

    public private(set) var restored = false {
        didSet { os_log(.debug, log: log, "restored: %{public}@", collection.description) }
    }

    /**
     Create a new manager for a collection of SoundFonts. Attempts to load from disk a saved collection, and if that
     fails then creates a new one containing SoundFont instances embedded in the app.
     */
    public init() {
        super.init()
        DispatchQueue.global(qos: .userInitiated).async {
            self.configFile = ConfigFile<Self>(manager: self)
        }
    }
}

extension FileManager {

    fileprivate var installedSF2Files: [URL] {
        let fileNames = FileManager.default.sharedFileNames
        return fileNames.map { FileManager.default.sharedPath(for: $0) }
    }

    fileprivate func validateSF2Files(log: OSLog, collection: LegacySoundFontCollection) -> Int {
        guard let contents = try? contentsOfDirectory(atPath: sharedDocumentsDirectory.path) else { return -1 }
        var found = 0
        for path in contents {
            let src = sharedDocumentsDirectory.appendingPathComponent(path)
            guard src.pathExtension == SF2Files.sf2Extension else { continue }
            let (stripped, uuid) = path.stripEmbeddedUUID()
            if let uuid = uuid, collection.getBy(key: uuid) != nil { continue }
            let dst = localDocumentsDirectory.appendingPathComponent(stripped)
            os_log(.info, log: log, "removing '%{public}s' if it exists", dst.path)
            try? removeItem(at: dst)
            os_log(.info, log: log, "copying '%{public}s' to '%{public}s'", src.path, dst.path)
            do {
                try copyItem(at: src, to: dst)
            } catch let error as NSError {
                os_log(.error, log: log, "%{public}s", error.localizedDescription)
            }
            os_log(.info, log: log, "removing '%{public}s'", src.path)
            try? removeItem(at: src)
            found += 1
        }

        return found
    }
}

// MARK: - SoundFonts Protocol

extension LegacySoundFontsManager: SoundFonts {

    public var soundFontNames: [String] { collection.soundFonts.map { $0.displayName } }

    public var defaultPreset: SoundFontAndPatch? { collection.defaultPreset }

    public func firstIndex(of key: LegacySoundFont.Key) -> Int? { collection.firstIndex(of: key) }

    public func getBy(key: LegacySoundFont.Key) -> LegacySoundFont? { collection.getBy(key: key) }

    public func resolve(soundFontAndPatch: SoundFontAndPatch) -> LegacyPatch? {
        let soundFont = collection.getBy(key: soundFontAndPatch.soundFontKey)
        return soundFont?.patches[soundFontAndPatch.patchIndex]
    }

    public func filtered(by tag: LegacyTag.Key) -> [LegacySoundFont.Key] {
        collection.soundFonts.filter { $0.tags.union(LegacyTag.allTagSet).contains(tag) }.map { $0.key }
    }

    public func filteredIndex(index: Int, tag: LegacyTag.Key) -> Int {
        var reduction = 0
        for entry in collection.soundFonts.enumerated()
        where entry.offset <= index && !entry.element.tags.union(LegacyTag.allTagSet).contains(tag) {
            reduction += 1
        }

        return index - reduction
    }

    public func names(of keys: [LegacySoundFont.Key]) -> [String] {
        keys.compactMap { getBy(key: $0)?.displayName }
    }

    @discardableResult
    public func add(url: URL) -> Result<(Int, LegacySoundFont), SoundFontFileLoadFailure> {
        switch LegacySoundFont.makeSoundFont(from: url) {
        case .failure(let failure): return .failure(failure)
        case.success(let soundFont):
            defer { collectionChanged() }
            let index = collection.add(soundFont)
            notify(.added(new: index, font: soundFont))
            return .success((index, soundFont))
        }
    }

    public func remove(key: LegacySoundFont.Key) {
        guard let index = collection.firstIndex(of: key) else { return }
        guard let soundFont = collection.remove(index) else { return }
        defer { collectionChanged() }
        notify(.removed(old: index, font: soundFont))
    }

    public func rename(key: LegacySoundFont.Key, name: String) {
        guard let index = collection.firstIndex(of: key) else { return }
        defer { collectionChanged() }
        let (newIndex, soundFont) = collection.rename(index, name: name)
        notify(.moved(old: index, new: newIndex, font: soundFont))
    }

    public func removeTag(_ tag: LegacyTag.Key) {
        defer { collectionChanged() }
        for soundFont in collection.soundFonts {
            var tags = soundFont.tags
            tags.remove(tag)
            soundFont.tags = tags
        }
    }

    public func createFavorite(soundFontAndPatch: SoundFontAndPatch, keyboardLowestNote: Note?) -> LegacyFavorite? {
        guard let soundFont = getBy(key: soundFontAndPatch.soundFontKey) else { return nil }
        defer { collectionChanged() }
        let preset = soundFont.patches[soundFontAndPatch.patchIndex]
        return preset.makeFavorite(soundFontAndPatch: soundFontAndPatch, keyboardLowestNote: keyboardLowestNote)
    }

    public func deleteFavorite(soundFontAndPatch: SoundFontAndPatch, key: LegacyFavorite.Key) {
        guard let soundFont = getBy(key: soundFontAndPatch.soundFontKey) else { return }
        defer { collectionChanged() }
        let preset = soundFont.patches[soundFontAndPatch.patchIndex]
        preset.favorites.removeAll { $0 == key }
    }

    public func updatePreset(soundFontAndPatch: SoundFontAndPatch, config: PresetConfig) {
        guard let soundFont = getBy(key: soundFontAndPatch.soundFontKey) else { return }
        defer { collectionChanged() }
        let patch = soundFont.patches[soundFontAndPatch.patchIndex]
        patch.presetConfig = config
        notify(.presetChanged(font: soundFont, index: soundFontAndPatch.patchIndex))
    }

    public func setVisibility(soundFontAndPatch: SoundFontAndPatch, state: Bool) {
        guard let soundFont = getBy(key: soundFontAndPatch.soundFontKey) else { return }
        defer { collectionChanged() }
        let patch = soundFont.patches[soundFontAndPatch.patchIndex]
        os_log(.debug, log: log, "setVisibility - %{public}s %d - %d",
               soundFontAndPatch.soundFontKey.uuidString, soundFontAndPatch.patchIndex, state)
        patch.isVisible = state
    }

    public func setEffects(soundFontAndPatch: SoundFontAndPatch, delay: DelayConfig?, reverb: ReverbConfig?) {
        guard let soundFont = getBy(key: soundFontAndPatch.soundFontKey) else { return }
        os_log(.debug, log: log, "setEffects - %{public}s %d %{public}s %{public}s",
               soundFontAndPatch.soundFontKey.uuidString, soundFontAndPatch.patchIndex,
               delay?.description ?? "nil", reverb?.description ?? "nil")
        defer { collectionChanged() }
        let patch = soundFont.patches[soundFontAndPatch.patchIndex]
        patch.presetConfig.delayConfig = delay
        patch.presetConfig.reverbConfig = reverb
    }

    public func makeAllVisible(key: LegacySoundFont.Key) {
        guard let soundFont = getBy(key: key) else { return }
        defer { collectionChanged() }
        for preset in soundFont.patches.filter({ $0.isVisible == false}) {
            preset.isVisible = true
        }
        notify(.unhidPresets(font: soundFont))
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
        defer { collectionChanged() }
        for url in SF2Files.allResources {
            if let index = collection.index(of: url) {
                os_log(.info, log: log, "removing %{public}s", url.absoluteString)
                guard let soundFont = collection.remove(index) else { return }
                notify(.removed(old: index, font: soundFont))
            }
        }
    }

    public func restoreBundled() {
        os_log(.info, log: log, "restoreBundled")
        defer { collectionChanged() }
        for url in SF2Files.allResources {
            if collection.index(of: url) == nil {
                os_log(.info, log: log, "restoring %{public}s", url.absoluteString)
                if let soundFont = Self.addFromBundle(url: url) {
                    let index = collection.add(soundFont)
                    notify(.added(new: index, font: soundFont))
                }
            }
        }
    }

    public func reloadEmbeddedInfo(key: LegacySoundFont.Key) {
        guard let soundFont = getBy(key: key) else { return }
        guard soundFont.embeddedAuthor.isEmpty &&
                soundFont.embeddedComment.isEmpty &&
                soundFont.embeddedCopyright.isEmpty else {
            return
        }

        if soundFont.reloadEmbeddedInfo() {
            collectionChanged()
        }
    }

    /**
     Copy one file to the local document directory.
     */
    public func copyToLocalDocumentsDirectory(name: String) -> Bool {
        let fm = FileManager.default
        let src = fm.sharedDocumentsDirectory.appendingPathComponent(name)
        let dst = fm.localDocumentsDirectory.appendingPathComponent(name)
        do {
            os_log(.info, log: Self.log, "removing '%{public}s' if it exists", dst.path)
            try? fm.removeItem(at: dst)
            os_log(.info, log: Self.log, "copying '%{public}s' to '%{public}s'", src.path, dst.path)
            try fm.copyItem(at: src, to: dst)
            return true
        } catch let error as NSError {
            os_log(.error, log: Self.log, "%{public}s", error.localizedDescription)
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
                os_log(.info, log: Self.log, "removing '%{public}s' if it exists", dst.path)
                try? fm.removeItem(at: dst)
                os_log(.info, log: Self.log, "copying '%{public}s' to '%{public}s'", src.path, dst.path)
                try fm.copyItem(at: src, to: dst)
                good += 1
            } catch let error as NSError {
                os_log(.error, log: Self.log, "%{public}s", error.localizedDescription)
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
        guard let info = SoundFontInfo.load(viaParser: url) else { return nil }
        guard let infoName = info.embeddedName else { return nil }
        guard !(infoName.isEmpty || info.presets.isEmpty) else { return nil }
        let displayName = niceNames.first { (key, _) in info.embeddedName.hasPrefix(key) }?.value ?? infoName
        return LegacySoundFont(displayName, soundFontInfo: info, resource: url)
    }

    @discardableResult
    fileprivate static func addFromSharedFolder(url: URL) -> LegacySoundFont? {
        switch LegacySoundFont.makeSoundFont(from: url) {
        case .success(let soundFont): return soundFont
        case .failure: return nil
        }
    }

    /**
     Mark the current configuration as dirty so that it will get saved.
     */
    private func collectionChanged() {
        os_log(.info, log: log, "collectionChanged - %{public}@", collection.description)
        AskForReview.maybe()
        configFile?.updateChangeCount(.done)
    }
}

extension LegacySoundFontsManager: ConfigFileManager {

    internal var filename: String { "SoundFontLibrary.plist" }

    internal func configurationData() throws -> Any {
        os_log(.info, log: log, "configurationData")
        os_log(.info, log: log, "collection: %{public}@", collection.description)
        let data = try PropertyListEncoder().encode(collection)
        os_log(.info, log: log, "done - %d", data.count)
        if !restored {
            restored = true
            DispatchQueue.main.async { self.notify(.restored) }
        }
        return data
    }

    internal func loadConfigurationData(contents: Any) throws {
        os_log(.info, log: log, "loadConfigurationData")
        guard let data = contents as? Data else {
            restoreCollection(Self.defaultCollection)
            NotificationCenter.default.post(Notification(name: .soundFontsCollectionLoadFailure, object: nil))
            return
        }

        os_log(.info, log: log, "has data")
        guard let collection = try? PropertyListDecoder().decode(LegacySoundFontCollection.self, from: data) else {
            restoreCollection(Self.defaultCollection)
            NotificationCenter.default.post(Notification(name: .soundFontsCollectionLoadFailure, object: nil))
            return
        }

        os_log(.info, log: log, "properly decoded")
        restoreCollection(collection)
    }
}

extension LegacySoundFontsManager {

    private func restoreCollection(_ collection: LegacySoundFontCollection) {
        self.collection = collection
        restored = true
        DispatchQueue.main.async { self.notify(.restored) }
    }

    /**
     Create a new collection using the embedded SoundFont files.

     - returns: new SoundFontCollection
     */
    private static var defaultCollection: LegacySoundFontCollection {
        let bundleUrls: [URL] = SF2Files.allResources
        let fileUrls = FileManager.default.installedSF2Files
        return LegacySoundFontCollection(soundFonts: (bundleUrls.compactMap { addFromBundle(url: $0) }) +
                                                (fileUrls.compactMap { addFromSharedFolder(url: $0) }))
    }
}

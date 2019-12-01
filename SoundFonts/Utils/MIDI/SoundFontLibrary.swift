// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os

public final class SoundFontLibrary: Codable, SoundFontLibraryManager {

    private var notifiers = [UUID: (SoundFontLibraryChangeKind) -> Void]()

    private static let logger = Logging.logger("SFLib")

    private static let archivePath = FileManager.default.localDocumentsDirectory
        .appendingPathComponent("SoundFontLibrary.plist")

    // Internal collection of SoundFont instances managed in a thread-safe manner. All access is through a
    // serialized queue.
    private class Collection: Codable {
        let logger = Logging.logger("SFCol")

        private var catalog = [UUID:SoundFont]()
        private var _sortedKeys = [UUID]()
        private var sortedKeysDirty = false
        private var sortedKeys: [UUID] {
            if sortedKeysDirty {
                _sortedKeys = catalog.values.sorted { $0.displayName < $1.displayName } .map { $0.uuid }
                sortedKeysDirty = false
            }
            return _sortedKeys
        }

        private let updatingQueue = DispatchQueue(label: "SoundFontLibrary", qos: .userInitiated)

        private enum CodingKeys: String, CodingKey {
            case catalog
            case _sortedKeys
            case sortedKeysDirty
        }

        /**
         Add a SoundFont to the collection. Regenerates the `sortedKeys`

         - parameter soundFont: the instance to add
         */
        func add(_ soundFont: SoundFont) {
            updatingQueue.async {
                self.catalog[soundFont.uuid] = soundFont
                self.sortedKeysDirty = true
            }
        }

        var orderedSoundFonts: [SoundFont] { updatingQueue.sync { sortedKeys.map { catalog[$0]! } } }
        func getBy(uuid: UUID) -> SoundFont { updatingQueue.sync { catalog[uuid]! } }
    }

    private var collection = Collection()

    /// True when the library is restored and available for use.
    public private(set) var isRestored: Bool = false

    /// Get the display names of all of the SoundFont instances in the library. These are in alphabetical order.
    public var orderedSoundFonts: [SoundFont] { collection.orderedSoundFonts }

    /**
     Get the SoundFont with the given UUID value.

     - parameter uuid: the key to look for
     - returns the SoundFont
     */
    public func getBy(uuid: UUID) -> SoundFont { collection.getBy(uuid: uuid) }

    public static let shared = builder()

    private static func builder() -> SoundFontLibrary {
        do {
            os_log(.info, log: logger, "attempting to restore library")
            let data = try Data(contentsOf: Self.archivePath, options: .dataReadingMapped)
            os_log(.info, log: logger, "loaded data")
            let library = try PropertyListDecoder().decode(SoundFontLibrary.self, from: data)
            library.isRestored = true
            return library
        } catch {
            os_log(.info, log: logger, "creating initial library")
            return SoundFontLibrary()
        }
    }

    private enum CodingKeys: String, CodingKey {
        case collection
    }

    private init() {
        let bundle = Bundle(for: SoundFontLibrary.self)
        let urls = bundle.paths(forResourcesOfType: "sf2", inDirectory: nil).map { URL(fileURLWithPath: $0) }
        let dg = DispatchGroup()
        urls.forEach { url in
            dg.enter()
            if url.path.contains("RolandNicePiano") {
                DispatchQueue.global(qos: .userInitiated).async {
                    guard let data = try? Data(contentsOf: url, options: .dataReadingMapped) else { fatalError() }
                    let info = GetSoundFontInfo(data: data)
                    if info.name.isEmpty || info.patches.isEmpty { fatalError() }
                    let soundFont = SoundFont("Roland Nice Piano", resource: url, soundFontInfo: info)
                    self.collection.add(soundFont)
                    dg.leave()
                }
            }
            else {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.add(url: url)
                    os_log(.info, log: Self.logger, "0 added '%s'", url.lastPathComponent)
                    dg.leave()
                }
            }
        }

        dg.wait()
        let found = self.orderedSoundFonts
        print(found)
        precondition(found.count == 4)
        save()
        isRestored = true
    }

    /**
     Add a SoundFont resource to the library.

     - parameter soundFont: the URL of the resource to add
     */
    @discardableResult
    public func add(url: URL) -> SoundFont? {
        os_log(.info, log: Self.logger, "1 adding '%s'", url.lastPathComponent)

        // If this is a resource from iCloud we need to enable access to it. This will return `false` if the URL is
        // not in a security scope.
        let secured = url.startAccessingSecurityScopedResource()
        let data = try? Data(contentsOf: url, options: .dataReadingMapped)
        if secured { url.stopAccessingSecurityScopedResource() }

        guard let content = data else {
            os_log(.error, log: Self.logger, "failed to fetch content")
            return nil
        }

        let info = GetSoundFontInfo(data: content)
        if info.name.isEmpty || info.patches.isEmpty {
            os_log(.error, log: Self.logger, "failed to parse content")
            return nil
        }
        
        let soundFont = SoundFont(info)
        os_log(.info, log: Self.logger, "creating SF2 file at '%s'", soundFont.fileURL.lastPathComponent)
        let result = FileManager.default.createFile(atPath: soundFont.fileURL.path, contents: data, attributes: nil)
        os_log(.info, log: Self.logger, "created - %s", result ? "true" : "false")
        self.collection.add(soundFont)
        os_log(.info, log: Self.logger, "1 added '%s'", url.lastPathComponent)

        return soundFont
    }

    func remove(soundFont: SoundFont) {

    }

    func edit(soundFont: SoundFont) {

    }
}

extension SoundFontLibrary {

    func addSoundFontLibraryChangeNotifier<O>(_ observer: O, closure: @escaping (SoundFontLibraryChangeKind) -> Void) -> NotifierToken where O : AnyObject {
        let uuid = UUID()
        let token = NotifierToken { [weak self] in self?.notifiers.removeValue(forKey: uuid) }
        notifiers[uuid] = { [weak observer] kind in
            if observer != nil {
                closure(kind)
            }
            else {
                token.cancel()
            }
        }

        if isRestored {
            closure(.restored)
        }

        return token
    }

    func removeNotifier(forKey key: UUID) {
        notifiers.removeValue(forKey: key)
    }

    private func notify(_ kind: SoundFontLibraryChangeKind) {
        notifiers.values.forEach { $0(kind) }
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
            DispatchQueue.global(qos: .userInitiated).async {
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

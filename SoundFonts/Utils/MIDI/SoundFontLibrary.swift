// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os

public final class SoundFontLibrary: Codable, SoundFontLibraryManager {

    private var notifiers = [UUID: (SoundFontLibraryChangeKind) -> Void]()

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
            return SoundFontLibrary()
        }
    }

    private enum CodingKeys: String, CodingKey {
        case map
        case keys
    }

    private init() {
        let bundle = Bundle(for: SoundFontLibrary.self)
        let paths = bundle.paths(forResourcesOfType: "sf2", inDirectory: nil).map { URL(fileURLWithPath: $0) }

        let dg = DispatchGroup()
        dg.notify(queue: .main) {
            self.keys = self.map.keys.sorted()
            self.save()
            self.notify(.restored)
        }

        paths.forEach { path in
            if path.path.contains("RolandNicePiano") {
                guard let data = try? Data(contentsOf: path, options: .dataReadingMapped) else { fatalError() }
                let info = GetSoundFontInfo(data: data)
                if info.name.isEmpty || info.patches.isEmpty { fatalError() }
                let soundFont = SoundFont("Roland Nice Piano", resource: path, soundFontInfo: info)
                self.map[soundFont.displayName] = soundFont
                self.keys = self.map.keys.sorted()
            }
            else {
                dg.enter()
                add(soundFont: path) { _ in
                    dg.leave()
                }
            }
        }
    }

    /**
     Obtain a SoundFont using an index into the `keys` name array. If the index is out-of-bounds this will return the
     first sound font in alphabetical order.
     - parameter index: the key to use
     - returns: found SoundFont object
     */
    public func getByIndex(_ index: Int) -> SoundFont {
        return map[keys[index >= 0 && index < keys.count ? index : 0]]!
    }

    /**
     Obtain a SoundFont by name. If none exists, return the first one (alphabetically)
     - parameter key: the key to use
     - returns: found SoundFont object
     */
    public func getByName(_ name: String) -> SoundFont {
        return map[name] ?? getByIndex(0)
    }

    /**
     Obtain the index in `keys` for the given sound font name. If not found, return 0
     - parameter name: the name to look for
     - returns: found index or zero
     */
    public func indexForName(_ name: String) -> Int { keys.firstIndex(of: name) ?? 0 }

    /**
     Add a SoundFont resource to the library.

     - parameter soundFont: the URL of the resource to add
     */
    public func add(soundFont: URL, completionHandler: ((Bool) -> Void)? = nil) {
        os_log(.info, log: Self.logger, "adding '%s' to library", soundFont.path)

        // If this is a resource from iCloud we need to enable access to it. This will return `false` if the URL is
        // not in a security scope.
        let secured = soundFont.startAccessingSecurityScopedResource()
        let data = try? Data(contentsOf: soundFont, options: .dataReadingMapped)
        if secured { soundFont.stopAccessingSecurityScopedResource() }

        guard let content = data else {
            os_log(.error, log: Self.logger, "failed to fetch content")
            completionHandler?(false)
            return
        }

        let info = GetSoundFontInfo(data: content)
        if info.name.isEmpty || info.patches.isEmpty {
            os_log(.error, log: Self.logger, "failed to parse content")
            completionHandler?(false)
            return
        }
        
        let soundFont = SoundFont(info)
        let wrappedCompletonHandler: (Bool) -> Void = { result in
            if result {
                self.map[info.name] = soundFont
                self.keys = self.map.keys.sorted()
                self.notify(.added(soundFont: soundFont))
                self.save()
            }
            completionHandler?(result)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            os_log(.info, log: Self.logger, "creating SF2 file at '%s'", soundFont.fileURL.path)
            let result = FileManager.default.createFile(atPath: soundFont.fileURL.path, contents: data, attributes: nil)
            os_log(.info, log: Self.logger, "created %d", result)
            DispatchQueue.main.async { wrappedCompletonHandler(result) }
        }
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

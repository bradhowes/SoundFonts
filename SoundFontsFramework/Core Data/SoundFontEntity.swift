// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData
import SoundFontInfoLib

@objc(SoundFontEntity)
public final class SoundFontEntity: NSManagedObject, Managed {

    public static var defaultSortDescriptors: [NSSortDescriptor] = {
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true,
                                              selector: #selector(NSString.localizedCaseInsensitiveCompare))
        return [sortDescriptor]
    }()

    public static func count(_ context: NSManagedObjectContext) throws -> Int {
        return try context.count(for: fetchRequest);
    }
}

extension SoundFontEntity {

    public enum Kind {
        case builtin(path: URL)
        case installed(path: URL)
    }

    @NSManaged public private(set) var uuid: UUID
    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var path: URL
    @NSManaged public private(set) var embeddedName: String
    @NSManaged public private(set) var presets: NSOrderedSet
    @NSManaged public private(set) var resource: Bool
    @NSManaged public private(set) var visible: Bool

    public var kind: Kind { resource ? .builtin(path: path) : .installed(path: path) }
    public var exists: Bool { FileManager.default.fileExists(atPath: path.path) }

    @discardableResult
    public convenience init(context: NSManagedObjectContext, config: SoundFontInfo,
                            isResource: Bool = false) {
        self.init(context: context)

        uuid = UUID()
        name = config.embeddedName
        embeddedName = config.embeddedName
        path = config.path
        resource = isResource
        visible = true

        config.presets.enumerated().forEach { index, config in
            addToPresets(PresetEntity(context: context, index: index, config: config))
        }
    }

    public func makeSoundFontAndPatch(for patchIndex: Int) -> SoundFontAndPatch {
        SoundFontAndPatch(soundFontKey: uuid, patchIndex: patchIndex)
    }

    public func setName(_ name: String) {
        self.name = name
    }
}

extension SoundFontEntity {
    @objc(addPresetsObject:)
    @NSManaged private func addToPresets(_ value: PresetEntity)
}

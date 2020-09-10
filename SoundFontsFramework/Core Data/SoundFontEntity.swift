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
    @NSManaged public private(set) var resource: Bool
    @NSManaged public private(set) var visible: Bool
    @NSManaged private var children: NSOrderedSet

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
        config.presets.forEach { addToChildren(PresetEntity(context: context, config: $0)) }
    }

    @discardableResult
    public convenience init(context: NSManagedObjectContext, import soundFont: SoundFont) {
        self.init(context: context)

        uuid = soundFont.key
        name = soundFont.displayName
        embeddedName = soundFont.embeddedName
        path = soundFont.fileURL
        switch soundFont.kind {
        case .builtin: resource = true
        case .installed: resource = false
        }

        visible = true

        soundFont.patches.forEach { addToChildren(PresetEntity(context: context, import: $0)) }
    }


    public func setName(_ value: String) { name = value }
    public func setVisible(_ value: Bool) { visible = value }

    public var presets: EntityCollection<PresetEntity> { EntityCollection(children) }
}

extension SoundFontEntity {
    @objc(addChildrenObject:)
    @NSManaged private func addToChildren(_ value: PresetEntity)
}

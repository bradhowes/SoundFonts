// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import CoreData
import SoundFontInfoLib

@objc(SoundFont)
public final class ManagedSoundFont: NSManagedObject, Managed {
    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var path: URL
    @NSManaged public private(set) var bookmark: Data?
    @NSManaged public private(set) var embeddedName: String
    @NSManaged public private(set) var resource: Bool
    @NSManaged public private(set) var visible: Bool
    @NSManaged private var children: NSOrderedSet
    @NSManaged private var tags: NSOrderedSet

    public static var defaultSortDescriptors: [NSSortDescriptor] = {
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true,
                                              selector: #selector(NSString.localizedCaseInsensitiveCompare))
        return [sortDescriptor]
    }()

    public static var fetchRequestForRows: FetchRequest {
        let request = typedFetchRequest
        request.predicate = NSPredicate(format: "visible == YES")
        return request
    }

    public static func countRows(in context: NSManagedObjectContext) -> Int {
        return count(in: context, request: fetchRequestForRows)
    }

    public static func fetchRows(in context: NSManagedObjectContext) -> [ManagedSoundFont] {
        let request = fetchRequestForRows
        request.fetchBatchSize = 50
        request.resultType = .managedObjectResultType
        return fetch(in: context, request: request)
    }
}

extension ManagedSoundFont {

    public enum Kind {
        case builtin(path: URL)
        case bookmark(data: Data?)
    }

    public var kind: Kind { resource ? .builtin(path: path) : .bookmark(data: bookmark) }
    public var exists: Bool { FileManager.default.fileExists(atPath: path.path) }

    @discardableResult
    public convenience init(in context: NSManagedObjectContext, config: SoundFontInfo, isResource: Bool = false) {
        self.init(context: context)
        self.name = config.embeddedName
        self.embeddedName = config.embeddedName
        self.path = config.url
        self.bookmark = try? config.url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: [],
                                                     relativeTo: nil)
        self.resource = isResource
        self.visible = true
        config.presets.enumerated().forEach {
            self.addToChildren(ManagedPreset(in: context, owner: self, index: $0.offset, config: $0.element))
        }
        context.saveChangesAsync()
    }

    public func setName(_ value: String) { name = value }
    public func setVisible(_ value: Bool) { visible = value }
    public var presets: EntityCollection<ManagedPreset> { EntityCollection(children) }
}

extension ManagedSoundFont {
    @objc(addChildrenObject:)
    @NSManaged private func addToChildren(_ value: ManagedPreset)
}

extension ManagedSoundFont {
    @objc(addTagsObject:)
    @NSManaged private func addToTags(_ value: ManagedTag)
}

// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData
import Foundation
import SF2Files
import SoundFontInfoLib

/// Definition of the Core Data managed sound font entities.
@objc(ManagedSoundFont)
public final class ManagedSoundFont: NSManagedObject, Managed {

  /// The name to show in a view
  @NSManaged public private(set) var displayName: String

  /// The author name found embedded in the SF2 file
  @NSManaged public private(set) var embeddedAuthor: String
  /// The comment found embedded in the SF2 file
  @NSManaged public private(set) var embeddedComment: String
  /// The copyright found embedded in the SF2 file
  @NSManaged public private(set) var embeddedCopyright: String
  /// The name found embedded in the SF2 file
  @NSManaged public private(set) var embeddedName: String
  /// The original display name of the SF2
  @NSManaged public private(set) var originalDisplayName: String
  /// If non-nil, Data to be used to reconstruct a Bookmark
  @NSManaged public private(set) var resourceBookmark: Data?
  /// If non-nil, the name of the bookmark or the name of the sound font file
  @NSManaged public private(set) var resourceName: String?
  /// If non-nil, the URL for the resource
  @NSManaged public private(set) var resourcePath: URL?
  /// If false the sound font will not be shown. Default is true
  @NSManaged public private(set) var visible: Bool

  @NSManaged private var presets: NSOrderedSet
  @NSManaged private var tags: NSSet
}

extension ManagedSoundFont {

  /// Obtain the ordered collection of presets in the sound font.
  public var presetsCollection: EntityCollection<ManagedPreset> { EntityCollection(presets) }

  // swiftlint:disable force_cast
  /// Obtain the set of tags associated with the sound font.
  public var tagsSet: Set<ManagedTag> { tags as! Set<ManagedTag> }
  // swiftlint:enable force_cast
}

extension ManagedSoundFont {

  /// Fetching sound font rows will order them by their name in ascending order
  public static var defaultSortDescriptors: [NSSortDescriptor] = {
    let sortDescriptor = NSSortDescriptor(
      key: "displayName", ascending: true,
      selector: #selector(NSString.localizedCaseInsensitiveCompare))
    return [sortDescriptor]
  }()

  /**
   Fetch request to use for table rows.

   - parameter tag: the tag to filter with
   - returns: sound fonts that are visible and that belong to a given tag.
   */
  public static func fetchRequestForRows(tag: ManagedTag) -> FetchRequest {
    let request = typedFetchRequest
    request.predicate = NSPredicate(format: "ANY tags = %@ AND visible == YES", tag)
    return request
  }

  /**
   Obtain a count for the number of sound fonts that are visible and belong to a given tag.

   - parameter context: the context to operate in
   - parameter tag: the tag to filter with
   - returns: count of sound fonts that are visible and that belong to a given tag.
   */
  public static func countRows(in context: NSManagedObjectContext, tag: ManagedTag) -> Int {
    return count(in: context, request: fetchRequestForRows(tag: tag))
  }

  /**
   Fetch the sound fonts that are visible and belong to a given tag.

   - parameter context: the context to operate in
   - parameter tag: the tag to filter with
   - returns: collection of sound fonts that are visible and that belong to a given tag.
   */
  public static func fetchRows(in context: NSManagedObjectContext, tag: ManagedTag) -> [ManagedSoundFont] {
    let request = fetchRequestForRows(tag: tag)
    request.fetchBatchSize = 50
    request.resultType = .managedObjectResultType
    return fetch(in: context, request: request)
  }
}

extension ManagedSoundFont {

  /// Generate SoundFontKind value based on contents of various resource values
  public var kind: SoundFontKind {
    if let name = resourceName, let path = resourcePath {
      return .reference(bookmark: Bookmark(name: name, original: path, bookmark: resourceBookmark))
    }

    if let url = self.resourcePath {
      return .builtin(resource: url)
    }

    if let fileName = self.resourceName {
      return .installed(fileName: fileName)
    }

    fatalError("missing reference to sound font")
  }

  /**
   Create a new ManagedSoundFont instance using data from a SoundFontInfo description.

   - parameter context: the context to operate in
   - parameter config: the description to use
   */
  @discardableResult
  public convenience init(in context: NSManagedObjectContext, config: SoundFontInfo) {
    self.init(context: context)

    self.displayName = config.embeddedName
    self.originalDisplayName = config.embeddedName

    self.embeddedName = config.embeddedName
    self.embeddedComment = config.embeddedComment
    self.embeddedAuthor = config.embeddedAuthor
    self.embeddedCopyright = config.embeddedCopyright

    self.visible = true

    config.presets.forEach { self.addToPresets(ManagedPreset(in: context, owner: self, config: $0)) }

    self.addToTags(appState.allTag)

    context.saveChangesAsync()
  }

  /**
   Set the display name for the sound font

   - parameter name: the display name to use
   */
  public func setDisplayName(_ name: String) {
    self.displayName = name
    self.originalDisplayName = name
  }

  /**
   Set the location of the sound font file via a bookmark.

   - parameter bookmark: the location of the sound font file
   */
  public func setBookmark(_ bookmark: Bookmark) {
    self.resourceBookmark = bookmark.bookmark
    self.resourcePath = bookmark.original
    self.resourceName = bookmark.name
  }

  /**
   Set the location of the sound font file via a Bundle resource URL.

   - parameter url: the location of the sound font file
   */
  public func setBundleUrl(_ url: URL) {
    self.resourcePath = url
    self.resourceBookmark = nil
    self.resourceName = nil
    self.addToTags(appState.builtInTag)
  }

  /**
   Set the location of the sound font file via a file name in the app's private storage

   - parameter fileName: the name of the file in the app's private storage
   */
  public func setFileName(_ fileName: String) {
    self.resourceName = fileName
    self.resourceBookmark = nil
    self.resourcePath = nil
  }

  /**
   Change the visibility state of a sound font.

   - parameter value: true if visible
   */
  public func setVisible(_ value: Bool) { self.visible = value }
}

// MARK: Generated accessors for presets
extension ManagedSoundFont {

  @objc(addPresetsObject:)
  @NSManaged private func addToPresets(_ value: ManagedPreset)
}

// MARK: Generated accessors for tags
extension ManagedSoundFont {

  @objc(addTagsObject:)
  @NSManaged public func addToTags(_ value: ManagedTag)

  @objc(removeTagsObject:)
  @NSManaged public func removeFromTags(_ value: ManagedTag)
}

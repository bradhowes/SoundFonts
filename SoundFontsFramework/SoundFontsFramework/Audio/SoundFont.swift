// Copyright (c) 2016 Brad Howes. All rights reserved.

import Foundation
import SF2Files
import SoundFontInfoLib
import os

/// Representation of a sound font library. NOTE: all sound font files must have 'sf2' extension.
public final class SoundFont: Codable {
  private static let log = Logging.logger("SoundFont")
  private var log: OSLog { Self.log }

  /// Presentation name of the sound font
  public var displayName: String

  ///  The resolved URL for the sound font
  public var fileURL: URL { kind.fileURL }

  public typealias Key = UUID
  public let key: Key

  public let originalDisplayName: String

  @DecodableDefault.EmptyString var embeddedName: String
  @DecodableDefault.EmptyString var embeddedComment: String
  @DecodableDefault.EmptyString var embeddedAuthor: String
  @DecodableDefault.EmptyString var embeddedCopyright: String

  public let kind: SoundFontKind

  /// The collection of presets found in the sound font
  public let presets: [Preset]

  /// Collection of tags assigned to the sound font
  @DecodableDefault.EmptyTagSet var tags: Set<Tag.Key>

  private enum CodingKeys: String, CodingKey {
    case key
    case displayName
    case originalDisplayName
    case embeddedName
    case embeddedComment
    case embeddedAuthor
    case embeddedCopyright
    case kind
    case presets = "patches" // legacy name
    case tags
  }

  /**
   Constructor for installed sound font files -- those added via File app.

   - parameter displayName: the display name of the resource
   - parameter soundFontInfo: preset info from the sound font
   - parameter url: the resource URL for this sound font
   - parameter key: UUID for this font
   */
  public init(_ displayName: String, soundFontInfo: SoundFontInfo, url: URL, key: Key, copyFilesWhenAdding: Bool) {
    self.key = key
    self.displayName = displayName
    self.originalDisplayName = displayName
    self.embeddedName = soundFontInfo.embeddedName
    self.embeddedComment = soundFontInfo.embeddedComment
    self.embeddedAuthor = soundFontInfo.embeddedAuthor
    self.embeddedCopyright = soundFontInfo.embeddedCopyright
    self.kind = copyFilesWhenAdding
      ? .installed(fileName: displayName + "_" + key.uuidString + SF2Files.sf2DottedExtension)
      : .reference(bookmark: Bookmark(url: url, name: displayName))
    self.presets = Self.makePresets(soundFontInfo.presets)
  }

  /**
   Constructor for built-in sound font files -- those in the Bundle.

   - parameter displayName: the display name of the resource
   - parameter soundFontInfo: preset info from the sound font
   - parameter resource: the name of the resource in the bundle
   */
  public init(_ displayName: String, soundFontInfo: SoundFontInfo, resource: URL) {
    self.key = Key()
    self.displayName = displayName
    self.originalDisplayName = displayName
    self.embeddedName = soundFontInfo.embeddedName
    self.embeddedComment = soundFontInfo.embeddedComment
    self.embeddedAuthor = soundFontInfo.embeddedAuthor
    self.embeddedCopyright = soundFontInfo.embeddedCopyright
    self.kind = .builtin(resource: resource)
    self.presets = Self.makePresets(soundFontInfo.presets)
  }
}

extension SoundFont {

  public static func makeSoundFont(from url: URL,
                                   copyFilesWhenAdding: Bool) -> Result<SoundFont, SoundFontFileLoadFailure> {
    os_log(.debug, log: log, "makeSoundFont - '%{public}s'", url.lastPathComponent)

    guard let info = SoundFontInfo.load(viaParser: url) else {
      os_log(.error, log: log, "failed to process SF2 file")
      return .failure(.invalidFile(url.lastPathComponent))
    }

    guard !info.presets.isEmpty else {
      os_log(.error, log: log, "failed to locate any presets")
      return .failure(.invalidFile(url.lastPathComponent))
    }

    let (fileName, uuid) = url.lastPathComponent.stripEmbeddedUUID()

    // Strip off the extension to make a display name. We set the embedded name if it is empty, but we do not use
    // the embedded name as it is often garbage. We do show it in the SoundFont editor sheet.
    let displayName = String(fileName[fileName.startIndex..<(fileName.lastIndex(of: ".") ?? fileName.endIndex)])
    if info.embeddedName.isEmpty {
      info.embeddedName = displayName
    }

    let soundFont = SoundFont(displayName, soundFontInfo: info, url: url, key: uuid ?? Key(),
                              copyFilesWhenAdding: copyFilesWhenAdding)
    if copyFilesWhenAdding {
      do {
        try copyToAppFolder(source: url, destination: soundFont.fileURL)
      } catch {
        os_log(.error, log: log, "failed to create file")
        return .failure(.unableToCreateFile(url.lastPathComponent))
      }
    }

    return .success(soundFont)
  }

  private static func copyToAppFolder(source: URL, destination: URL) throws {
    os_log(.debug, log: log, "SF2 source: '%{public}s'", source.absoluteString)
    os_log(.debug, log: log, "SF2 destination: '%{public}s'", destination.absoluteString)
    let secured = source.startAccessingSecurityScopedResource()
    defer { if secured { source.stopAccessingSecurityScopedResource() } }
    try FileManager.default.copyItem(at: source, to: destination)
  }

  private static func makePresets(_ presets: [SoundFontInfoPreset]) -> [Preset] {
    presets.enumerated().map { Preset($0.1.name, Int($0.1.bank), Int($0.1.program), $0.0) }
  }
}

extension SoundFont {

  /// Determines if the sound font file exists on the device
  public var isAvailable: Bool { FileManager.default.fileExists(atPath: fileURL.path) }

  public subscript(index: SoundFontAndPreset) -> Preset { presets[index.presetIndex] }
  public subscript(index: Int) -> SoundFontAndPreset { makeSoundFontAndPreset(at: index) }

  public func makeSoundFontAndPreset(at index: Int) -> SoundFontAndPreset {
    .init(soundFontKey: self.key, soundFontName: self.originalDisplayName, presetIndex: index,
          itemName: presets[index].presetConfig.name)
  }

  public func makeSoundFontAndPreset(for preset: Preset) -> SoundFontAndPreset {
    makeSoundFontAndPreset(at: preset.soundFontIndex)
  }

  public func reloadEmbeddedInfo() -> Bool {
    guard let info = SoundFontInfo.load(viaParser: self.fileURL) else { return false }
    embeddedComment = info.embeddedComment
    embeddedAuthor = info.embeddedAuthor.isEmpty ? "Unknown" : info.embeddedAuthor
    embeddedCopyright = info.embeddedCopyright.isEmpty ? "Unknown" : info.embeddedCopyright
    return true
  }

  public func validate(_ tags: TagsProvider) {
    var invalidTags = [Tag.Key]()
    for tagKey in self.tags {
      if let tag = tags.getBy(key: tagKey) {
        if tag.name == "All" || tag.name == "Built-in" {
          invalidTags.append(tagKey)
          os_log(.error, log: log, "removing stock tag %{public}s", tag.name)
        }
      } else {
        invalidTags.append(tagKey)
        os_log(.error, log: log, "tag %{public}s does not exist", tagKey.uuidString)
      }
    }

    if !invalidTags.isEmpty {
      self.tags = self.tags.subtracting(invalidTags)
    }
  }
}

extension SoundFont: Hashable {

  public func hash(into hasher: inout Hasher) { hasher.combine(key) }

  public static func == (lhs: SoundFont, rhs: SoundFont) -> Bool { lhs.key == rhs.key }
}

extension SoundFont: CustomStringConvertible {

  public var description: String { "[SoundFont '\(displayName)' '\(key)]" }
}

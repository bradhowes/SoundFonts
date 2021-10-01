// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import SF2Files
import os

/// Various error conditions for loading or working with a sound font (SF2) file
public enum SoundFontKindError: Error {
  case invalidKind
  case failedToRead
  case failedToResolveURL
}

/// There are two types of SoundFont instances in the application: a built-in kind that resides in the app's bundle, and
/// a file kind which comes from an external source.
public enum SoundFontKind {
  static let log = Logging.logger("SoundFontKind")

  /// Built-in sound font file that is comes with the app. Holds a URL to a bundle resource
  case builtin(resource: URL)
  /// Sound font file that was installed by the user. Holds the name of the SF2 file
  case installed(fileName: String)
  /// Alternative sound font file that was installed by the user but that was not copied into the app's working
  /// directory.
  case reference(bookmark: Bookmark)

  /// The URL that points to the data file that defines the SoundFont.
  public var fileURL: URL {
    switch self {
    case .builtin(let resource): return resource
    case .installed(let file):
      return FileManager.default.sharedDocumentsDirectory.appendingPathComponent(file)
    case .reference(let bookmark): return bookmark.url
    }
  }

  /// The String representation of the fileURL
  public var path: String { return fileURL.path }

  /// True if the file deleted by the user
  public var removable: Bool {
    switch self {
    case .builtin: return false
    case .installed: return true
    case .reference: return true
    }
  }

  /// True if is resource
  public var resource: Bool {
    switch self {
    case .builtin: return true
    case .installed: return false
    case .reference: return false
    }
  }

  /// True if is reference
  public var reference: Bool {
    switch self {
    case .builtin: return false
    case .installed: return false
    case .reference: return true
    }
  }

  /// Key used to encode/decode the above case types.
  private enum InternalKey: Int {
    case builtin = 0
    case installed = 1
    case reference = 2
  }
}

// MARK: - Codable Protocol

extension SoundFontKind: Codable {

  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let kind = InternalKey(rawValue: try container.decode(Int.self))
    switch kind {
    case .builtin:
      let value = try container.decode(String.self)
      let name = URL(fileURLWithPath: value).deletingPathExtension().lastPathComponent
      let url = try SF2Files.resource(name: name)
      self = .builtin(resource: url)

    case .installed:
      let value = try container.decode(String.self)
      self = .installed(fileName: value)

    case .reference:
      let value = try container.decode(Bookmark.self)
      self = .reference(bookmark: value)

    default:
      throw SoundFontKindError.invalidKind
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    switch self {
    case .builtin(let resource):
      try container.encode(InternalKey.builtin.rawValue)
      try container.encode(resource.lastPathComponent)
    case .installed(let fileName):
      try container.encode(InternalKey.installed.rawValue)
      try container.encode(fileName)
    case .reference(let bookmark):
      try container.encode(InternalKey.reference.rawValue)
      try container.encode(bookmark)
    }
  }
}

// MARK: - Hashable Protocol

extension SoundFontKind: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .builtin(let resource):
      hasher.combine(InternalKey.builtin.rawValue)
      hasher.combine(resource.lastPathComponent)
    case .installed(let fileName):
      hasher.combine(InternalKey.installed.rawValue)
      hasher.combine(fileName)
    case .reference(let bookmark):
      hasher.combine(InternalKey.reference.rawValue)
      hasher.combine(bookmark)
    }
  }
}

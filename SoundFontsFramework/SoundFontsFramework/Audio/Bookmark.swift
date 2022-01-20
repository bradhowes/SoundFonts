// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

/// A bookmark represents a file located outside of the app's own storage space. It is used to reference sound font files
/// without making a copy of them. However there are risks involved, namely that the bookmark may not resolve to a real
/// file.
public final class Bookmark: Codable {
  private static let log = Logging.logger("Bookmark")
  private var log: OSLog { Self.log }

  /// The custom coding keys for a bookmark encoding
  enum CodingKeys: String, CodingKey {
    case name
    case bookmark
    case original
  }

  /// The name of the sound font represented by the bookmark
  public let name: String
  public private(set) var bookmark: Data?
  public let original: URL

  private var _resolved: URL?

  /**
   Construct a new bookmark

   - parameter url: the file to bookmark
   - parameter name: the name to associate with the bookmark
   */
  public init(url: URL, name: String) {
    self.name = name
    original = url
    bookmark = bookmarkData
    os_log(.debug, log: log, "name: %{public}s data.count: %d url: %{public}s", name, bookmark?.count ?? 0, url.path)
  }

  /**
   Restore bookmark from Core Data values
   */
  public init(name: String, original: URL, bookmark: Data?) {
    self.name = name
    self.original = original
    self.bookmark = bookmark
  }

  /**
   Attempt to reconstitute a bookmark from an encoded container

   - parameter decoder: the container to read from
   - throws exception if unable to decode from container
   */
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    name = try values.decode(String.self, forKey: .name)
    original = try values.decode(URL.self, forKey: .original)
    let data = try? values.decode(Data.self, forKey: .bookmark)
    bookmark = data
    _resolved = Self.resolve(from: data)
  }
}

extension Bookmark {

  /// The resolved URL of the bookmark. Note well that this may not point to a valid file if the file has moved or is
  /// not available.
  public var url: URL { _resolved ?? self.resolve() }

  /// Determine the availability state for a bookmarked URL
  public var isAvailable: Bool {
    let secured = url.startAccessingSecurityScopedResource()
    defer { if secured { url.stopAccessingSecurityScopedResource() } }
    return (try? url.checkResourceIsReachable()) ?? false
  }

  /// Determine if the file is located in an iCloud container
  public var isUbiquitous: Bool { FileManager.default.isUbiquitousItem(at: url) }

  /// The various iCloud states a bookmark item may be in.
  public enum CloudState {
    /// Item is on iCloud but not available locally.
    case inCloud
    /// Item is queue to be downloaded to the device
    case downloadRequested
    /// Item is currently being downloaded to the device
    case downloading
    /// Item has been downloaded and is available locally
    case downloaded
    /// Problem downloading the file from iCloud
    case downloadError
    /// Unknown state
    case unknown
  }

  /// Obtain the current iCloud state of the bookmark item
  public var cloudState: CloudState {
    guard
      let values = try? url.resourceValues(forKeys: [
        .ubiquitousItemDownloadingStatusKey,
        .ubiquitousItemIsDownloadingKey,
        .ubiquitousItemDownloadingErrorKey
      ])
    else {
      return .unknown
    }
    guard values.ubiquitousItemDownloadingError == nil else { return .downloadError }
    guard let status = values.ubiquitousItemDownloadingStatus else { return .unknown }
    switch status {
    case .current: return .downloaded
    case .downloaded: return .downloading
    case .notDownloaded: return .inCloud
    default: return .unknown
    }
  }
}

extension Bookmark {
  private static func resolve(from data: Data?) -> URL? {
    guard let data = data else { return nil }
    var isStale = false
    return try? URL(
      resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
  }

  private func resolve() -> URL {
    if let url = _resolved { return url }
    _resolved = Self.resolve(from: self.bookmark)
    return _resolved ?? original
  }

  private var bookmarkData: Data? {
    let secured = url.startAccessingSecurityScopedResource()
    defer { if secured { url.stopAccessingSecurityScopedResource() } }
    return try? url.bookmarkData(
      options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
  }
}

extension Bookmark: Hashable {

  /**
   Provide a hash for a bookmark. Relies on the bookmark hash value.

   - parameter hasher: the object to hash into
   */
  public func hash(into hasher: inout Hasher) { hasher.combine(bookmark) }

  /**
   Allow comparison operator for bookmarks

   - parameter lhs: first argument to compare
   - parameter rhs: second argument to compare
   - returns: true if they are the same
   */
  public static func == (lhs: Bookmark, rhs: Bookmark) -> Bool { lhs.bookmark == rhs.bookmark }
}

// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

private final class SF2FilesTag {}

public enum SF2FilesError: Error {
  case notFound(name: String)
  case missingResources
}

/// Public interface for the SF2Files framework. It provides URLs to SF2 files that are bundled with the framework.
@objc @objcMembers public class SF2Files: NSObject {

  /// The extension for an SF2 file
  public static let sf2Extension = "sf2"

  /// The extension for an SF2 file that begins with a period ('.')
  public static let sf2DottedExtension = "." + sf2Extension

  private static let bundle = Bundle(for: SF2FilesTag.self)

  /**
     Locate a specific SF2 resource by name.

     - parameter name: the name to look for
     - returns: the URL of the resource in the bundle
     */
  public class func resource(name: String) throws -> URL {
    guard let url = bundle.url(forResource: name, withExtension: sf2Extension) else {
      throw SF2FilesError.notFound(name: name)
    }
    return url
  }

  /// Collection of URLs for the SF2 resources in the bundle.
  public class var allResources: [URL] { bundle.urls(forResourcesWithExtension: sf2Extension, subdirectory: nil)! }

  public class func validate(expectedResourceCount: Int = 4) throws {
    let urls = allResources
    if urls.count != expectedResourceCount {
      throw SF2FilesError.missingResources
    }
  }
}

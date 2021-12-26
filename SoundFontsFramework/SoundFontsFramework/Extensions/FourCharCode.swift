// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

extension FourCharCode: ExpressibleByStringLiteral {

  public init(stringLiteral value: StringLiteralType) {
    var code: FourCharCode = 0
    // Value has to consist of 4 printable ASCII characters, e.g. '420v'.
    // Note: This implementation does not enforce printable range (32-126)
    if value.count == 4 && value.utf8.count == 4 {
      for byte in value.utf8 {
        code = code << 8 + FourCharCode(byte)
      }
    } else {
      os_log(
        .error,
        "FourCharCode: Can't initialize with '%s', only printable ASCII allowed. Setting to '????'.",
        value)
      code = 0x3F3F_3F3F  // = '????'
    }
    self = code
  }

  public init(extendedGraphemeClusterLiteral value: String) {
    self = FourCharCode(stringLiteral: value)
  }
  public init(unicodeScalarLiteral value: String) { self = FourCharCode(stringLiteral: value) }
  public init(_ value: String) { self = FourCharCode(stringLiteral: value) }
}

extension FourCharCode {

  private static let bytesSizeForStringValue = MemoryLayout<Self>.size

  /// Obtain a 4-character string from our value - based on https://stackoverflow.com/a/60367676/629836
  public var stringValue: String {
    withUnsafePointer(to: bigEndian) { pointer in
      pointer.withMemoryRebound(to: UInt8.self, capacity: Self.bytesSizeForStringValue) { bytes in
        String(
          bytes: UnsafeBufferPointer(start: bytes, count: Self.bytesSizeForStringValue),
          encoding: .macOSRoman) ?? "????"
      }
    }
  }
}

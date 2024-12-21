// Copyright © 2019 Brad Howes. All rights reserved.

import os

private class BundleTag {}

/// Builder of OSLog values for categorization / classification of log statements.
public struct Logging {

  /// The top-level identifier for the app.
  public static let subsystem = Bundle(for: BundleTag.self).bundleIdentifier?.lowercased() ?? "?"

  /**
   Create a new logger for a subsystem

   - parameter category: the subsystem to log under
   - returns: OSLog instance to use for subsystem logging
   */
  public static func logger(_ category: String) -> OSLog { .init(subsystem: subsystem, category: category) }

  public static func logger(_ category: String) -> Logger { .init(subsystem: subsystem, category: category) }
}

extension Logger {

  public func measure<T>(_ label: String, _ block: () throws -> T) throws -> T {
    let start = Date()
    defer { self.info("\(label) END - duration: \(Date().timeIntervalSince(start))s") }
    self.info("\(label) BEGIN")
    return try block()
  }

  public func measure<T>(_ label: String, _ block: () -> T) -> T {
    let start = Date()
    defer { self.info("\(label) END - duration: \(Date().timeIntervalSince(start))s") }
    self.info("\(label) BEGIN")
    return block()
  }

  public func measure(_ label: String, _ block: () throws -> Void) throws {
    let start = Date()
    defer { self.info("\(label) END - duration: \(Date().timeIntervalSince(start))s") }
    self.info("\(label) BEGIN")
    try block()
  }

  public func measure(_ label: String, _ block: () -> Void) {
    let start = Date()
    defer { self.info("\(label) END - duration: \(Date().timeIntervalSince(start))s") }
    self.info("\(label) BEGIN")
    block()
  }
}

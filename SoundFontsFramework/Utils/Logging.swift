// Copyright © 2019 Brad Howes. All rights reserved.

import os

private class BundleTag {}

/**
 Builder of OSLog values for categorization / classification of log statements.
 */
public struct Logging {

    /// The top-level identifier for the app.
    public static let subsystem = Bundle(for: BundleTag.self).bundleID

    /**
     Create a new logger for a subsystem

     - parameter category: the subsystem to log under
     - returns: OSLog instance to use for subsystem logging
     */
    public static func logger(_ category: String) -> OSLog { OSLog(subsystem: subsystem, category: category) }
}

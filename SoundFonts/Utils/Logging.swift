// Copyright © 2019 Brad Howes. All rights reserved.

import os

public struct Logging {

    /// The top-level identifier for this app
    static let subsystem = "com.braysoftware.SoundFonts"

    /**
     Create a new logger for a subsystem

     - parameter category: the subsystem to log under
     - returns: OSLog instance to use for subsystem logging
     */
    public static func logger(_ category: String) -> OSLog { OSLog(subsystem: subsystem, category: category) }
}

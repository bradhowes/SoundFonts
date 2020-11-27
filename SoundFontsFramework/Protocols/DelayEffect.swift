// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

public protocol DelayEffect: NSObject {
    var active: DelayConfig { get set }
    var presets: [String: DelayConfig] { get }

    func savePreset(name: String, config: DelayConfig)
    func removePreset(name: String)
}

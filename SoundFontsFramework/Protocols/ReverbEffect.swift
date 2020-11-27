// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

public protocol ReverbEffect {
    var active: ReverbConfig { get set }
    var presets: [String: ReverbConfig] { get }

    func savePreset(name: String, config: ReverbConfig)
    func removePreset(name: String)
}

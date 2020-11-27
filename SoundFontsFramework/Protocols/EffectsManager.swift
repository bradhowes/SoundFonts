// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

public protocol EffectsManager {
    func setReverbConfig(_ config: ReverbConfig)
    func setDelayConfig(_ config: DelayConfig)
}

// Copyright © 2020 Brad Howes. All rights reserved.

import AudioUnit

/**
 Protocol that handles AUParameter get and set operations.
 */
public protocol AUParameterHandler {
    func set(_ parameter: AUParameter, value: AUValue)
    func get(_ parameter: AUParameter) -> AUValue
}

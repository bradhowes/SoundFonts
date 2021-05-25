// Copyright © 2020 Brad Howes. All rights reserved.

import AudioUnit

/**
 Protocol that handles AUParameter get and set operations.
 */
public protocol AUParameterHandler {

    /**
     Set a parameter with a new value.

     - parameter parameter: the configuration parameter to set
     - parameter value: the value to set it to
     */
    func set(_ parameter: AUParameter, value: AUValue)

    /**
     Get a parameter's current value.

     - parameter parameter: the configuration parameter to get
     - returns: the current value
     */
    func get(_ parameter: AUParameter) -> AUValue
}

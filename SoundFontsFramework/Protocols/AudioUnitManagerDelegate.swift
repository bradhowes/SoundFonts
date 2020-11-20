// Copyright © 2020 Brad Howes. All rights reserved.

/**
 Delegation protocol for AudioUnitManager class.
 */
public protocol AudioUnitManagerDelegate: class {

    /**
     Notification that a ViewController for the audio unit has been instantiated.
     */
    func connected()
}

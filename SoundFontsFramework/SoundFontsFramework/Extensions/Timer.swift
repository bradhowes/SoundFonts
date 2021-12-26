// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

public extension Timer {

  /**
   Create a timer that will fire just once after some interval has elapsed.

   - parameter after: the duration to wait before firing
   - parameter block: the closure to call when the timer fires
   - returns: new Timer instance
   */
  @discardableResult
  class func once(after: TimeInterval, _ block: @escaping (Timer) -> Void) -> Timer {
    once(when: Date().addingTimeInterval(after), block)
  }

  /**
   Create a timer that will fire just once at a given time.

   - parameter when: the to fire
   - parameter block: the closure to call when the timer fires
   - returns: new Timer instance
   */
  @discardableResult
  class func once(when: Date, _ block: @escaping (Timer) -> Void) -> Timer {
    let timer = Timer(fire: when, interval: 0.0, repeats: false, block: block)
    RunLoop.current.add(timer, forMode: .default)
    return timer
  }

  /**
   Create a timer that will fire repeatedly every N seconds.

   - parameter interval: the number of seconds between firings
   - parameter block: the closure to call when the timer fires
   - returns: new Timer instance
   */
  @discardableResult
  class func every(_ interval: TimeInterval, _ block: @escaping (Timer) -> Void) -> Timer {
    let timer = Timer(timeInterval: interval, repeats: true, block: block)
    RunLoop.current.add(timer, forMode: .default)
    return timer
  }
}

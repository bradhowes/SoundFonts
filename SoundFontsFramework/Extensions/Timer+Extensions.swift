// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

extension Timer {

    @discardableResult
    public class func once(after: TimeInterval, _ block: @escaping (Timer) -> Void) -> Timer {
        once(when: Date().addingTimeInterval(after), block)
    }

    @discardableResult
    public class func once(when: Date, _ block: @escaping (Timer) -> Void) -> Timer {
        let timer = Timer(fire: when, interval: 0.0, repeats: false, block: block)
        RunLoop.current.add(timer, forMode: .default)
        return timer
    }

    @discardableResult
    public class func every(_ interval: TimeInterval, _ block: @escaping (Timer) -> Void) -> Timer {
        let timer = Timer(timeInterval: interval, repeats: true, block: block)
        RunLoop.current.add(timer, forMode: .default)
        return timer
    }
}

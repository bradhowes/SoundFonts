// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/**
 The collection of event types that can be targeted in the `UpperViewSwipingActivity.addTarget` method
 */
public enum UpperViewSwipingEvent {
    /// Swiping to the left
    case swipeLeft
    /// Swiping to the right
    case swipeRight
}

/**
 Manages what swiping activity does.
 */
public protocol UpperViewSwipingActivity {

    /// The gesture recognizer used to handle swiping to the left
    var swipeLeft: UISwipeGestureRecognizer {get}
    /// The gesture recognizer used to handle swiping to the right
    var swipeRight: UISwipeGestureRecognizer {get}

    /**
     Link a button / gesture event to a target/selector combination

     - parameter event: the event to link to
     - parameter closure: the closure to invokes when the event takes place
     */
    func addEventClosure(_ event: UpperViewSwipingEvent, _ closure: @escaping (AnyObject) -> Void)
}

extension UpperViewSwipingActivity {

    /**
     Link a button / gesture event to a target/selector combination

     - parameter event: the event to link to
     - parameter closure: the closure to invokes when the event takes place
     */
    public func addEventClosure(_ event: UpperViewSwipingEvent, _ closure: @escaping (AnyObject) -> Void) {
        switch event {
        case .swipeLeft: swipeLeft.addClosure(closure)
        case .swipeRight: swipeRight.addClosure(closure)
        }
    }
}

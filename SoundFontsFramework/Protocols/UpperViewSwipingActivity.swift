// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/**
 The collection of event types that can be targeted in the `UpperViewSwipingActivity.addTarget` method
 */
public enum UpperViewSwipingEvent {
    case swipeLeft
    case swipeRight
}

/**
 Manages what swiping activity does.
 */
public protocol UpperViewSwipingActivity {

    var swipeLeft: UISwipeGestureRecognizer {get}
    var swipeRight: UISwipeGestureRecognizer {get}

    /**
     Link a button / gesture event to a target/selector combination

     - parameter event: the event to link to
     - parameter target: the object to call when the event takes place
     - parameter action: the function to call when the event takes place
     */
    func addEventClosure(_ event: UpperViewSwipingEvent, _ closure: @escaping (AnyObject) -> Void)
}

extension UpperViewSwipingActivity {

    /**
     Attach an event notification to the given object/selector pair so that future events will invoke the selector.

     - parameter event: the event to attach to
     - parameter target: the object to notify
     - parameter action: the selector to invoke
     */
    public func addEventClosure(_ event: UpperViewSwipingEvent, _ closure: @escaping (AnyObject) -> Void) {
        switch event {
        case .swipeLeft: swipeLeft.addClosure(closure)
        case .swipeRight: swipeRight.addClosure(closure)
        }
    }
}

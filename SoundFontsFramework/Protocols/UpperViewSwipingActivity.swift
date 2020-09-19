// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

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

    /**
     Link a button / gesture event to a target/selector combination

     - parameter event: the event to link to
     - parameter target: the object to call when the event takes place
     - parameter action: the function to call when the event takes place
     */
    func addEventClosure(_ event: UpperViewSwipingEvent, _ closure: @escaping () -> Void)
}

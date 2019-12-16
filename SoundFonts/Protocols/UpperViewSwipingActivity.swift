// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/**
 The collection of event types that can be targeted in the `UpperViewSwipingActivity.addTarget` method
 */
enum UpperViewSwipingEvent {
    case swipeLeft
    case swipeRight
}

/**
 Manages what swiping activity does.
 */
protocol UpperViewSwipingActivity {

    /**
     Link a button / gesture event to a target/selector combination

     - parameter event: the event to link to
     - parameter target: the object to call when the event takes place
     - parameter action: the function to call when the event takes place
     */
    func addTarget(_ event: UpperViewSwipingEvent, target: Any, action: Selector)
}


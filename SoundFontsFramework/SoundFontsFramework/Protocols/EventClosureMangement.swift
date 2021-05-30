// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/// Manages what swiping activity does.
public protocol EventClosureManagement {

  typealias Closure = () -> Void

  func addEventClosure<EventType>(_ event: EventType, _ closure: @escaping Closure)
}

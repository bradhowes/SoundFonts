// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

/// Extend UIControl to accept closures for events.
extension UIControl {

  /// Type of closure to invoke when control fires.
  public typealias Closure = (AnyObject) -> Void

  /**
   Add a closure to the control.

   - parameter controlEvents: the event to register for
   - parameter closure: the closure to call when the event happens
   - returns: token to be used when removing a registration
   */
  @discardableResult
  func addClosure(for controlEvents: UIControl.Event = .touchUpInside, _ closure: @escaping Closure) -> UUID {
    let sleeve = BoxedClosure(closure)
    addTarget(sleeve, action: #selector(BoxedClosure.invoke(_:)), for: controlEvents)
    let key = UUID()
    objc_setAssociatedObject(self, "[\(key)]", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    return key
  }

  /**
   Remove a closure registration.

   - parameter key: the token that was obtained from addClosure call
   - parameter controlEvents: the event that was registered for in the addClosure call
   */
  func removeClosure(key: UUID, for controlEvents: UIControl.Event) {
    guard let sleeve = objc_getAssociatedObject(self, "[\(key)]") else { return }
    removeTarget(sleeve, action: nil, for: controlEvents)
    objc_setAssociatedObject(self, "[\(key)]", nil, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
  }
}

@objc private class BoxedClosure: NSObject {
  let closure: UIControl.Closure
  init(_ closure: @escaping UIControl.Closure) { self.closure = closure }
  @objc func invoke(_ sender: AnyObject) { closure(sender) }
}

// From https://stackoverflow.com/a/63738419/629836

import Foundation
import UIKit

/// Template class that manages an association between two objects using Objective-C API.
final class AssociatedObject<T> {
  private let policy: objc_AssociationPolicy

  /**
   Creates an associated value wrapper.
   - parameter policy: The policy for the association.
   */
  init(policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
    self.policy = policy
  }

  /**
   Getter and setting for the associated value.

   - parameter index: The source object for the association.
   - returns: the current value for the getter and nil for the setter
   */
  subscript(index: AnyObject) -> T? {
    get { objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as? T }
    set {
      objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, policy)
    }
  }
}

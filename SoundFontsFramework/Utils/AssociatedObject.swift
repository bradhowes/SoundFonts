// From https://stackoverflow.com/a/63738419/629836

import UIKit
import Foundation

public final class AssociatedObject<T> {
    private let policy: objc_AssociationPolicy

    /// Creates an associated value wrapper.
    /// - Parameter policy: The policy for the association.
    public init(policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        self.policy = policy
    }

    /// Accesses the associated value.
    /// - Parameter index: The source object for the association.
    public subscript(index: AnyObject) -> T? {
        get { objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as? T }
        set { objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, policy) }
    }
}

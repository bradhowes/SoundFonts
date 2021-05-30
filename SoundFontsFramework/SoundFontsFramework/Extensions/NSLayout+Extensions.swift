import UIKit

extension NSLayoutConstraint {

  /**
     Change multiplier constraint

     - parameter multiplier: CGFloat
     - returns: NSLayoutConstraint
     */
  func setMultiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {
    guard let firstItem = self.firstItem else { return self }
    guard let secondItem = self.secondItem else { return self }

    NSLayoutConstraint.deactivate([self])
    let newConstraint = NSLayoutConstraint(
      item: firstItem,
      attribute: firstAttribute,
      relatedBy: relation,
      toItem: secondItem,
      attribute: secondAttribute,
      multiplier: multiplier,
      constant: constant)

    newConstraint.priority = priority
    newConstraint.shouldBeArchived = self.shouldBeArchived
    newConstraint.identifier = self.identifier

    NSLayoutConstraint.activate([newConstraint])
    return newConstraint
  }
}

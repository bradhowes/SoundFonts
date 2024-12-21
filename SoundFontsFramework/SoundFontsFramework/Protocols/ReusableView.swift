// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/// Protocol for UIView "cell" classes that will be recycled and used over and over again to render content in a
/// container such as UICollectionView.
public protocol ReusableView: AnyObject {

  /// Obtain the name of the identifier for this class
  static var reuseIdentifier: String { get }
}

extension ReusableView where Self: UIView {

  /// Default implementation of the reuseIdentifier that uses the name of the class
  public static var reuseIdentifier: String {
    return NSStringFromClass(self).components(separatedBy: ".").last ?? ""
  }
}

extension ReusableView where Self: UITableViewHeaderFooterView {

  /// Default implementation of the reuseIdentifier that uses the name of the class
  public static var reuseIdentifier: String {
    return NSStringFromClass(self).components(separatedBy: ".").last ?? ""
  }
}

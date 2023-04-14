// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

extension UICollectionView {

  /**
   Register a cell view type that implements ReusableView protocol.

   - parameter _: the cell class to register (ignored)
   */
  func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView {
    register(T.self, forCellWithReuseIdentifier: T.reuseIdentifier)
  }

  /**
   Register a cell view type that implements the NibLoadableView protocol.

   - parameter _: the cell class to register (ignored)
   */
  func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView {
    register(T.nib, forCellWithReuseIdentifier: T.reuseIdentifier)
  }

  /**
   Obtain a cell view to use to render cell content in a collection view.

   - parameter indexPath: the location of the cell that is being rendered
   - returns: instance of a T class
   */
  @inlinable
  func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T where T: ReusableView {
    let ident = T.reuseIdentifier
    guard let cell = dequeueReusableCell(withReuseIdentifier: ident, for: indexPath) as? T else {
      fatalError("could not dequeue cell with identifier \(ident)")
    }
    return cell
  }

  /**
   Generic method to obtain the cell at a given index. Will return nil if index is invalid or not visible.

   - parameter indexPath: the index to use
   - returns: optional cell of the indicated type
   */
  @inlinable
  func cellForItem<T: UICollectionViewCell>(at indexPath: IndexPath) -> T? where T: ReusableView {
    cellForItem(at: indexPath) as? T
  }
}

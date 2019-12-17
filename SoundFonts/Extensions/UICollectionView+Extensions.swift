// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

extension UICollectionView {

    /**
     Register a cell view type that implements ReusableView protocol.
    
     - parameter _: the cell class to register (ignored)
     */
    func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView {
        let ident = T.reuseIdentifier
        register(T.self, forCellWithReuseIdentifier: ident)
    }

    /**
     Register a cell view type that implements the NibLoadableView protocol.
    
     - parameter _: the cell class to register (ignored)
     */
    func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView {
        let ident = T.reuseIdentifier
        register(T.nib, forCellWithReuseIdentifier: ident)
    }

    /**
     Obtain a cell view to use to render cell content in a collection view.
    
     - parameter indexPath: the location of the cell that is being rendered
     - returns: instance of a T class
     */
    func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T where T: ReusableView {
        let ident = T.reuseIdentifier
        guard let cell = dequeueReusableCell(withReuseIdentifier: ident, for: indexPath) as? T else {
            fatalError("could not dequeue cell with identifier \(ident)")
        }
        return cell
    }

    func cellForItem<T: UICollectionViewCell>(at indexPath: IndexPath) -> T? where T: ReusableView {
        return cellForItem(at: indexPath) as? T
    }
}

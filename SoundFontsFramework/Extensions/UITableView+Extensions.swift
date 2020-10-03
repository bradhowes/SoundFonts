// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

extension UITableView {

    /**
     Register a cell view type that implements ReusableView protocol.
    
     - parameter _: the cell class to register (ignored)
     */
    public func register<T: UITableViewCell>(_: T.Type) where T: ReusableView { register(T.self, forCellReuseIdentifier: T.reuseIdentifier) }

    /**
     Register a cell view type that implements the NibLoadableView protocol.
    
     - parameter _: the cell class to register (ignored)
     */
    public func register<T: UITableViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView { register(T.nib, forCellReuseIdentifier: T.reuseIdentifier) }

    /**
     Obtain a cell view to use to render cell content in a collection view.
    
     - parameter indexPath: the location of the cell that is being rendered
     - returns: instance of a T class
     */
    public func dequeueReusableCell<T: UITableViewCell>(at indexPath: IndexPath) -> T where T: ReusableView {
        let ident = T.reuseIdentifier
        guard let cell = dequeueReusableCell(withIdentifier: ident, for: indexPath) as? T else {
            fatalError("could not dequeue cell with identifier \(ident)")
        }
        return cell
    }

    /**
     Obtain a cell view for the given index.

     - parameter indexPath: the location of the cell to return
     - returns: optional cell instance (nil if index path is out of bounds)
     */
    public func cellForRow<T: UITableViewCell>(at indexPath: IndexPath) -> T? where T: ReusableView { cellForRow(at: indexPath) as? T }
}

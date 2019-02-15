//
//  UICollectionView+Extensions.swift
//  SoundFonts
//
//  Created by Brad Howes on 2/13/19.
//  Copyright © 2019 Brad Howes. All rights reserved.
//

import UIKit

extension UITableView {
    
    /**
     Register a cell view type that implements ReusableView protocol.
    
     - parameter _: the cell class to register (ignored)
     */
    func register<T: UITableViewCell>(_: T.Type) where T: ReusableView {
        let ident = T.reuseIdentifier
        register(T.self, forCellReuseIdentifier: ident)
    }

    /**
     Register a cell view type that implements the NibLoadableView protocol.
    
     - parameter _: the cell class to register (ignored)
     */
    func register<T: UITableViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView {
        let ident = T.reuseIdentifier
        register(T.nib, forCellReuseIdentifier: ident)
    }

    /**
     Obtain a cell view to use to render cell content in a collection view.
    
     - parameter indexPath: the location of the cell that is being rendered
     - returns: instance of a T class
     */
    func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T where T: ReusableView {
        let ident = T.reuseIdentifier
        guard let cell = dequeueReusableCell(withIdentifier: ident, for: indexPath) as? T else {
            fatalError("could not dequeue cell with identifier \(ident)")
        }
        return cell
    }

    func cellForRow<T: UITableViewCell>(at indexPath: IndexPath) -> T? where T: ReusableView {
        return cellForRow(at: indexPath) as? T
    }
}

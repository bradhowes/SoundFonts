//
//  UICollectionView+Extensions.swift
//  SoundFonts
//
//  Created by Brad Howes on 2/13/19.
//  Copyright © 2019 Brad Howes. All rights reserved.
//

import UIKit

extension UICollectionView {
    
    func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView {
        let ident = T.defaultReuseIdentifier
        register(T.self, forCellWithReuseIdentifier: ident)
    }

    func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView {
        // let bundle = Bundle(for: T.self)
        // let nib = UINib(nibName: T.nibName, bundle: bundle)
        let ident = T.defaultReuseIdentifier
        register(T.nib, forCellWithReuseIdentifier: ident)
    }

    func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T where T: ReusableView {
        let ident = T.defaultReuseIdentifier
        guard let cell = dequeueReusableCell(withReuseIdentifier: ident, for: indexPath) as? T else {
            fatalError("could not dequeue cell with identifier \(ident)")
        }
        return cell
    }
}

// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

class FavoriteMover: NSObject {

    let view: UICollectionView
    var cell: FavoriteCell?

    init(view: UICollectionView, gr: UILongPressGestureRecognizer) {
        self.view = view
        super.init()
        gr.minimumPressDuration = 0.25
        gr.addTarget(self, action: #selector(handleLongPress))
    }
    
    @objc func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        switch(gr.state) {
        case .began:
            let pos = gr.location(in: view)
            guard let indexPath = view.indexPathForItem(at: pos) else { return }
            guard let cell: FavoriteCell = view.cellForItem(at: indexPath) else { return }
            self.cell = cell
            view.beginInteractiveMovementForItem(at: indexPath)
            cell.moving = true
            
        case .changed:
            let pos = gr.location(in: gr.view!)
            view.updateInteractiveMovementTargetPosition(pos)
            
        case .ended:
            view.endInteractiveMovement()
            cell?.moving = false

        default:
            view.cancelInteractiveMovement()
            cell?.moving = false
        }
    }
}

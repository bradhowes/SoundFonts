// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/// Manages the movement of a Favorite cells in a UICollectionView
final class FavoriteMover: NSObject {

  private let view: UICollectionView
  private var cell: FavoriteCell?

  /**
   Create a new mover for the given view and long-press gesture recognizer.

   - parameter view: the view to manage
   - parameter recognizer: the long-press gesture recognizer that triggers a move.
   */
  init(view: UICollectionView, recognizer: UILongPressGestureRecognizer) {
    self.view = view
    super.init()
    recognizer.minimumPressDuration = 0.25
    recognizer.addTarget(self, action: #selector(handleLongPress))
  }

  /**
   Handle a long-press gesture.

   - parameter recognizer: the gesture recognizer being used
   */
  @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
    switch recognizer.state {
    case .began:
      let pos = recognizer.location(in: view)
      guard let indexPath = view.indexPathForItem(at: pos) else { return }
      guard let cell: FavoriteCell = view.cellForItem(at: indexPath) else { return }
      self.cell = cell
      view.beginInteractiveMovementForItem(at: indexPath)
      cell.moving = true

    case .changed:
      let pos = recognizer.location(in: recognizer.view!)
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

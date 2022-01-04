import UIKit

/**
 View controller for the tutorial pages. Nearly all of the functionality is delegated to the
 `TutorialContentPagerViewController`. This view controller does respond to touches on either side of the view to
 change the current page position.
 */
class TutorialPageViewController: UIViewController {

  private var pager: TutorialContentPagerViewController? {
    super.parent as? TutorialContentPagerViewController
  }

  /**
   Respond to touch events that occur at the left/right sides of the view, command the `pager` to change to the
   page appropriate for the edge.

   - parameter touches: the collection of touches that caused the event
   - parameter event: the event that took place (ignored)
   */
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    let position = touches.first!.location(in: self.view)
    if position.x > self.view.frame.width * 0.8 {
      pager?.nextPage()
    } else if position.x < self.view.frame.size.width * 0.20 {
      pager?.previousPage()
    }
  }
}

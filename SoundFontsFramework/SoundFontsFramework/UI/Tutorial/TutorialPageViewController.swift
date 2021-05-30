import UIKit

class TutorialPageViewController: UIViewController {

  private var pager: TutorialContentPagerViewController? {
    super.parent as? TutorialContentPagerViewController
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    let position = touches.first!.location(in: self.view)
    if position.x > self.view.frame.width * 0.8 {
      pager?.nextPage()
    } else if position.x < self.view.frame.size.width * 0.20 {
      pager?.previousPage()
    }
  }
}

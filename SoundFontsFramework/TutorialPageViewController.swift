import UIKit

class TutorialPageViewController: UIViewController {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let position = touches.first!.location(in: self.view)
        if position.x > self.view.frame.width * 0.75 {
            if let pager = parent as? TutorialViewController {
                pager.nextPage()
            }
        }
        else if position.x < self.view.frame.size.width / 4 {
            if let pager = parent as? TutorialViewController {
                pager.previousPage()
            }
        }
    }
}

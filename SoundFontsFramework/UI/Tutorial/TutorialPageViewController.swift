import UIKit

class TutorialPageViewController: UIViewController {

    @IBOutlet weak var doneButton: UIButton?

    override func viewDidLoad() {
        if let doneButton = self.doneButton {
            doneButton.layer.borderColor = UIColor.systemTeal.cgColor
            doneButton.layer.borderWidth = 1
            doneButton.layer.cornerRadius = doneButton.bounds.height / 2
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let position = touches.first!.location(in: self.view)
        if position.x > self.view.frame.width * 0.8 {
            if let pager = parent as? TutorialViewController {
                pager.nextPage()
            }
        }
        else if position.x < self.view.frame.size.width * 0.20 {
            if let pager = parent as? TutorialViewController {
                pager.previousPage()
            }
        }
    }

    @IBAction func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
}

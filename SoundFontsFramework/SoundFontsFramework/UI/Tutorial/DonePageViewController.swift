import UIKit

class DonePageViewController: TutorialPageViewController {

  @IBOutlet weak var doneButton: UIButton?

  override func viewDidLoad() {
    super.viewDidLoad()

    if let doneButton = self.doneButton {
      doneButton.layer.borderColor = UIColor.systemTeal.cgColor
      doneButton.layer.borderWidth = 1
      doneButton.layer.cornerRadius = doneButton.bounds.height / 2
    }
  }

  @IBAction func doneButtonPressed(_ sender: Any) {
    dismiss(animated: true)
  }
}

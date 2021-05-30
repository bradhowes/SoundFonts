import UIKit

class PresetsPageViewController: TutorialPageViewController {

  @IBOutlet weak var descriptionText: UILabel?

  override func viewDidLoad() {
    super.viewDidLoad()

    let tealAttributes = [NSAttributedString.Key.foregroundColor: UIColor.systemTeal]

    let desc = NSMutableAttributedString(
      string:
        "Shows visible presets in the active soundfont file. Any favorites you create will appear in ",
      attributes: tealAttributes)

    let goldAttributes = [NSAttributedString.Key.foregroundColor: UIColor.systemOrange]
    desc.append(NSAttributedString(string: "gold", attributes: goldAttributes))
    desc.append(NSAttributedString(string: ".", attributes: tealAttributes))

    descriptionText?.attributedText = desc
  }
}

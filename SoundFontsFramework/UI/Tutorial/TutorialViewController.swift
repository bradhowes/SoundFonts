import UIKit

public final class TutorialViewController: UIViewController {

    public class func instantiate() -> UIViewController? {
        let storyboard = UIStoryboard(name: "Tutorial", bundle: Bundle(for: TutorialViewController.self))
        let viewController = storyboard.instantiateInitialViewController()
        return viewController
    }

    @IBAction func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
}

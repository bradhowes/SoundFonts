import UIKit

public final class Tutorial2ViewController: UIViewController {

    public class func instantiate() -> UIViewController? {
        let storyboard = UIStoryboard(name: "Tutorial2", bundle: Bundle(for: Tutorial2ViewController.self))
        let viewController = storyboard.instantiateInitialViewController()
        return viewController
    }

    @IBAction func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
}

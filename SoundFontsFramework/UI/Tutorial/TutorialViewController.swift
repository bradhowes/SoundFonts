import UIKit

public final class TutorialViewController: UIViewController {

    private var stagedChanges: [String]?

    /**
     Create a new TutorialViewController. If given a collection of changes, it will show a "Recent Changes" page with
     the contents. Otherwise, it will show the tutorial pages.

     @param changes optional collection of changes that this version contains over past ones
     */
    public class func instantiate(_ changes: [String]? = nil) -> UIViewController? {
        let storyboard = UIStoryboard(name: "Tutorial", bundle: Bundle(for: TutorialViewController.self))
        let viewController = storyboard.instantiateInitialViewController()
        if let vc = viewController as? UINavigationController,
           let top = vc.topViewController as? TutorialViewController {
            if let changes = changes {
                // Only show the updates page if there are any changes to reveal
                print("TutorialViewController setting showChanges - \(changes.count)")
                guard !changes.isEmpty else { return nil }
                top.stagedChanges = changes
            }
        }
        return viewController
    }

    @IBAction func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }

    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? TutorialContentPagerViewController {
            vc.changes = stagedChanges
            stagedChanges = nil
        }
        super.prepare(for: segue, sender: sender)
    }
}

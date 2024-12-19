import UIKit
import os

public final class TutorialViewController: UIViewController {
  private static let log: Logger = Logging.logger("TutorialViewController")
  private var log: Logger { Self.log }

  // Temporary holding area for changes until the segue for the TutorialContentPagerViewController fires
  public private(set) var stagedChanges: [String]?

  /**
   Create a new TutorialViewController to show the tutorial.
   */
  public static func instantiate() -> UIViewController? {
    log.debug("instantiate")
    let viewControllers = createViewControllers()
    return viewControllers?.0
  }

  private static func createViewControllers() -> (UINavigationController, TutorialViewController)? {
    let storyboard = UIStoryboard(name: "Tutorial", bundle: Bundle(for: TutorialViewController.self))
    let viewController = storyboard.instantiateInitialViewController()
    guard let vc = viewController as? UINavigationController,
          let top = vc.topViewController as? TutorialViewController else {
      log.error("problem instantiating TutorialViewController from storyboard")
      return nil
    }

    return (vc, top)
  }

  /**
   Create a new TutorialViewController. If given a collection of changes, it will show a "Recent Changes" page with
   the contents. Otherwise, it will show the tutorial pages.

   @param changes optional collection of changes that this version contains over past ones
   */
  public static func instantiateChanges(_ changes: [String]) -> UIViewController? {
    log.debug("instantiate - \(changes.count)")
    guard !changes.isEmpty else {
      log.debug("nothing to show")
      return nil
    }

    let viewControllers = createViewControllers()
    viewControllers?.1.stagedChanges = changes
    return viewControllers?.0
  }

  @IBAction func doneButtonPressed(_ sender: Any) {
    presentingViewController?.dismiss(animated: true)
  }

  override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    log.debug("prepare")
    if let vc = segue.destination as? TutorialContentPagerViewController {
      vc.changes = stagedChanges
      // stagedChanges = nil
    }
    super.prepare(for: segue, sender: sender)
  }
}

import UIKit
import os

public final class TutorialViewController: UIViewController {
  private static let log = Logging.logger("TutorialViewController")
  private var log: OSLog { Self.log }

  private static let changesDisabled = false

  // Temporary holding area for changes until the segue for the TutorialContentPagerViewController fires
  private var stagedChanges: [String]?

  /**
   Create a new TutorialViewController to show the tutorial.
   */
  public static func instantiate() -> UIViewController? {
    os_log(.debug, log: log, "instantiate")
    let viewControllers = createViewControllers()
    return viewControllers?.0
  }

  private static func createViewControllers() -> (UINavigationController, TutorialViewController)? {
    let storyboard = UIStoryboard(name: "Tutorial", bundle: Bundle(for: TutorialViewController.self))
    let viewController = storyboard.instantiateInitialViewController()
    guard let vc = viewController as? UINavigationController,
          let top = vc.topViewController as? TutorialViewController else {
      os_log(.error, log: log, "problem instantiating TutorialViewController from storyboard")
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
    os_log(.debug, log: log, "instantiate - %d", changes.count)
    guard !changes.isEmpty else {
      os_log(.debug, log: log, "nothing to show")
      return nil
    }

    if changesDisabled { return nil }
    let viewControllers = createViewControllers()
    viewControllers?.1.stagedChanges = changes
    return viewControllers?.0
  }

  @IBAction func doneButtonPressed(_ sender: Any) {
    dismiss(animated: true)
  }

  override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    os_log(.debug, log: log, "prepare")
    if let vc = segue.destination as? TutorialContentPagerViewController {
      vc.changes = stagedChanges
      stagedChanges = nil
    }
    super.prepare(for: segue, sender: sender)
  }
}

import UIKit

public final class TutorialContentPagerViewController: UIPageViewController {

  public var changes: [String]?

  private let pages: [TutorialPageViewController] = [
    loadPage("Intro"),
    loadPage("SoundFontList"),
    loadPage("TagsList"),
    loadPage("Presets"),
    loadPage("InfoBar1"),
    loadPage("InfoBar2"),
    loadPage("Favorites"),
    loadPage("Reverb"),
    loadPage("Delay"),
    loadPage("Settings"),
    loadPage("Done")
  ]

  override public func viewDidLoad() {
    super.viewDidLoad()
    dataSource = self

    if let changes = changes {
      setViewControllers([loadChanges(changes)], direction: .forward, animated: true)
    } else {
      setViewControllers([pages[0]], direction: .forward, animated: true)
    }

    let appearance = UIPageControl.appearance(whenContainedInInstancesOf: [
      UIPageViewController.self
    ])
    appearance.pageIndicatorTintColor = .systemTeal
    appearance.currentPageIndicatorTintColor = .systemOrange
  }

  @IBAction func donePressed(_ sender: Any) {
    dismiss(animated: true)
  }

  public func nextPage() {
    guard changes == nil, let next = page(after: self.viewControllers?.first) else { return }
    setViewControllers([next], direction: .forward, animated: true, completion: nil)
  }

  public func previousPage() {
    guard changes == nil, let prev = page(before: self.viewControllers?.first) else { return }
    setViewControllers([prev], direction: .reverse, animated: true, completion: nil)
  }

  private static func loadPage(_ name: String) -> TutorialPageViewController {
    let storyboard = UIStoryboard(name: name, bundle: Bundle(for: TutorialViewController.self))
    guard
      let viewController = storyboard.instantiateInitialViewController()
        as? TutorialPageViewController
    else {
      fatalError("failed to load tutorial page \(name)")
    }
    return viewController
  }

  private func loadChanges(_ changes: [String]) -> ChangesPageViewController {
    let storyboard = UIStoryboard(name: "Changes", bundle: Bundle(for: TutorialViewController.self))
    guard
      let viewController = storyboard.instantiateInitialViewController()
        as? ChangesPageViewController
    else {
      fatalError("failed to load Changes page")
    }
    viewController.changes = changes
    return viewController
  }

}

extension TutorialContentPagerViewController: UIPageViewControllerDataSource {

  public func pageViewController(
    _ pageViewController: UIPageViewController,
    viewControllerBefore viewController: UIViewController
  ) -> UIViewController? {
    changes != nil ? nil : page(before: viewController)
  }

  public func pageViewController(
    _ pageViewController: UIPageViewController,
    viewControllerAfter viewController: UIViewController
  ) -> UIViewController? {
    changes != nil ? nil : page(after: viewController)
  }

  public func presentationCount(for pageViewController: UIPageViewController) -> Int {
    changes != nil ? 1 : pages.count
  }

  public func presentationIndex(for pageViewController: UIPageViewController) -> Int {
    guard let viewController = viewControllers?.first as? TutorialPageViewController else {
      return 0
    }
    return changes != nil ? 0 : pages.firstIndex(of: viewController)!
  }
}

extension TutorialContentPagerViewController {

  private func page(before viewController: UIViewController?) -> UIViewController? {
    guard let pageViewController = viewController as? TutorialPageViewController,
          let index = pages.firstIndex(of: pageViewController)
    else { return nil }
    return index == 0 ? nil : pages[index - 1]
  }

  private func page(after viewController: UIViewController?) -> UIViewController? {
    guard let pageViewController = viewController as? TutorialPageViewController,
          let index = pages.firstIndex(of: pageViewController)
    else { return nil }
    return index == pages.count - 1 ? nil : pages[index + 1]
  }
}

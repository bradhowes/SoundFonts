import UIKit

private func custom(_ name: String) -> TutorialPageViewController {
    let storyboard = UIStoryboard(name: name, bundle: Bundle(for: TutorialViewController.self))
    guard let viewController = storyboard.instantiateInitialViewController(),
          let page = viewController as? TutorialPageViewController else {
        fatalError("failed to load tutorial page \(name)")
    }
    return page
}

public final class TutorialContentPagerViewController: UIPageViewController, UIPageViewControllerDataSource,
                                                       UIPageViewControllerDelegate {

    private let pages: [TutorialPageViewController] = [
        custom("Intro"),
        custom("SoundFontList"),
        custom("TagsList"),
        custom("Presets"),
        custom("InfoBar1"),
        custom("InfoBar2"),
        custom("Favorites"),
        custom("Reverb"),
        custom("Delay"),
        custom("Settings"),
        custom("Done")
    ]

    override public func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        setViewControllers([pages[0]], direction: .forward, animated: true)

        let appearance = UIPageControl.appearance(whenContainedInInstancesOf: [UIPageViewController.self])
        appearance.pageIndicatorTintColor = .systemTeal
        appearance.currentPageIndicatorTintColor = .systemOrange
    }

    public func nextPage() {
        guard let next = page(after: self.viewControllers?.first) else { return }
        setViewControllers([next], direction: .forward, animated: true, completion: nil)
    }

    public func previousPage() {
        guard let prev = page(before: self.viewControllers?.first) else { return }
        setViewControllers([prev], direction: .reverse, animated: true, completion: nil)
    }

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerBefore viewController: UIViewController) -> UIViewController? {
        page(before: viewController)
    }

    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerAfter viewController: UIViewController) -> UIViewController? {
        page(after: viewController)
    }

    public func presentationCount(for pageViewController: UIPageViewController) -> Int {
        pages.count
    }

    public func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let viewController = viewControllers?.first as? TutorialPageViewController else { return 0 }
        return pages.firstIndex(of: viewController)!
    }

    @IBAction func donePressed(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension TutorialContentPagerViewController {

    private func page(before viewController: UIViewController?) -> UIViewController? {
        guard let pageViewController = viewController as? TutorialPageViewController,
              var index = pages.firstIndex(of: pageViewController) else { return nil }
        if index == 0 { return nil }
        index -= 1
        // if index < 0 { index = pages.count - 1 }
        return pages[index]
    }

    private func page(after viewController: UIViewController?) -> UIViewController? {
        guard let pageViewController = viewController as? TutorialPageViewController,
              var index = pages.firstIndex(of: pageViewController) else { return nil }
        if index == pages.count - 1 { return nil }
        index += 1
        // if index == pages.count { index = 0 }
        return pages[index]
    }
}

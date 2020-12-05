// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public final class GuideViewController: UIViewController {

    private var savedParent: UIViewController!
    private var infoBar: InfoBar!

    @IBOutlet weak var fontPresetPanel: UIView!
    @IBOutlet weak var infoBarPanel: UIView!
    @IBOutlet weak var favoritesPanel: UIView!

    public override func viewDidLoad() {
        super.viewDidLoad()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideGuide))
        view.addGestureRecognizer(tapGestureRecognizer)
        prepareGuide(for: Settings.instance.showingFavorites ? 1 : 0)
    }
}

extension GuideViewController: ControllerConfiguration {

    public func establishConnections(_ router: ComponentContainer) {
        infoBar = router.infoBar
        infoBar.addEventClosure(InfoBarEvent.showGuide, self.showGuide)
        savedParent = parent
        removeFromParent()
    }
}

extension GuideViewController: GuideManager {

    public func prepareGuide(for panel: Int) {
        switch panel {
        case 0:
            fontPresetPanel.isHidden = false
            favoritesPanel.isHidden = true
        case 1:
            fontPresetPanel.isHidden = true
            favoritesPanel.isHidden = false
        default:
            break
        }
    }
}

extension GuideViewController {

    private func showGuide(_ action: AnyObject) {
        savedParent.add(self)
        view.alpha = 0.0
        view.isHidden = false
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.4, delay: 0.0, options: .curveEaseIn) {
            self.view.alpha = 1.0
        }
    }

    @objc private func hideGuide() {
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.4, delay: 0.0, options: .curveEaseIn, animations: {
            self.view.alpha = 0.0
        },
        completion: { _ in
            self.view.isHidden = true
            self.removeFromParent()
            AskForReview.maybe()
        })
        infoBar.hideMoreButtons()
    }
}

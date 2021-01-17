// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public final class GuideViewController: UIViewController {

    private var savedParent: UIViewController!
    private var infoBar: InfoBar!

    @IBOutlet weak var fontPresetPanel: UIView!
    @IBOutlet weak var infoBarPanel: UIView!
    @IBOutlet weak var favoritesPanel: UIView!

    @IBOutlet weak var effectsLabel: UILabel!
    @IBOutlet weak var effectsArrow: ArrowView!
    @IBOutlet weak var keySlideLabel: UILabel!
    @IBOutlet weak var keyRangeLabel: UILabel!
    @IBOutlet weak var keyRangeArrow: ArrowView!

    private var isMainApp = true

    public override func viewDidLoad() {
        super.viewDidLoad()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideGuide))
        view.addGestureRecognizer(tapGestureRecognizer)
    }
}

extension GuideViewController: ControllerConfiguration {

    public func establishConnections(_ router: ComponentContainer) {
        infoBar = router.infoBar
        isMainApp = router.isMainApp
        infoBar.addEventClosure(InfoBarEvent.showGuide, self.showGuide)
        savedParent = parent
        removeFromParent()
    }
}

extension GuideViewController {

    private func prepareGuide() {
        let isAUv3 = !isMainApp
        effectsLabel.isHidden = isAUv3
        effectsArrow.isHidden = isAUv3
        keySlideLabel.isHidden = isAUv3
        keyRangeLabel.isHidden = isAUv3
        keyRangeArrow.isHidden = isAUv3
        if Settings.instance.showingFavorites {
            fontPresetPanel.isHidden = true
            favoritesPanel.isHidden = false
        }
        else {
            fontPresetPanel.isHidden = false
            favoritesPanel.isHidden = true
        }
    }
    private func showGuide(_ action: AnyObject) {
        prepareGuide()
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

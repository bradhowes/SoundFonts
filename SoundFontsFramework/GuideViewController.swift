// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public final class GuideViewController: UIViewController {
    @IBOutlet weak var fontsPanel: UIView!
    @IBOutlet weak var patchesPanel: UIView!
    @IBOutlet weak var favoritesPanel: UIView!

    private var savedParent: UIViewController!

    public override func viewDidLoad() {
        super.viewDidLoad()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideGuide))
        view.addGestureRecognizer(tapGestureRecognizer)
        prepareGuide(for: settings.showingFavorites ? 1 : 0)
    }
}

extension GuideViewController: ControllerConfiguration {

    public func establishConnections(_ router: ComponentContainer) {
        router.infoBar.addEventClosure(InfoBarEvent.showGuide, self.showGuide)
        savedParent = parent
        removeFromParent()
    }
}

extension GuideViewController: GuideManager {

    public func prepareGuide(for panel: Int) {
        switch panel {
        case 0:
            fontsPanel.isHidden = false
            patchesPanel.isHidden = false
            favoritesPanel.isHidden = true
        case 1:
            fontsPanel.isHidden = true
            patchesPanel.isHidden = true
            favoritesPanel.isHidden = false
        case 2:
            fontsPanel.isHidden = true
            patchesPanel.isHidden = true
            favoritesPanel.isHidden = true
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

        let animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeIn)
        animator.addAnimations { self.view.alpha = 1.0 }
        animator.startAnimation()
    }

    @objc private func hideGuide() {
        let animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeIn)
        animator.addAnimations { self.view.alpha = 0.0 }
        animator.addCompletion { _ in
            self.view.isHidden = true
            self.removeFromParent()
            AskForReview.maybe()
        }
        animator.startAnimation()
    }
}

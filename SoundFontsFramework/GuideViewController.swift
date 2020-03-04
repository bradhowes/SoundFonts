// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public final class GuideViewController: UIViewController, ControllerConfiguration, GuideManager {
    @IBOutlet weak var fontsPanel: UIView!
    @IBOutlet weak var patchesPanel: UIView!
    @IBOutlet weak var favoritesPanel: UIView!

    private var savedParent: UIViewController!

    public override func viewDidLoad() {
        super.viewDidLoad()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideGuide))
        view.addGestureRecognizer(tapGestureRecognizer)

        if Settings[.wasShowingFavorites] {
            favoritesGuide()
        }
        else {
            soundFontsGuide()
        }
    }

    public func establishConnections(_ router: ComponentContainer) {
        router.infoBar.addTarget(.showGuide, target: self, action: #selector(showGuide))
        savedParent = parent
        removeFromParent()
    }

    @objc public func showGuide() {
        savedParent.add(self)
        view.isHidden = false
    }

    @objc public func hideGuide() {
        removeFromParent()
        view.isHidden = true
        AskForReview.maybe()
    }

    public func soundFontsGuide() {
        fontsPanel.isHidden = false
        patchesPanel.isHidden = false
        favoritesPanel.isHidden = true
    }

    public func favoritesGuide() {
        fontsPanel.isHidden = true
        patchesPanel.isHidden = true
        favoritesPanel.isHidden = false
    }
}

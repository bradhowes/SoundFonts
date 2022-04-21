// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public final class GuideViewController: UIViewController {

  private var savedParent: UIViewController!
  private var infoBar: AnyInfoBar!
  private var settings: Settings!

  @IBOutlet private weak var fontPresetPanel: UIView!
  @IBOutlet private weak var infoBarPanel: UIView!
  @IBOutlet private weak var favoritesPanel: UIView!

  @IBOutlet private weak var effectsLabel: UILabel!
  @IBOutlet private weak var effectsArrow: ArrowView!
  @IBOutlet private weak var keySlideLabel: UILabel!
  @IBOutlet private weak var keyRangeLabel: UILabel!
  @IBOutlet private weak var keyRangeArrow: ArrowView!

  private var isMainApp = true

  public override func viewDidLoad() {
    super.viewDidLoad()
  }
}

extension GuideViewController: ControllerConfiguration {

  public func establishConnections(_ router: ComponentContainer) {
    settings = router.settings
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
    if settings.showingFavorites {
      fontPresetPanel.isHidden = true
      favoritesPanel.isHidden = false
    } else {
      fontPresetPanel.isHidden = false
      favoritesPanel.isHidden = true
    }
  }

  private func showGuide(_ sender: AnyObject) {
    prepareGuide()
    savedParent.add(self)
    view.alpha = 0.0
    view.isHidden = false
    UIViewPropertyAnimator.runningPropertyAnimator(
      withDuration: 0.4, delay: 0.0, options: .curveEaseIn
    ) {
      self.view.alpha = 1.0
    }

    let button = sender as? UIButton
    button?.tintColor = .systemOrange

    let gesture = BindableGestureRecognizer { gesture in
      button?.tintColor = .systemTeal
      UIViewPropertyAnimator.runningPropertyAnimator(
        withDuration: 0.4, delay: 0.0, options: .curveEaseOut,
        animations: {
          self.view.alpha = 0.0
        },
        completion: { _ in
          self.view.isHidden = true
          self.removeFromParent()
          AskForReview.maybe()
        })
      self.infoBar.hideMoreButtons()
      self.view.removeGestureRecognizer(gesture)
    }

    view.addGestureRecognizer(gesture)
  }
}

final class BindableGestureRecognizer: UITapGestureRecognizer {

  private var action: (BindableGestureRecognizer) -> Void

  init(action: @escaping (BindableGestureRecognizer) -> Void) {
    self.action = action
    super.init(target: nil, action: nil)
    self.addTarget(self, action: #selector(execute))
  }

  @objc private func execute() { action(self) }
}

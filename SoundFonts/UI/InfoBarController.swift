// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Manager of the strip informational strip between the keyboard and the SoundFont patches / favorites screens. Supports
 left/right swipes to switch the upper view, and two-finger left/right pan to adjust the keyboard range.
 */
final class InfoBarController : UIViewController, ControllerConfiguration, InfoBarManager {
    @IBOutlet private weak var status: UILabel!
    @IBOutlet private weak var patchInfo: UILabel!
    @IBOutlet private weak var lowestKey: UIButton!
    @IBOutlet private weak var highestKey: UIButton!

    private let doubleTap1 = UITapGestureRecognizer()
    private let doubleTap2 = UITapGestureRecognizer()

    override func viewDidLoad() {
        doubleTap1.numberOfTouchesRequired = 1
        doubleTap1.numberOfTapsRequired = 2
        patchInfo.addGestureRecognizer(doubleTap1)

        doubleTap2.numberOfTouchesRequired = 1
        doubleTap2.numberOfTapsRequired = 2
        status.addGestureRecognizer(doubleTap2)

        let panner = UIPanGestureRecognizer(target: self, action: #selector(panKeyboard))
        panner.minimumNumberOfTouches = 1
        panner.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panner)
    }

    func establishConnections(_ context: RunContext) {
    }

    /**
     Add an event target to one of the internal UIControl entities.
    
     - parameter event: the event to target
     - parameter target: the instance to notify when the event fires
     - parameter action: the method to call when the event fires
     */
    func addTarget(_ event: InfoBarEvent, target: Any, action: Selector) {
        switch event {
        case .shiftKeyboardUp: highestKey.addTarget(target, action: action, for: .touchUpInside)
        case .shiftKeyboardDown: lowestKey.addTarget(target, action: action, for: .touchUpInside)
        case .doubleTap:
            doubleTap1.addTarget(target, action: action)
            doubleTap2.addTarget(target, action: action)
        }
    }

    /**
     Set the text to temporarily show in the center of the info bar.

     - parameter value: the text to display
     */
    func setStatus(_ value: String) {
        status.text = value
        startStatusAnimation()
    }

    /**
     Set the Patch info to show in the display.
    
     - parameter name: the name of the Patch to show
     - parameter isFavored: true if the Patch is a Favorite
     */
    func setPatchInfo(name: String, isFavored: Bool) {
        let name = PatchCell.favoriteTag(isFavored) + name
        patchInfo.text = name
        cancelStatusAnimation()
    }

    /**
     Set the range of keys to show in the bar
    
     - parameter from: the first key label
     - parameter to: the last key label
     */
    func setVisibleKeyLabels(from: String, to: String) {
        UIView.performWithoutAnimation {
            lowestKey.setTitle("⋘ " + from, for: .normal)
            lowestKey.layoutIfNeeded()
            highestKey.setTitle(to + " ⋙", for: .normal)
            highestKey.layoutIfNeeded()
        }
    }

    private var fader: UIViewPropertyAnimator? = nil

    private func startStatusAnimation() {

        cancelStatusAnimation()

        status.isHidden = false
        status.alpha = 1.0
        patchInfo.alpha = 0.0

        self.fader = UIViewPropertyAnimator(duration: 0.25, curve: .linear) {
            self.status.alpha = 0.0
            self.patchInfo.alpha = 1.0
        }

        self.fader?.addCompletion { _ in
            self.status.isHidden = true
            self.fader = nil
        }

        self.fader?.startAnimation(afterDelay: 1.0)
    }

    private func cancelStatusAnimation() {
        if let fader = self.fader {
            fader.stopAnimation(true)
            self.fader = nil
        }
    }

    private var panOrigin: CGPoint = CGPoint.zero
    
    @IBAction private func panKeyboard(_ panner: UIPanGestureRecognizer) {
        if panner.state == .began {
            panOrigin = panner.translation(in: view)
        }
        else {
            let point = panner.translation(in: view)
            let change = Int((point.x - panOrigin.x) / 40.0)
            if change < 0 {
                for _ in change..<0 {
                    highestKey.sendActions(for: .touchUpInside)
                }
                panOrigin = point
            }
            else if change > 0 {
                for _ in 0..<change {
                    lowestKey.sendActions(for: .touchUpInside)
                }
                panOrigin = point
            }
        }
    }
}

// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Manager of the strip informational strip between the keyboard and the SoundFont patches / favorites screens. Supports
 left/right swipes to switch the upper view, and two-finger left/right pan to adjust the keyboard range.
 */
public final class InfoBarController: UIViewController, ControllerConfiguration, InfoBar {
    @IBOutlet private weak var status: UILabel!
    @IBOutlet private weak var patchInfo: UILabel!
    @IBOutlet private weak var lowestKey: UIButton!
    @IBOutlet private weak var addSoundFont: UIButton!
    @IBOutlet private weak var highestKey: UIButton!
    @IBOutlet private weak var touchView: UIView!
    @IBOutlet private weak var showGuide: UIButton!

    private let doubleTap = UITapGestureRecognizer()
    private var panOrigin: CGPoint = CGPoint.zero
    private var fader: UIViewPropertyAnimator?
    private var activePatchManager: ActivePatchManager!

    public override func viewDidLoad() {

        highestKey.isHidden = true
        lowestKey.isHidden = true

        doubleTap.numberOfTouchesRequired = 1
        doubleTap.numberOfTapsRequired = 2
        touchView.addGestureRecognizer(doubleTap)

        let panner = UIPanGestureRecognizer(target: self, action: #selector(panKeyboard))
        panner.minimumNumberOfTouches = 1
        panner.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panner)
    }

    public func establishConnections(_ router: ComponentContainer) {
        activePatchManager = router.activePatchManager
        activePatchManager.subscribe(self, notifier: activePatchChange)
        router.favorites.subscribe(self, notifier: favoritesChange)
        useActivePatchKind(activePatchManager.active)
    }

    /**
     Add an event target to one of the internal UIControl entities.
    
     - parameter event: the event to target
     - parameter target: the instance to notify when the event fires
     - parameter action: the method to call when the event fires
     */
    public func addTarget(_ event: InfoBarEvent, target: Any, action: Selector) {
        switch event {
        case .shiftKeyboardUp:
            highestKey.addTarget(target, action: action, for: .touchUpInside)
            highestKey.isHidden = false

        case .shiftKeyboardDown:
            lowestKey.addTarget(target, action: action, for: .touchUpInside)
            lowestKey.isHidden = false

        case .doubleTap: doubleTap.addTarget(target, action: action)
        case .addSoundFont: addSoundFont.addTarget(target, action: action, for: .touchUpInside)
        case .showGuide: showGuide.addTarget(target, action: action, for: .touchUpInside)
        }
    }

    /**
     Set the text to temporarily show in the center of the info bar.

     - parameter value: the text to display
     */
    public func setStatus(_ value: String) {
        status.text = value
        startStatusAnimation()
    }

    /**
     Set the Patch info to show in the display.
    
     - parameter name: the name of the Patch to show
     - parameter isFavored: true if the Patch is a Favorite
     */
    public func setPatchInfo(name: String, isFavored: Bool) {
        let name = PatchCell.favoriteTag(isFavored) + name
        patchInfo.text = name
        cancelStatusAnimation()
    }

    /**
     Set the range of keys to show in the bar
    
     - parameter from: the first key label
     - parameter to: the last key label
     */
    public func setVisibleKeyLabels(from: String, to: String) {
        UIView.performWithoutAnimation {
            lowestKey.setTitle("❰" + from, for: .normal)
            lowestKey.accessibilityLabel = "Keyboard down before " + from
            lowestKey.layoutIfNeeded()
            highestKey.setTitle(to + "❱", for: .normal)
            highestKey.accessibilityLabel = "Keyboard up after " + to
            highestKey.layoutIfNeeded()
        }
    }
}

// MARK: - Private

extension InfoBarController {

    private func activePatchChange(_ event: ActivePatchEvent) {
        if case let .active(old: _, new: new) = event {
            useActivePatchKind(new)
        }
    }

    private func favoritesChange(_ event: FavoritesEvent) {
        switch event {
        case let .added(index: _, favorite: favorite): updateInfoBar(with: favorite)
        case let .changed(index: _, favorite: favorite): updateInfoBar(with: favorite)
        case let .removed(index: _, favorite: favorite, bySwiping: _): updateInfoBar(with: favorite.soundFontPatch)
        default: break
        }
    }

    private func updateInfoBar(with favorite: Favorite) {
        if favorite.soundFontPatch == activePatchManager.soundFontPatch {
            setPatchInfo(name: favorite.name, isFavored: true)
        }
    }

    private func updateInfoBar(with soundFontPatch: SoundFontPatch) {
        if soundFontPatch == activePatchManager.soundFontPatch {
            setPatchInfo(name: soundFontPatch.patch.name, isFavored: false)
        }
    }

    private func useActivePatchKind(_ activePatchKind: ActivePatchKind) {

        if let favorite = activePatchKind.favorite {
            setPatchInfo(name: favorite.name, isFavored: true)
        }
        else {
            setPatchInfo(name: activePatchKind.soundFontPatch.patch.name, isFavored: false)
        }
    }

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

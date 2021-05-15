// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Manager of the strip informational strip between the keyboard and the SoundFont patches / favorites screens. Supports
 left/right swipes to switch the upper view, and two-finger left/right pan to adjust the keyboard range.
 */
public final class InfoBarController: UIViewController {
    private let log = Logging.logger("InfoBar")

    @IBOutlet private weak var status: UILabel!
    @IBOutlet private weak var patchInfo: UILabel!
    @IBOutlet private weak var lowestKey: UIButton!
    @IBOutlet private weak var addSoundFont: UIButton!
    @IBOutlet private weak var highestKey: UIButton!
    @IBOutlet private weak var touchView: UIView!
    @IBOutlet private weak var showGuide: UIButton!
    @IBOutlet private weak var showSettings: UIButton!
    @IBOutlet private weak var editVisibility: UIButton!
    @IBOutlet private weak var slidingKeyboard: UIButton!
    @IBOutlet private weak var showTags: UIButton!
    @IBOutlet private weak var showEffects: UIButton!

    @IBOutlet private weak var showMoreButtonsButton: UIButton!
    @IBOutlet private weak var moreButtons: UIView!
    @IBOutlet private weak var moreButtonsXConstraint: NSLayoutConstraint!

    private let doubleTap = UITapGestureRecognizer()

    private var panOrigin: CGPoint = CGPoint.zero
    private var fader: UIViewPropertyAnimator?
    private var activePatchManager: ActivePatchManager!
    private var soundFonts: SoundFonts!
    private var isMainApp: Bool!

    private var observers = [NSKeyValueObservation]()

    private var lowestKeyValue = ""
    private var highestKeyValue = ""
    private var showingMoreButtons = false

    public override func viewDidLoad() {

        highestKey.isHidden = true
        lowestKey.isHidden = true
        slidingKeyboard.isHidden = true

        doubleTap.numberOfTouchesRequired = 1
        doubleTap.numberOfTapsRequired = 2
        touchView.addGestureRecognizer(doubleTap)

        let panner = UIPanGestureRecognizer(target: self, action: #selector(panKeyboard))
        panner.minimumNumberOfTouches = 1
        panner.maximumNumberOfTouches = 1
        touchView.addGestureRecognizer(panner)

        observers.append(
            Settings.shared.observe(\.slideKeyboard, options: [.new]) { [weak self] _, _ in
                self?.updateSlidingKeyboardState()
            }
        )

        updateSlidingKeyboardState()
        showEffects.tintColor = Settings.instance.showEffects ? .systemOrange : .systemTeal
    }

    public override func willTransition(to newCollection: UITraitCollection,
                                        with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        let showingMoreButtons = self.showingMoreButtons
        coordinator.animate(alongsideTransition: { _ in
            if showingMoreButtons {
                self.hideMoreButtons()
            }
        }, completion: { _ in
            if showingMoreButtons {
                self.hideMoreButtons()
            }
        })
    }
}

extension InfoBarController {

    @IBAction
    func toggleMoreButtons(_ sender: UIButton) {
        setMoreButtonsVisible(state: !showingMoreButtons)
    }

    @IBAction private func showSettings(_ sender: UIButton) {
        setMoreButtonsVisible(state: false)
    }

    @IBAction private func showGuide(_ sender: UIButton) {
        guard traitCollection.horizontalSizeClass == .compact else { return }
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.4,
            delay: 0.0,
            options: [.curveEaseOut],
            animations: {
                self.moreButtonsXConstraint.constant = -40
            },
            completion: { _ in
                self.moreButtonsXConstraint.constant = -40
            }
        )
    }

    @IBAction private func toggleSlideKeyboard(_ sender: UIButton) {
        Settings.shared.slideKeyboard = !Settings.shared.slideKeyboard
    }
}

extension InfoBarController: ControllerConfiguration {

    public func establishConnections(_ router: ComponentContainer) {
        activePatchManager = router.activePatchManager
        activePatchManager.subscribe(self, notifier: activePatchChange)
        soundFonts = router.soundFonts
        isMainApp = router.isMainApp
        router.favorites.subscribe(self, notifier: favoritesChange)
        useActivePatchKind(activePatchManager.active)
        showEffects.isEnabled = router.isMainApp
        showEffects.isHidden = !router.isMainApp
    }
}

extension InfoBarController: InfoBar {

    public func setEditVisibilityButtonEnabled(_ state: Bool) {
        editVisibility.isEnabled = state
    }

    public var moreButtonsVisible: Bool { showingMoreButtons }

    /**
     Add an event target to one of the internal UIControl entities.

     - parameter event: the event to target
     - parameter target: the instance to notify when the event fires
     - parameter action: the method to call when the event fires
     */
    public func addEventClosure(_ event: InfoBarEvent, _ closure: @escaping UIControl.Closure) {
        switch event {
        case .shiftKeyboardUp:
            highestKey.addClosure(closure)
            highestKey.isHidden = false
            slidingKeyboard.isHidden = false

        case .shiftKeyboardDown:
            lowestKey.addClosure(closure)
            lowestKey.isHidden = false
            slidingKeyboard.isHidden = false

        case .doubleTap: doubleTap.addClosure(closure)
        case .addSoundFont: addSoundFont.addClosure(closure)
        case .showGuide: showGuide.addClosure(closure)
        case .showSettings: showSettings.addClosure(closure)
        case .editVisibility: editVisibility.addClosure(closure)
        case .showEffects: showEffects.addClosure(closure)
        case .showTags: showTags.addClosure(closure)
        }
    }

    public func resetButtonState(_ event: InfoBarEvent) {
        let button: UIButton? = {
            switch event {
            case .addSoundFont: return addSoundFont
            case .showGuide: return showGuide
            case .showSettings: return showSettings
            case .editVisibility: return editVisibility
            case .showEffects: return showEffects
            case .showTags: return showTags
            case .shiftKeyboardUp: return nil
            case .shiftKeyboardDown: return nil
            case .doubleTap: return nil
            }
        }()
        button?.tintColor = .systemTeal
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
     Set the range of keys to show in the bar

     - parameter from: the first key label
     - parameter to: the last key label
     */
    public func setVisibleKeyLabels(from: String, to: String) {
        lowestKeyValue = from
        highestKeyValue = to
        updateKeyLabels()
    }

    public func showMoreButtons() {
        setMoreButtonsVisible(state: true)
    }

    public func hideMoreButtons() {
        setMoreButtonsVisible(state: false)
    }
}

// MARK: - Private

extension InfoBarController: SegueHandler {

    public enum SegueIdentifier: String {
        case settings
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if case .settings = segueIdentifier(for: segue) {
            beginSettingsView(segue, sender: sender)
        }
    }

    private func beginSettingsView(_ segue: UIStoryboardSegue, sender: Any?) {
        guard let navController = segue.destination as? UINavigationController,
              let viewController = navController.topViewController as? SettingsViewController else { return }

        viewController.soundFonts = soundFonts
        viewController.isMainApp = isMainApp

        if !isMainApp {
            viewController.modalPresentationStyle = .fullScreen
            navController.modalPresentationStyle = .fullScreen
        }

        if let ppc = navController.popoverPresentationController {
            ppc.sourceView = showSettings
            ppc.sourceRect = showSettings.bounds
            ppc.permittedArrowDirections = .any
        }
    }
}

extension InfoBarController {

    private func setMoreButtonsVisible(state: Bool) {
        guard state != showingMoreButtons else { return }
        guard traitCollection.horizontalSizeClass == .compact else { return }

        let willBeHidden = !state
        showingMoreButtons = state
        moreButtonsXConstraint.constant = willBeHidden ? 0 : -moreButtons.frame.width

        view.layoutIfNeeded()

        let newImage = UIImage(named: willBeHidden ? "More Right" : "More Right Filled", in: Bundle(for: Self.self),
                               compatibleWith: .none)
        let newConstraint = willBeHidden ? -moreButtons.frame.width : 0
        let newAlpha: CGFloat = willBeHidden ? 1.0 : 0.5

        moreButtons.isHidden = false
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.4,
            delay: 0.0,
            options: [willBeHidden ? .curveEaseOut : .curveEaseIn],
            animations: {
                self.moreButtonsXConstraint.constant = newConstraint
                self.touchView.alpha = newAlpha
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                self.moreButtons.isHidden = willBeHidden
                self.touchView.alpha = newAlpha
            }
        )

        UIView.transition(with: showMoreButtonsButton, duration: 0.4, options: .transitionCrossDissolve) {
            self.showMoreButtonsButton.setImage(newImage, for: .normal)
        }
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        if case let .active(old: _, new: new, playSample: _) = event {
            useActivePatchKind(new)
        }
    }

    private func favoritesChange(_ event: FavoritesEvent) {
        switch event {
        case let .added(index: _, favorite: favorite): updateInfoBar(with: favorite)
        case let .changed(index: _, favorite: favorite): updateInfoBar(with: favorite)
        case let .removed(index: _, favorite: favorite): updateInfoBar(with: favorite.soundFontAndPatch)
        case .selected: break
        case .beginEdit: break
        case .removedAll: break
        case .restored: break
        }
    }

    private func updateInfoBar(with favorite: LegacyFavorite) {
        if favorite.soundFontAndPatch == activePatchManager.soundFontAndPatch {
            setPatchInfo(name: favorite.presetConfig.name, isFavored: true)
        }
    }

    private func updateInfoBar(with soundFontAndPatch: SoundFontAndPatch) {
        if soundFontAndPatch == activePatchManager.soundFontAndPatch {
            if let patch = activePatchManager.resolveToPatch(soundFontAndPatch) {
                setPatchInfo(name: patch.presetConfig.name, isFavored: false)
            }
        }
    }

    private func useActivePatchKind(_ activePatchKind: ActivePatchKind) {
        if let favorite = activePatchKind.favorite {
            setPatchInfo(name: favorite.presetConfig.name, isFavored: true)
        }
        else if let soundFontAndPatch = activePatchKind.soundFontAndPatch {
            if let patch = activePatchManager.resolveToPatch(soundFontAndPatch) {
                setPatchInfo(name: patch.presetConfig.name, isFavored: false)
            }
        }
        else {
            setPatchInfo(name: "-", isFavored: false)
        }
    }

    private func setPatchInfo(name: String, isFavored: Bool) {
        os_log(.info, log: log, "setPatchInfo: %{public}s %d", name, isFavored)
        patchInfo.text = TableCell.favoriteTag(isFavored) + name
        cancelStatusAnimation()
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

    @objc private func panKeyboard(_ panner: UIPanGestureRecognizer) {
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

    private func updateKeyLabels() {
        UIView.performWithoutAnimation {
            lowestKey.setTitle("❰" + lowestKeyValue, for: .normal)
            lowestKey.accessibilityLabel = "Keyboard down before " + lowestKeyValue
            lowestKey.layoutIfNeeded()
            highestKey.setTitle(highestKeyValue + "❱", for: .normal)
            highestKey.accessibilityLabel = "Keyboard up after " + highestKeyValue
            highestKey.layoutIfNeeded()
        }
    }

    private func updateSlidingKeyboardState() {
        slidingKeyboard.setTitleColor(Settings.shared.slideKeyboard ? .systemTeal : .darkGray, for: .normal)
    }
}

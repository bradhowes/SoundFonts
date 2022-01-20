// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/// Manager of the strip informational strip between the keyboard and the SoundFont presets / favorites screens. Supports
/// left/right swipes to switch the upper view, and two-finger left/right pan to adjust the keyboard range.
public final class InfoBarController: UIViewController, Tasking {
  private lazy var log = Logging.logger("InfoBarController")

  @IBOutlet private weak var status: UILabel!
  @IBOutlet private weak var presetInfo: UILabel!
  @IBOutlet private weak var lowestKey: UIButton!
  @IBOutlet private weak var addSoundFont: UIButton!
  @IBOutlet private weak var highestKey: UIButton!
  @IBOutlet private weak var touchView: UIView!
  @IBOutlet private weak var showGuide: UIButton!
  @IBOutlet private weak var showSettings: UIButton!
  @IBOutlet private weak var editVisibility: UIButton!
  @IBOutlet private weak var slidingKeyboardToggle: UIButton!
  @IBOutlet private weak var showTags: UIButton!
  @IBOutlet private weak var showEffects: UIButton!

  @IBOutlet private weak var tuningIndicator: UILabel!
  @IBOutlet private weak var panIndicator: UILabel!
  @IBOutlet private weak var gainIndicator: UILabel!

  @IBOutlet private weak var showMoreButtonsButton: UIButton!
  @IBOutlet private weak var moreButtons: UIView!
  @IBOutlet private weak var moreButtonsXConstraint: NSLayoutConstraint!

  private let doubleTap = UITapGestureRecognizer()

  private var panOrigin: CGPoint = CGPoint.zero
  private var fader: UIViewPropertyAnimator?
  private var activePresetManager: ActivePresetManager!
  private var soundFonts: SoundFonts!
  private var isMainApp: Bool!
  private var settings: Settings!

  private var observers = [NSKeyValueObservation]()

  private var lowestKeyValue = ""
  private var highestKeyValue = ""
  private var showingMoreButtons = false
  private var tuningChangedNotifier: NotificationObserver?
  private var presetConfigChangedNotifier: NotificationObserver?

  public override func viewDidLoad() {
    super .viewDidLoad()

    // Hide until we know for sure that they should be visible
    highestKey.isHidden = true
    lowestKey.isHidden = true
    slidingKeyboardToggle.isHidden = true

    doubleTap.numberOfTouchesRequired = 1
    doubleTap.numberOfTapsRequired = 2
    touchView.addGestureRecognizer(doubleTap)

    let panner = UIPanGestureRecognizer(target: self, action: #selector(panKeyboard))
    panner.minimumNumberOfTouches = 1
    panner.maximumNumberOfTouches = 1
    touchView.addGestureRecognizer(panner)

    tuningChangedNotifier = Sampler.tuningChangedNotification.registerOnAny(block: updateTuningIndicator(_:))
    presetConfigChangedNotifier = PresetConfig.changedNotification.registerOnAny(block: updateIndicators(_:))
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    showEffects.tintColor = settings.showEffects ? .systemOrange : .systemTeal

    // NOTE: begin observing *after* first accessing setting value.
    updateSlidingKeyboardState()
    observers.append(
      settings.observe(\.slideKeyboard, options: [.new]) { [weak self] _, _ in
        self?.updateSlidingKeyboardState()
      }
    )
  }

  /**
   Detect changes in orientation and adjust button layouts

   - parameter newCollection: the new size traits
   - parameter coordinator: the animation coordinator
   */
  public override func willTransition(to newCollection: UITraitCollection,
                                      with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    coordinator.animate(
      alongsideTransition: { _ in
        self.hideMoreButtons()
      },
      completion: { _ in
        self.hideMoreButtons()
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

  @IBAction private func toggleSlideKeyboard(_ sender: UIButton) { settings.slideKeyboard = !settings.slideKeyboard }
}

extension InfoBarController: ControllerConfiguration {

  public func establishConnections(_ router: ComponentContainer) {
    settings = router.settings
    activePresetManager = router.activePresetManager
    soundFonts = router.soundFonts
    isMainApp = router.isMainApp
    showActivePreset()
    showEffects.isEnabled = router.isMainApp
    showEffects.isHidden = !router.isMainApp

    activePresetManager.subscribe(self, notifier: activePresetChanged_BT)
    router.favorites.subscribe(self, notifier: favoritesChanged_BT)
  }
}

extension InfoBarController: InfoBar {

  public func updateButtonsForPresetsViewState(visible: Bool) {
    editVisibility.isEnabled = visible
    showTags.isEnabled = visible
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
    case .shiftKeyboardUp: addShiftKeyboardUpClosure(closure)
    case .shiftKeyboardDown: addShiftKeyboardDownClosure(closure)
    case .doubleTap: doubleTap.addClosure(closure)
    case .addSoundFont: addSoundFont.addClosure(closure)
    case .showGuide: showGuide.addClosure(closure)
    case .showSettings: showSettings.addClosure(closure)
    case .editVisibility: editVisibility.addClosure(closure)
    case .showEffects: showEffects.addClosure(closure)
    case .showTags: showTags.addClosure(closure)
    case .showMoreButtons: addShowMoreButtonsClosure(closure)
    case .hideMoreButtons: addHideMoreButtonsClosure(closure)
    }
  }

  private func addShiftKeyboardUpClosure(_ closure: @escaping UIControl.Closure) {
    highestKey.addClosure(closure)
    highestKey.isHidden = false
    slidingKeyboardToggle.isHidden = false
  }

  private func addShiftKeyboardDownClosure(_ closure: @escaping UIControl.Closure) {
    lowestKey.addClosure(closure)
    lowestKey.isHidden = false
    slidingKeyboardToggle.isHidden = false
  }

  private func addShowMoreButtonsClosure(_ closure: @escaping UIControl.Closure) {
    showMoreButtonsButton.addClosure { [weak self] button in
      guard let self = self, self.showingMoreButtons else { return }
      closure(button)
    }
  }

  private func addHideMoreButtonsClosure(_ closure: @escaping UIControl.Closure) {
    showMoreButtonsButton.addClosure { [weak self] button in
      guard let self = self, !self.showingMoreButtons else { return }
      closure(button)
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
      default: return nil
      }
    }()
    button?.tintColor = .systemTeal
  }

  /**
   Set the text to temporarily show in the center of the info bar.

   - parameter value: the text to display
   */
  public func setStatusText(_ value: String) {
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

  public func updateIndicators(_ presetConfig: PresetConfig) {
    updateTuningIndicator(presetConfig.presetTuning)
    updateGainIndicator(presetConfig.gain)
    updatePanIndicator(presetConfig.pan)
  }

  public func updateTuningIndicator() {
    updateTuningIndicator(activePresetManager.activePresetConfig?.presetTuning ?? 0.0)
  }

  public func updatePanIndicator() {
    updatePanIndicator(activePresetManager.activePresetConfig?.pan ?? 0.0)
  }

  public func updateGainIndicator() {
    updateGainIndicator(activePresetManager.activePresetConfig?.gain ?? 0.0)
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
          let viewController = navController.topViewController as? SettingsViewController
    else { return }

    viewController.soundFonts = soundFonts
    viewController.isMainApp = isMainApp
    viewController.settings = settings
    viewController.infoBar = self

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

    let newImage = UIImage(
      named: willBeHidden ? "More Right" : "More Right Filled", in: Bundle(for: Self.self),
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

    UIView.transition(with: showMoreButtonsButton, duration: 0.4, options: .transitionCrossDissolve)
    {
      self.showMoreButtonsButton.setImage(newImage, for: .normal)
    }
  }

  private func soundFontsChanged_BT(_ event: SoundFontsEvent) {
    if case .restored = event {
      Self.onMain { self.showActivePreset() }
    }
  }

  private func activePresetChanged_BT(_ event: ActivePresetEvent) {
    if case .change = event {
      Self.onMain { self.showActivePreset() }
    }
  }

  private func favoritesChanged_BT(_ event: FavoritesEvent) {
    Self.onMain { self.showActivePreset() }
  }

  private func showActivePreset() {
    let activePresetKind = activePresetManager.active
    os_log(.debug, log: log, "useActivePresetKind BEGIN - %{public}s", activePresetKind.description)
    if activePresetKind.favoriteKey != nil,
       let presetConfig = activePresetManager.activePresetConfig {
      setPresetInfo(presetConfig: presetConfig, isFavored: true)
    } else if let soundFontAndPreset = activePresetKind.soundFontAndPreset,
              let preset = activePresetManager.resolveToPreset(soundFontAndPreset) {
      setPresetInfo(presetConfig: preset.presetConfig, isFavored: false)
    } else {
      setPresetInfo(presetConfig: .init(name: "-"), isFavored: false)
    }
  }

  private func setPresetInfo(presetConfig: PresetConfig, isFavored: Bool) {
    os_log(.debug, log: log, "setPresetInfo: %{public}s %d %f", presetConfig.name, isFavored)
    presetInfo.text = TableCell.favoriteTag(isFavored) + presetConfig.name
    updateTuningIndicator(presetConfig.presetTuning)
    updatePanIndicator(presetConfig.pan)
    updateGainIndicator(presetConfig.gain)
    cancelStatusAnimation()
  }

  private func updateTuningIndicator(_ presetTuning: Float) {
    os_log(.debug, log: log, "updateTuningIndicator BEGIN - %f", presetTuning)
    tuningIndicator.isHidden = presetTuning == 0.0 && settings.globalTuning == 0.0
    os_log(.debug, log: log, "updateTuningIndicator END")
  }

  private func updatePanIndicator(_ presetPan: Float) {
    panIndicator.isHidden = presetPan == 0.0
  }

  private func updateGainIndicator(_ presetGain: Float) {
    gainIndicator.isHidden = presetGain == 0.0
  }

  private func startStatusAnimation() {
    cancelStatusAnimation()

    status.isHidden = false
    status.alpha = 1.0
    presetInfo.alpha = 0.0

    self.fader = UIViewPropertyAnimator(duration: 0.25, curve: .linear) {
      self.status.alpha = 0.0
      self.presetInfo.alpha = 1.0
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
    } else {
      let point = panner.translation(in: view)
      let change = Int((point.x - panOrigin.x) / 40.0)
      if change < 0 {
        for _ in change..<0 {
          highestKey.sendActions(for: .touchUpInside)
        }
        panOrigin = point
      } else if change > 0 {
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
    slidingKeyboardToggle.setTitleColor(settings.slideKeyboard ? .systemTeal : .darkGray, for: .normal)
  }
}

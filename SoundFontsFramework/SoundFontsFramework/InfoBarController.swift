// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os
import MorkAndMIDI

/// Manager of the strip informational strip between the keyboard and the SoundFont presets / favorites screens. Supports
/// left/right swipes to switch the upper view, and two-finger left/right pan to adjust the keyboard range.
final class InfoBarController: UIViewController {
  private lazy var log: Logger = Logging.logger("InfoBarController")

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

  @IBOutlet private weak var midiIndicator: UIView!

  private let doubleTap = UITapGestureRecognizer()
  private let addButtonLongPressGesture = UILongPressGestureRecognizer()
  private let effectsButtonLongPressGesture = UILongPressGestureRecognizer()
  private let presetViewLongPressGesture = UILongPressGestureRecognizer()

  private var panOrigin: CGPoint = CGPoint.zero
  private var fader: UIViewPropertyAnimator?
  private var activePresetManager: ActivePresetManager!
  private var soundFonts: SoundFontsProvider!
  private var isMainApp: Bool!
  private var settings: Settings!
  private var audioEngine: AudioEngine?
  private var midi: MIDI?
  private var midiConnectionMonitor: MIDIConnectionMonitor?

  private var observers = [NSKeyValueObservation]()

  private var lowestKeyValue = ""
  private var highestKeyValue = ""
  private var showingMoreButtons = false
  private var tuningChangedNotifier: NotificationObserver?
  private var presetConfigChangedNotifier: NotificationObserver?
  private var midiIndicatorAnimator: MIDIIndicatorPulseAnimation?
  private var monitorToken: NotificationObserver?
}

extension InfoBarController {

  public override func viewDidLoad() {
    super .viewDidLoad()

    // Hide until we know for sure that they should be visible
    highestKey.isHidden = true
    lowestKey.isHidden = true
    slidingKeyboardToggle.isHidden = true

    doubleTap.numberOfTouchesRequired = 1
    doubleTap.numberOfTapsRequired = 2
    touchView.addGestureRecognizer(doubleTap)

    presetViewLongPressGesture.minimumPressDuration = 0.5
    touchView.addGestureRecognizer(presetViewLongPressGesture)

    effectsButtonLongPressGesture.minimumPressDuration = 0.5
    showEffects.addGestureRecognizer(effectsButtonLongPressGesture)

    let panner = UIPanGestureRecognizer(target: self, action: #selector(panKeyboard))
    panner.minimumNumberOfTouches = 1
    panner.maximumNumberOfTouches = 1
    touchView.addGestureRecognizer(panner)

    tuningChangedNotifier = AudioEngine.tuningChangedNotification.registerOnAny(block: updateTuningIndicator(_:))
    presetConfigChangedNotifier = PresetConfig.changedNotification.registerOnAny(block: updateIndicators(_:))

    addButtonLongPressGesture.minimumPressDuration = 0.5
    addSoundFont.addGestureRecognizer(addButtonLongPressGesture)

    let animator = MIDIIndicatorPulseAnimation()
    midiIndicatorAnimator = animator
    midiIndicator.layer.insertSublayer(animator, below: midiIndicator.layer)
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    monitorToken = midiConnectionMonitor?.addConnectionActivityMonitor { payload in
      let accepted = self.settings.midiChannel == -1 || self.settings.midiChannel == payload.channel
      self.updateMIDIIndicator(accepted: accepted)
    }

    showEffects.tintColor = settings.showEffects ? .systemOrange : .systemTeal

    // NOTE: begin observing *after* first accessing setting value.
    updateSlidingKeyboardState()
    observers.append(
      settings.observe(\.slideKeyboard, options: [.new]) { [weak self] _, _ in
        self?.updateSlidingKeyboardState()
      }
    )
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard let animator = midiIndicatorAnimator else { return }
    animator.bounds = midiIndicator.layer.bounds
    animator.position = CGPoint(x: midiIndicator.bounds.midX, y: midiIndicator.bounds.midY)
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

  func resetButtonState(_ event: InfoBarEvent) {
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
  func setStatusText(_ value: String) {
    status.text = value
    startStatusAnimation()
  }

  /**
   Set the range of keys to show in the bar

   - parameter from: the first key label
   - parameter to: the last key label
   */
  func setVisibleKeyLabels(from: String, to: String) {
    lowestKeyValue = from
    highestKeyValue = to
    updateKeyLabels()
  }

  func showMoreButtons() {
    setMoreButtonsVisible(state: true)
  }

  func hideMoreButtons() {
    setMoreButtonsVisible(state: false)
  }

  func updateTuningIndicator() {
    updateTuningIndicator(activePresetManager.activePresetConfig?.presetTuning ?? 0.0)
  }
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

    activePresetManager.subscribe(self, notifier: activePresetChangedNotificationInBackground)
    router.favorites.subscribe(self, notifier: favoritesChangedNotificationInBackground)

    router.subscribe(self, notifier: routerChangedNotificationInBackground)

    if let audioEngine = router.audioEngine {
      self.audioEngine = audioEngine
      self.midi = audioEngine.midi
      midiConnectionMonitor = audioEngine.midiConnectionMonitor
    }
  }
}

extension InfoBarController: AnyInfoBar {

  public func updateButtonsForPresetsViewState(visible: Bool) {
    editVisibility.isEnabled = visible
    showTags.isEnabled = visible
  }

  public var moreButtonsVisible: Bool { showingMoreButtons }

  // swiftlint:disable cyclomatic_complexity
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
    case .doubleTap: addDoubleTapClosure(closure)
    case .addSoundFont: addSoundFontClosure(closure)
    case .editSoundFonts: addButtonLongPressGestureClosure(closure)
    case .showGuide: addShowGuideClosure(closure)
    case .showSettings: addShowSettingsClosure(closure)
    case .editVisibility: addEditVisibilityClosure(closure)
    case .showEffects: addShowEffectsClosure(closure)
    case .showTags: addShowTagsClosure(closure)
    case .showMoreButtons: addShowMoreButtonsClosure(closure)
    case .hideMoreButtons: addHideMoreButtonsClosure(closure)
    case .panic: doPanic(closure)
    }
  }
  // swiftlint:enable cyclomatic_complexity
}

extension InfoBarController: SegueHandler {

  enum SegueIdentifier: String {
    case settings
  }

  public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if case .settings = segueIdentifier(for: segue) {
      beginSettingsView(segue, sender: sender)
    }
  }
}

// MARK: - Private

private extension InfoBarController {

  func updateIndicators(_ presetConfig: PresetConfig) {
    updateTuningIndicator(presetConfig.presetTuning)
    updateGainIndicator(presetConfig.gain)
    updatePanIndicator(presetConfig.pan)
  }

  func updatePanIndicator() { updatePanIndicator(activePresetManager.activePresetConfig?.pan ?? 0.0) }
  func updateGainIndicator() { updateGainIndicator(activePresetManager.activePresetConfig?.gain ?? 0.0) }
  func addDoubleTapClosure(_ closure: @escaping UIControl.Closure) { doubleTap.addClosure(closure) }
  func addSoundFontClosure(_ closure: @escaping UIControl.Closure) { addSoundFont.addClosure(closure) }
  func addButtonLongPressGestureClosure(_ closure: @escaping UIControl.Closure) { addButtonLongPressGesture.addClosure(closure) }
  func addShowGuideClosure(_ closure: @escaping UIControl.Closure) { showGuide.addClosure(closure) }
  func addShowSettingsClosure(_ closure: @escaping UIControl.Closure) { showSettings.addClosure(closure) }
  func addEditVisibilityClosure(_ closure: @escaping UIControl.Closure) { editVisibility.addClosure(closure) }
  func addShowEffectsClosure(_ closure: @escaping UIControl.Closure) { showEffects.addClosure(closure) }
  func addShowTagsClosure(_ closure: @escaping UIControl.Closure) { showTags.addClosure(closure) }

  func doPanic(_ closure: @escaping UIControl.Closure) {
    presetViewLongPressGesture.addClosure(closure)
    effectsButtonLongPressGesture.addClosure(closure)
  }

  func addShiftKeyboardUpClosure(_ closure: @escaping UIControl.Closure) {
    highestKey.addClosure(closure)
    highestKey.isHidden = false
    slidingKeyboardToggle.isHidden = false
  }

  func addShiftKeyboardDownClosure(_ closure: @escaping UIControl.Closure) {
    lowestKey.addClosure(closure)
    lowestKey.isHidden = false
    slidingKeyboardToggle.isHidden = false
  }

  func addShowMoreButtonsClosure(_ closure: @escaping UIControl.Closure) {
    showMoreButtonsButton.addClosure { [weak self] button in
      guard let self = self, self.showingMoreButtons else { return }
      closure(button)
    }
  }

  func addHideMoreButtonsClosure(_ closure: @escaping UIControl.Closure) {
    showMoreButtonsButton.addClosure { [weak self] button in
      guard let self = self, !self.showingMoreButtons else { return }
      closure(button)
    }
  }

  func routerChangedNotificationInBackground(_ event: ComponentContainerEvent) {
    log.debug("routerChangedNotificationInBackground: \(event.description, privacy: .public)")
    switch event {
    case .audioEngineAvailable(let audioEngine):
      self.audioEngine = audioEngine
      self.midi = audioEngine.midi
      self.midiConnectionMonitor = audioEngine.midiConnectionMonitor
    }
  }
}

private extension InfoBarController {

  @IBAction func toggleMoreButtons(_ sender: UIButton) { setMoreButtonsVisible(state: !showingMoreButtons) }
  @IBAction func showSettings(_ sender: UIButton) { setMoreButtonsVisible(state: false) }
  @IBAction func toggleSlideKeyboard(_ sender: UIButton) { settings.slideKeyboard = !settings.slideKeyboard }

  func beginSettingsView(_ segue: UIStoryboardSegue, sender: Any?) {
    guard let navController = segue.destination as? UINavigationController,
          let viewController = navController.topViewController as? SettingsViewController
    else { return }

    viewController.configure(isMainApp: isMainApp, soundFonts: soundFonts, settings: settings, audioEngine: audioEngine,
                             midi: midi, midiConnectionMonitor: midiConnectionMonitor, infoBar: self)

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

  func setMoreButtonsVisible(state: Bool) {
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

    UIView.transition(with: showMoreButtonsButton, duration: 0.4, options: .transitionCrossDissolve) {
      self.showMoreButtonsButton.setImage(newImage, for: .normal)
    }
  }

  func activePresetChangedNotificationInBackground(_ event: ActivePresetEvent) {
    if case .changed = event {
      DispatchQueue.main.async { self.showActivePreset() }
    }
  }

  func favoritesChangedNotificationInBackground(_ event: FavoritesEvent) {
    DispatchQueue.main.async { self.showActivePreset() }
  }

  func showActivePreset() {
    let activePresetKind = activePresetManager.active
    log.debug("useActivePresetKind BEGIN - \(activePresetKind.description, privacy: .public)")
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

  func setPresetInfo(presetConfig: PresetConfig, isFavored: Bool) {
    log.debug("setPresetInfo: \(presetConfig.name, privacy: .public) - \(isFavored)")
    presetInfo.text = TableCell.favoriteTag(isFavored) + presetConfig.name
    updateTuningIndicator(presetConfig.presetTuning)
    updatePanIndicator(presetConfig.pan)
    updateGainIndicator(presetConfig.gain)
    cancelStatusAnimation()
  }

  func updateTuningIndicator(_ presetTuning: Float) {
    log.debug("updateTuningIndicator BEGIN - \(presetTuning)")
    tuningIndicator.isHidden = presetTuning == 0.0 && settings.globalTuning == 0.0
    log.debug("updateTuningIndicator END")
  }

  func updatePanIndicator(_ presetPan: Float) {
    panIndicator.isHidden = presetPan == 0.0
  }

  func updateGainIndicator(_ presetGain: Float) {
    gainIndicator.isHidden = presetGain == 0.0
  }

  func startStatusAnimation() {
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

  func cancelStatusAnimation() {
    if let fader = self.fader {
      fader.stopAnimation(true)
      self.fader = nil
    }
  }

  @objc func panKeyboard(_ panner: UIPanGestureRecognizer) {
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

  func updateKeyLabels() {
    UIView.performWithoutAnimation {
      lowestKey.setTitle("❰" + lowestKeyValue, for: .normal)
      lowestKey.accessibilityLabel = "Keyboard down before " + lowestKeyValue
      lowestKey.layoutIfNeeded()
      highestKey.setTitle(highestKeyValue + "❱", for: .normal)
      highestKey.accessibilityLabel = "Keyboard up after " + highestKeyValue
      highestKey.layoutIfNeeded()
    }
  }

  func updateSlidingKeyboardState() {
    slidingKeyboardToggle.setTitleColor(settings.slideKeyboard ? .systemTeal : .darkGray, for: .normal)
  }

  func updateMIDIIndicator(accepted: Bool) {
    let color = accepted ? UIColor.systemTeal : UIColor.systemOrange
    midiIndicatorAnimator?.start(radius: midiIndicator.frame.height / 2, color: color, duration: 0.5,
                                 repetitions: 2.0)
  }
}

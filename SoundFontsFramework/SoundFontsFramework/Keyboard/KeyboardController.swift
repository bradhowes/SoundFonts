// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/// Controller for the keyboard view. Creates the individual Key views and handles touch event detection within them.
/// The controller creates an entire 108 keyboard which it then shows only a part of on the screen. The keyboard can
/// be shifted up/down by octaves or by sliding via touch (if enabled).
final class KeyboardController: UIViewController {
  private lazy var log: Logger = Logging.logger("KeyCon")

  private var settings: Settings!

  /// MIDI value of the first note in the keyboard
  private var firstMidiNoteValue = 48 {
    didSet { settings.lowestKeyNote = firstMidiNoteValue }
  }

  /// MIDI value of the last note in the keyboard
  private var lastMidiNoteValue = -1

  @IBOutlet private weak var keyboard: UIView!
  @IBOutlet private weak var keyboardWidthConstraint: NSLayoutConstraint!
  @IBOutlet private weak var keyboardLeadingConstraint: NSLayoutConstraint!

  private var allKeys = [Key]()
  private lazy var visibleKeys: Array<Key>.SubSequence = allKeys[0..<allKeys.count]

  private lazy var keyWidth: CGFloat = CGFloat(settings.keyWidth)
  private var activePresetManager: ActivePresetManager!
  private var keyLabelOptionObservation: NSKeyValueObservation?
  private var keyWidthObservation: NSKeyValueObservation?

  private var infoBar: AnyInfoBar!
  private var touchedKeys = TouchKeyMap()

  private var trackedTouch: UITouch?
  private var panPending: CGFloat = 0.0

  private var keyLabelOption: KeyLabelOption {
    get { KeyLabelOption(rawValue: settings.keyLabelOption) ?? .off }
    set { _ = newValue; allKeys.forEach { $0.setNeedsDisplay() } }
  }

  /// Flag indicating that the audio is currently muted, and playing a note will not generate any sound
  var isMuted: Bool = false {
    didSet {
      if oldValue != isMuted {
        Key.isMuted = self.isMuted
        allKeys.forEach { $0.setNeedsDisplay() }
      }
    }
  }
}

extension KeyboardController {

  override func viewWillAppear(_ animated: Bool) {
    log.debug("viewWillAppear - BEGIN")
    super.viewWillAppear(animated)

    createKeys()
    let lowestKeyNote = settings.lowestKeyNote
    firstMidiNoteValue = lowestKeyNote
    offsetKeyboard(by: -allKeys[firstMidiNoteValue].frame.minX)

    _ = settings.keyLabelOption
    keyLabelOptionObservation = settings.observe(\.keyLabelOption, options: [.new]) { [weak self] _, change in
      guard let self = self, let newValue = change.newValue, let option = KeyLabelOption(rawValue: newValue) else {
        return
      }
      log.debug("keyLabelOptionObservation - option: \(option.rawValue, privacy: .public)")
      self.keyLabelOption = option
    }

    _ = settings.keyWidth
    keyWidthObservation = settings.observe(\.keyWidth, options: [.new]) { [weak self] _, change in
      guard let self = self, let keyWidth = change.newValue else { return }
      log.debug("keyWidthObservation - keyWidth: \(keyWidth)")
      precondition(!self.allKeys.isEmpty)
      self.keyWidth = CGFloat(keyWidth)
      self.releaseAllKeys()
      self.layoutKeys()
    }
    log.debug("viewWillAppear - END")
  }

  /// Redraw keyboard after layout change.
  override func viewDidLayoutSubviews() {
    log.debug("viewDidLayoutSubviews BEGIN")
    super.viewDidLayoutSubviews()
    layoutKeys()
    log.debug("viewDidLayoutSubviews END")
  }
}

// MARK: - Configuration

extension KeyboardController: ControllerConfiguration {

  /**
   Establish connections with other components

   - parameter router: the container holding the other components
   */
  func establishConnections(_ router: ComponentContainer) {
    settings = router.settings
    activePresetManager = router.activePresetManager
    infoBar = router.infoBar
    infoBar.addEventClosure(.shiftKeyboardUp, self.shiftKeyboardUp)
    infoBar.addEventClosure(.shiftKeyboardDown, self.shiftKeyboardDown)

    router.activePresetManager.subscribe(self, notifier: presetChangedNotificationInBackground)
    router.favorites.subscribe(self, notifier: favoritesChangedNotificationInBackground)
    router.subscribe(self, notifier: routerChangedNotificationInBackground)

    touchedKeys.processor = router.audioEngine
  }
}

// MARK: - Touch Processing

extension KeyboardController {

  /**
   Begin processing a touch event for the keyboard

   - parameter touches: the touch events that started
   - parameter event: the event that spawned the touches
   */
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    pressKeys(touches)
  }

  /**
   Update touch events for the keyboard

   - parameter touches: the touch events that moved
   - parameter event: the event that spawned the touches
   */
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    if settings.slideKeyboard {
      if trackedTouch == nil {
        trackedTouch = touches.first
        panPending = 0.0
      }

      for touch in touches where touch === trackedTouch {
        panPending += touch.location(in: keyboard).x - touch.previousLocation(in: keyboard).x
        if abs(panPending) > 10.0 {
          let keyboardWidth = keyboard.frame.width
          let viewWidth = view.frame.width
          let newConstraint = min(
            0,
            max(
              keyboardLeadingConstraint.constant + panPending,
              viewWidth - keyboardWidth))
          panPending = 0.0
          offsetKeyboard(by: newConstraint)
        }
      }
    } else {
      // Moved touches may become associated with a new key (releasing the old one)
      pressKeys(touches)
    }
  }

  /**
   Complete touch events for the keyboard

   - parameter touches: the touch events that stopped
   - parameter event: the event that spawned the touches
   */
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { releaseKeys(touches) }

  /**
   Cancel touch events for the keyboard

   - parameter touches: the touch events that stopped
   - parameter event: the event that spawned the touches
   */
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { releaseKeys(touches) }
}

// MARK: - Keyboard Protocol

extension KeyboardController: AnyKeyboard {

  /**
   Notification that the given note is being played (eg by MIDI event)

   - parameter note: the MIDI note value being played
   */
  func noteIsOn(note: UInt8) {
    guard note < allKeys.count else { return }
    let key = allKeys[Int(note)]
    DispatchQueue.main.async {
      key.pressed = true
      self.updateInfoBar(note: key.note)
    }
  }

  /**
   Notification that the given note is not being played (eg by MIDI event)

   - parameter note: the MIDI note value not being played
   */
  func noteIsOff(note: UInt8) {
    guard note < allKeys.count else { return }
    let key = allKeys[Int(note)]
    DispatchQueue.main.async { key.pressed = false }
  }

  /// The current lowest MIDI note of the keyboard (mutable)
  var lowestNote: Note {
    get { Note(midiNoteValue: firstMidiNoteValue) }
    set { shiftKeys(by: newValue.midiNoteValue - firstMidiNoteValue) }
  }

  /// The current highest MIDI note of the keyboard (read-only)
  var highestNote: Note { Note(midiNoteValue: lastMidiNoteValue) }

  /**
   Demand that all keys stop playing audio.
   */
  func releaseAllKeys() {
    log.debug("releaseAllKeys BEGIN")
    touchedKeys.releaseAll()
    DispatchQueue.main.async { self.allKeys.forEach { $0.pressed = false } }
    log.debug("releaseAllKeys END")
  }
}

// MARK: - Key Generation

private extension KeyboardController {

  var maxMidiValue: Int { 12 * 9 } // C8

  func createKeys() {
    log.debug("createKeys BEGIN")
    var blackKeys = [Key]()
    for each in KeyParamsSequence(keyWidth: keyWidth, keyHeight: keyboard.bounds.size.height, firstMidiNote: 0,
                                  lastMidiNote: maxMidiValue) {
      let key = Key(frame: each.0, note: each.1, settings: settings)
      if key.note.accented {
        blackKeys.append(key)
      } else {
        keyboard.addSubview(key)
      }
      allKeys.append(key)
    }

    blackKeys.forEach { keyboard.addSubview($0) }
    keyboardWidthConstraint.constant = allKeys[allKeys.count - 1].frame.maxX
    log.debug("createKeys END")
  }

  func layoutKeys() {
    log.debug("layoutKeys BEGIN")
    for (key, def) in zip(allKeys, KeyParamsSequence(keyWidth: keyWidth, keyHeight: keyboard.bounds.size.height,
                                                     firstMidiNote: 0, lastMidiNote: maxMidiValue)) {
      key.frame = def.0
    }

    updateVisibleKeys()
    log.debug("layoutKeys END")
  }

  func offsetKeyboard(by offset: CGFloat) {
    keyboardLeadingConstraint.constant = offset
    updateVisibleKeys()
  }

  func pressKeys(_ touches: Set<UITouch>) {
    var firstKey: Key?
    for touch in touches {
      if let key = visibleKeys.touched(by: touch.location(in: keyboard)) {
        if touchedKeys.assign(touch, key: key) && firstKey == nil {
          firstKey = key
        }
      }
    }

    if let firstKey = firstKey, settings.showSolfegeLabel == true {
      updateInfoBar(note: firstKey.note)
    }
  }

  func releaseKeys(_ touches: Set<UITouch>) {
    touches.forEach { touchedKeys.release($0) }
    if let touch = trackedTouch, touches.contains(touch) {
      trackedTouch = nil
    }
  }

  func updateVisibleKeys() {
    log.debug("updateVisibleKeys BEGIN")
    let offset = keyboardLeadingConstraint.constant
    let visible = allKeys.keySpan(for: view.bounds.offsetBy(dx: -offset, dy: 0.0))
    firstMidiNoteValue = visible.startIndex
    lastMidiNoteValue = visible.endIndex - 1
    infoBar?.setVisibleKeyLabels(from: lowestNote.label, to: highestNote.label)
    log.debug("updateVisibleKeys END")
  }

  func updateInfoBar(note: Note) {
    log.debug("updateInfoBar BEGIN - note: \(note.description, privacy: .public)")
    if isMuted {
      infoBar.setStatusText("🔇")
    } else if settings.showSolfegeLabel {
      infoBar.setStatusText(note.label + " - " + note.solfege)
    } else {
      infoBar.setStatusText(note.label)
    }
    log.debug("updateInfoBar END")
  }

  func shiftKeyboardUp(_ sender: AnyObject) {
    log.debug("shiftKeyBoardUp")
    precondition(!allKeys.isEmpty)
    if lastMidiNoteValue < maxMidiValue {
      let shift: Int = {
        (firstMidiNoteValue % 12 == 0)
          ? min(12, maxMidiValue - lastMidiNoteValue) : (12 - firstMidiNoteValue % 12)
      }()
      shiftKeys(by: shift)
    }
    AskForReview.maybe()
  }

  func shiftKeyboardDown(_ sender: AnyObject) {
    log.debug("shiftKeyBoardDown")
    precondition(!allKeys.isEmpty)
    if firstMidiNoteValue >= 12 {
      let shift: Int = {
        (firstMidiNoteValue % 12) == 0 ? min(firstMidiNoteValue, 12) : (firstMidiNoteValue % 12)
      }()
      shiftKeys(by: -shift)
    }
    AskForReview.maybe()
  }

  func shiftKeys(by: Int) {
    assert(!allKeys.isEmpty)
    if by != 0 {
      releaseAllKeys()
      firstMidiNoteValue += by
      lastMidiNoteValue += by
      if lowestNote.accented { firstMidiNoteValue += 1 }
      offsetKeyboard(by: -allKeys[firstMidiNoteValue].frame.minX)
    }
  }

  func routerChangedNotificationInBackground(_ event: ComponentContainerEvent) {
    if case let .audioEngineAvailable(audioEngine) = event {
      touchedKeys.processor = audioEngine
    }
  }

  func presetChangedNotificationInBackground(_ event: ActivePresetEvent) {
    switch event {
    case .changed:
      if let presetConfig = activePresetManager.activePresetConfig {
        DispatchQueue.main.async { self.updateWith(presetConfig: presetConfig) }
      }
    case .loaded: break
    }
  }

  func favoritesChangedNotificationInBackground(_ event: FavoritesEvent) {
    switch event {
    case let .changed(index: _, favorite: favorite):
      DispatchQueue.main.async { self.handleFavoriteChanged(favorite: favorite) }
    case let .selected(index: _, favorite: favorite):
      DispatchQueue.main.async { self.updateWith(presetConfig: favorite.presetConfig) }
    case .added: break
    case .beginEdit: break
    case .removed: break
    case .removedAll: break
    case .restored: break
    }
  }

  func handleFavoriteChanged(favorite: Favorite) {
    if self.activePresetManager.activeFavorite == favorite {
      self.updateWith(presetConfig: favorite.presetConfig)
    }
  }

  func updateWith(presetConfig: PresetConfig) {
    if presetConfig.keyboardLowestNoteEnabled, let lowest = presetConfig.keyboardLowestNote {
      lowestNote = lowest
    }
  }
}

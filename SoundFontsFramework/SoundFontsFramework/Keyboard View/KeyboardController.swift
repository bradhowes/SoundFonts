// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/// Controller for the keyboard view. Creates the individual Key views and handles touch event detection within them.
/// The controller creates an entire 108 keyboard which it then shows only a part of on the screen. The keyboard can
/// be shifted up/down by octaves or by sliding via touch (if enabled).
final class KeyboardController: UIViewController {
  private lazy var log = Logging.logger("KeyCon")

  /// MIDI value of the first note in the keyboard
  private var firstMidiNoteValue = 48 {
    didSet { Settings.shared.lowestKeyNote = firstMidiNoteValue }
  }

  /// MIDI value of the last note in the keyboard
  private var lastMidiNoteValue = -1

  @IBOutlet private weak var keyboard: UIView!
  @IBOutlet private weak var keyboardWidthConstraint: NSLayoutConstraint!
  @IBOutlet private weak var keyboardLeadingConstraint: NSLayoutConstraint!

  private var allKeys = [Key]()
  private lazy var visibleKeys: Array<Key>.SubSequence = allKeys[0..<allKeys.count]

  private var keyWidth: CGFloat = CGFloat(Settings.shared.keyWidth)
  private var activePatchManager: ActivePatchManager!
  private var keyLabelOptionObservation: NSKeyValueObservation?
  private var keyWidthObservation: NSKeyValueObservation?

  private var infoBar: InfoBar!
  private var touchedKeys = TouchKeyMap()

  private var trackedTouch: UITouch?
  private var panPending: CGFloat = 0.0

  private var keyLabelOption: KeyLabelOption {
    get { Key.keyLabelOption }
    set {
      if Key.keyLabelOption != newValue {
        Key.keyLabelOption = newValue
        allKeys.forEach { $0.setNeedsDisplay() }
      }
    }
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

  /// Initialize controller with view loaded
  override func viewDidLoad() {
    createKeys()
    let lowestKeyNote = Settings.shared.lowestKeyNote
    firstMidiNoteValue = lowestKeyNote
    offsetKeyboard(by: -allKeys[firstMidiNoteValue].frame.minX)

    keyLabelOptionObservation = Settings.shared.observe(
      \.keyLabelOption,
      options: [.new]
    ) { [weak self] _, change in
      guard let newValue = change.newValue, let option = KeyLabelOption(rawValue: newValue) else {
        return
      }
      self?.keyLabelOption = option
    }

    keyWidthObservation = Settings.shared.observe(\.keyWidth, options: [.new]) { [weak self] _, change in
      guard let self = self, let keyWidth = change.newValue else { return }
      precondition(!self.allKeys.isEmpty)
      self.keyWidth = CGFloat(keyWidth)
      Key.keyWidth = self.keyWidth
      self.releaseAllKeys()
      self.layoutKeys()
    }
  }

  /// Redraw keyboard after layout change.
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    layoutKeys()
  }
}

// MARK: - Configuration
extension KeyboardController: ControllerConfiguration {

  /**
     Establish connections with other components

     - parameter router: the container holding the other components
     */
  func establishConnections(_ router: ComponentContainer) {
    activePatchManager = router.activePatchManager
    infoBar = router.infoBar
    infoBar.addEventClosure(.shiftKeyboardUp, self.shiftKeyboardUp)
    infoBar.addEventClosure(.shiftKeyboardDown, self.shiftKeyboardDown)
    router.activePatchManager.subscribe(self, notifier: presetChanged)
    router.favorites.subscribe(self, notifier: favoritesChange)
    router.subscribe(self, notifier: routerChange)
  }

  private func routerChange(_ event: ComponentContainerEvent) {
    if case let .samplerAvailable(sampler) = event {
      touchedKeys.sampler = sampler
    }
  }

  private func presetChanged(_ event: ActivePatchEvent) {
    switch event {
    case .active:
      if let presetConfig = activePatchManager.activePatch?.presetConfig {
        updateWith(presetConfig: presetConfig)
      }
    }
  }

  private func favoritesChange(_ event: FavoritesEvent) {
    switch event {
    case let .changed(index: _, favorite: favorite):
      if activePatchManager.activeFavorite == favorite {
        updateWith(presetConfig: favorite.presetConfig)
      }
    case let .selected(index: _, favorite: favorite):
      updateWith(presetConfig: favorite.presetConfig)
    case .added: break
    case .beginEdit: break
    case .removed: break
    case .removedAll: break
    case .restored: break
    }
  }

  private func updateWith(presetConfig: PresetConfig) {
    if presetConfig.keyboardLowestNoteEnabled, let lowest = presetConfig.keyboardLowestNote {
      lowestNote = lowest
    }
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
    if Settings.shared.slideKeyboard {
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
    }

    // Moved touches may become associated with a new key (releasing the old one)
    pressKeys(touches)
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
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    releaseKeys(touches)
  }
}

// MARK: - Keyboard Protocol

extension KeyboardController: Keyboard {

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
    touchedKeys.releaseAll()
    DispatchQueue.main.async { self.allKeys.forEach { $0.pressed = false } }
  }
}

// MARK: - Key Generation

extension KeyboardController {

  private func createKeys() {
    var blackKeys = [Key]()
    for each in KeyParamsSequence(
      keyWidth: keyWidth, keyHeight: keyboard.bounds.size.height, firstMidiNote: 0,
      lastMidiNote: Sampler.maxMidiValue)
    {
      let key = Key(frame: each.0, note: each.1)
      if key.note.accented {
        blackKeys.append(key)
      } else {
        keyboard.addSubview(key)
      }
      allKeys.append(key)
    }

    blackKeys.forEach { keyboard.addSubview($0) }
    keyboardWidthConstraint.constant = allKeys[allKeys.count - 1].frame.maxX
  }

  private func layoutKeys() {
    for (key, def) in zip(
      allKeys,
      KeyParamsSequence(
        keyWidth: keyWidth, keyHeight: keyboard.bounds.size.height,
        firstMidiNote: 0, lastMidiNote: Sampler.maxMidiValue))
    {
      key.frame = def.0
    }

    updateVisibleKeys()
  }

  private func offsetKeyboard(by offset: CGFloat) {
    keyboardLeadingConstraint.constant = offset
    updateVisibleKeys()
  }

  private func pressKeys(_ touches: Set<UITouch>) {
    var firstKey: Key?
    for touch in touches {
      if let key = visibleKeys.touched(by: touch.location(in: keyboard)) {
        if touchedKeys.assign(touch, key: key) && firstKey == nil {
          firstKey = key
        }
      }
    }

    if let firstKey = firstKey, Settings.shared.showSolfegeLabel == true {
      updateInfoBar(note: firstKey.note)
    }
  }

  private func releaseKeys(_ touches: Set<UITouch>) {
    touches.forEach { touchedKeys.release($0) }
    if let touch = trackedTouch, touches.contains(touch) {
      trackedTouch = nil
    }
  }

  private func updateVisibleKeys() {
    let offset = keyboardLeadingConstraint.constant
    let visible = allKeys.keySpan(for: view.bounds.offsetBy(dx: -offset, dy: 0.0))
    firstMidiNoteValue = visible.startIndex
    lastMidiNoteValue = visible.endIndex - 1
    infoBar?.setVisibleKeyLabels(from: lowestNote.label, to: highestNote.label)
  }

  private func updateInfoBar(note: Note) {
    if isMuted {
      infoBar.setStatusText("🔇")
    } else if Settings.shared.showSolfegeLabel {
      infoBar.setStatusText(note.label + " - " + note.solfege)
    } else {
      infoBar.setStatusText(note.label)
    }
  }
}

// MARK: - Keyboard Shifting

extension KeyboardController {

  private func shiftKeyboardUp(_ sender: AnyObject) {
    os_log(.info, log: log, "shiftKeyBoardUp")
    precondition(!allKeys.isEmpty)
    if lastMidiNoteValue < Sampler.maxMidiValue {
      let shift: Int = {
        (firstMidiNoteValue % 12 == 0)
          ? min(12, Sampler.maxMidiValue - lastMidiNoteValue) : (12 - firstMidiNoteValue % 12)
      }()
      shiftKeys(by: shift)
    }
    AskForReview.maybe()
  }

  private func shiftKeyboardDown(_ sender: AnyObject) {
    os_log(.info, log: log, "shiftKeyBoardDown")
    precondition(!allKeys.isEmpty)
    if firstMidiNoteValue >= 12 {
      let shift: Int = {
        (firstMidiNoteValue % 12) == 0 ? min(firstMidiNoteValue, 12) : (firstMidiNoteValue % 12)
      }()
      shiftKeys(by: -shift)
    }
    AskForReview.maybe()
  }

  private func shiftKeys(by: Int) {
    assert(!allKeys.isEmpty)
    if by != 0 {
      releaseAllKeys()
      firstMidiNoteValue += by
      lastMidiNoteValue += by
      if lowestNote.accented { firstMidiNoteValue += 1 }
      offsetKeyboard(by: -allKeys[firstMidiNoteValue].frame.minX)
    }
  }
}

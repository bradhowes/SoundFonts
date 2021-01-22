// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Controller for the keyboard view. Creates the individual Key views and handles touch event detection within them.
 The controller creates an entire 108 keyboard which it then showns only a part of on the screen. The keyboard can
 be shifted up/down by octaves or by sliding via touch (if enabled).
 */
final class KeyboardController: UIViewController {
    private let log = Logging.logger("KeyCon")

    /// MIDI value of the first note in the keyboard
    private var firstMidiNoteValue = 48 { didSet { Settings.shared.lowestKeyNote = firstMidiNoteValue } }

    /// MIDI value of the last note in the keyboard
    private var lastMidiNoteValue = -1

    @IBOutlet weak var keyboard: UIView!
    @IBOutlet weak var keyboardWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var keyboardLeadingConstraint: NSLayoutConstraint!

    private var allKeys = [Key]()
    private lazy var visibleKeys: Array<Key>.SubSequence = allKeys[0..<allKeys.count]

    private var keyWidth: CGFloat = CGFloat(Settings.shared.keyWidth)
    private var activePatchManager: ActivePatchManager!
    private var midiChannelObservation: NSKeyValueObservation?
    private var keyLabelOptionObservation: NSKeyValueObservation?
    private var keyWidthObservation: NSKeyValueObservation?

    private var infoBar: InfoBar!
    private var sampler: Sampler!
    private var touchedKeys: TouchKeyMap!

    private var trackedTouch: UITouch?
    private var panPending: CGFloat = 0.0

    public private(set) var channel: Int = Settings.shared.midiChannel

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

    override func viewDidLoad() {
        createKeys()
        let lowestKeyNote = Settings.shared.lowestKeyNote
        firstMidiNoteValue = lowestKeyNote
        offsetKeyboard(by: -allKeys[firstMidiNoteValue].frame.minX)

        midiChannelObservation = Settings.shared.observe(\.midiChannel, options: .new) { _, change in
            guard let newValue = change.newValue else { return }
            self.releaseAllKeys()
            self.channel = newValue
        }

        keyLabelOptionObservation = Settings.shared.observe(\.keyLabelOption, options: [.new]) { _, change in
            guard let newValue = change.newValue, let option = KeyLabelOption(rawValue: newValue) else { return }
            self.keyLabelOption = option
        }

        keyWidthObservation = Settings.shared.observe(\.keyWidth, options: [.new]) { _, change in
            guard let keyWidth = change.newValue else { return }
            precondition(!self.allKeys.isEmpty)
            self.keyWidth = CGFloat(keyWidth)
            Key.keyWidth = self.keyWidth
            self.releaseAllKeys()
            self.layoutKeys()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutKeys()
    }
}

// MARK: - Configuration
extension KeyboardController: ControllerConfiguration {

    func establishConnections(_ router: ComponentContainer) {
        activePatchManager = router.activePatchManager
        infoBar = router.infoBar
        infoBar.addEventClosure(.shiftKeyboardUp, self.shiftKeyboardUp)
        infoBar.addEventClosure(.shiftKeyboardDown, self.shiftKeyboardDown)
        sampler = router.sampler
        touchedKeys = TouchKeyMap(sampler: sampler)
        router.favorites.subscribe(self, notifier: favoritesChange)
    }

    private func favoritesChange(_ event: FavoritesEvent) {
        switch event {
        case let .changed(index: _, favorite: favorite):
            if activePatchManager.favorite == favorite {
                updateWith(favorite: favorite)
            }
        case let .selected(index: _, favorite: favorite):
            updateWith(favorite: favorite)
        default:
            break
        }
    }

    private func updateWith(favorite: LegacyFavorite) {
        if let lowest = favorite.presetConfig?.keyboardLowestNote ?? favorite.keyboardLowestNote {
            lowestNote = lowest
        }
    }
}

// MARK: - Keyboard Shifting

extension KeyboardController {

    private func shiftKeyboardUp(_ sender: AnyObject) {
        os_log(.info, log: log, "shiftKeyBoardUp")
        precondition(!allKeys.isEmpty)
        if lastMidiNoteValue < Sampler.maxMidiValue {
            let shift: Int = { (firstMidiNoteValue % 12 == 0) ? min(12, Sampler.maxMidiValue - lastMidiNoteValue) : (12 - firstMidiNoteValue % 12) }()
            shiftKeys(by: shift)
        }
        AskForReview.maybe()
    }

    private func shiftKeyboardDown(_ sender: AnyObject) {
        os_log(.info, log: log, "shiftKeyBoardDown")
        precondition(!allKeys.isEmpty)
        if firstMidiNoteValue >= 12 {
            let shift: Int = { (firstMidiNoteValue % 12) == 0 ? min(firstMidiNoteValue, 12) : (firstMidiNoteValue % 12) }()
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

// MARK: - Touch Processing

extension KeyboardController {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        pressKeys(touches)
    }

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
                    let newConstraint = min(0, max(keyboardLeadingConstraint.constant + panPending, viewWidth - keyboardWidth))
                    panPending = 0.0
                    offsetKeyboard(by: newConstraint)
                }
            }
        }

        // Moved touches may become associated with a new key (releasing the old one)
        pressKeys(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { releaseKeys(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { releaseKeys(touches) }
}

// MARK: - Keyboard Protocol

extension KeyboardController: Keyboard {

    func noteOff(note: UInt8) {
        guard note < allKeys.count else { return }
        let key = allKeys[Int(note)]
        DispatchQueue.main.async { key.pressed = false }
    }

    func noteOn(note: UInt8, velocity: UInt8) {
        guard note < allKeys.count else { return }
        let key = allKeys[Int(note)]
        DispatchQueue.main.async {
            key.pressed = true
            self.updateInfoBar(note: key.note)
        }
    }

    var lowestNote: Note {
        get { Note(midiNoteValue: firstMidiNoteValue) }
        set { shiftKeys(by: newValue.midiNoteValue - firstMidiNoteValue) }
    }

    var highestNote: Note { Note(midiNoteValue: lastMidiNoteValue) }

    func releaseAllKeys() {
        touchedKeys.releaseAll()
        DispatchQueue.main.async { self.allKeys.forEach { $0.pressed = false } }
    }
}

// MARK: - Key Generation

extension KeyboardController {

    private func createKeys() {
        var blackKeys = [Key]()
        for each in KeyParamsSequence(keyWidth: keyWidth, keyHeight: keyboard.bounds.size.height, firstMidiNote: 0, lastMidiNote: Sampler.maxMidiValue) {
            let key = Key(frame: each.0, note: each.1)
            if key.note.accented {
                blackKeys.append(key)
            }
            else {
                keyboard.addSubview(key)
            }
            allKeys.append(key)
        }

        blackKeys.forEach { keyboard.addSubview($0) }
        keyboardWidthConstraint.constant = allKeys[allKeys.count - 1].frame.maxX
    }

    private func layoutKeys() {
        for (key, def) in zip(allKeys, KeyParamsSequence(keyWidth: keyWidth, keyHeight: keyboard.bounds.size.height, firstMidiNote: 0, lastMidiNote: Sampler.maxMidiValue)) {
            key.frame = def.0
        }

        updateVisibleKeys()
    }

    private func offsetKeyboard(by offset: CGFloat) {
        keyboardLeadingConstraint.constant = offset
        updateVisibleKeys()
    }

    private func pressKeys(_ touches: Set<UITouch>) {
        for touch in touches {
            if let key = visibleKeys.touched(by: touch.location(in: keyboard)) {
                touchedKeys.assign(touch, key: key)
            }
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
            infoBar.setStatus("🔇")
        }
        else {
            if Settings.shared.showSolfegeLabel {
                infoBar.setStatus(note.label + " - " + note.solfege)
            }
            else {
                infoBar.setStatus(note.label)
            }
        }
    }
}

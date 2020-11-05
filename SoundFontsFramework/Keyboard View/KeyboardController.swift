// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Controller for the keyboard view. Creates the individual key views and handles touch event detection within them.
 */
final class KeyboardController: UIViewController {
    private let log = Logging.logger("KeyCon")

    weak var delegate: KeyboardDelegate?

    /// MIDI value of the first note in the keyboard
    private var firstMidiNoteValue = 48 { didSet { settings.lowestKeyNote = firstMidiNoteValue } }

    /// MIDI value of the last note in the keyboard
    private var lastMidiNoteValue = -1

    @IBOutlet weak var keyboard: UIView!
    @IBOutlet weak var keyboardWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var keyboardLeadingConstraint: NSLayoutConstraint!

    private weak var infoBar: InfoBar?

    private var allKeys = [Key]()
    private lazy var visibleKeys: Array<Key>.SubSequence = allKeys[0..<allKeys.count]

    private var keyWidth: CGFloat = CGFloat(settings.keyWidth)
    private var activePatchManager: ActivePatchManager!
    private var keyLabelOptionObservation: NSKeyValueObservation?
    private var keyWidthObservation: NSKeyValueObservation?

    private var trackedTouch: UITouch?
    private var panPending: CGFloat = 0.0

    /// Flag indicating that the audio is currently muted, and playing a note will not generate any sound
    var isMuted: Bool = false {
        didSet {
            if oldValue != isMuted {
                Key.isMuted = self.isMuted
                allKeys.forEach { $0.setNeedsDisplay() }
            }
        }
    }

    var keyLabelOption: KeyLabelOption {
        get { Key.keyLabelOption }
        set {
            if Key.keyLabelOption != newValue {
                Key.keyLabelOption = newValue
                allKeys.forEach { $0.setNeedsDisplay() }
            }
        }
    }

    override func viewDidLoad() {
        createKeys()
        let lowestKeyNote = settings.lowestKeyNote
        firstMidiNoteValue = lowestKeyNote
        offsetKeyboard(by: -allKeys[firstMidiNoteValue].frame.minX)

        keyLabelOptionObservation = settings.observe(\.keyLabelOption, options: [.new]) { _, change in
            guard let newValue = change.newValue, let option = KeyLabelOption(rawValue: newValue) else { return }
            self.keyLabelOption = option
        }

        keyWidthObservation = settings.observe(\.keyWidth, options: [.new]) { _, change in
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
        infoBar?.addEventClosure(.shiftKeyboardUp, self.shiftKeyboardUp)
        infoBar?.addEventClosure(.shiftKeyboardDown, self.shiftKeyboardDown)
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
        if let lowest = favorite.keyboardLowestNote {
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
        // New touches will always cause pressed keys
        updateTouchedKeys(touches, with: event, pressed: true)
        trackedTouch = nil
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if settings[.slideKeyboard] {
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
        reviseTouchedKeys(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Touches no longer in view
        updateTouchedKeys(touches, with: event, pressed: false)
        trackedTouch = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Stop everything -- system has interrupted us.
        updateTouchedKeys(touches, with: event, pressed: false)
        trackedTouch = nil
    }

    private func reviseTouchedKeys(_ touches: Set<UITouch>, with event: UIEvent?) {

        // Look for keys that *did* belong to a touch that moved
        let previous = touches.map { findTouchedKey(touch: $0, with: event, previous: true) }

        // Look for keys that *now* belong to a touch that moved
        let found = touches.map { findTouchedKey(touch: $0, with: event, previous: false) }

        // Evaluate the old/new pairs and record which key should no longer be pressed and which
        // ones should now be pressed
        let changes = zip(previous, found).reduce(into: (released: Set<Key>(), pressed: Set<Key>())) { acc, pair in
            switch (pair.0, pair.1) {
            case let (prev?, next?):
                if prev != next {
                    acc.released.insert(prev)
                    acc.pressed.insert(next)
                }
            case let (.none, next?): acc.pressed.insert(next)
            case let (prev?, .none): acc.released.insert(prev)
            case (.none, .none): break
            }
        }

        // For released keys, update their status based on their presence in the pressed set
        changes.released.forEach { setKeyPressed($0, pressed: changes.pressed.contains($0)) }

        // For the pressed keys, do the usual. There can be some overlap with above, but there are only so many
        // touches...
        changes.pressed.forEach { setKeyPressed($0, pressed: true) }
    }

    private func updateTouchedKeys(_ touches: Set<UITouch>, with event: UIEvent?, pressed: Bool) {
        touches.compactMap { findTouchedKey(touch: $0, with: event) }
            .forEach { setKeyPressed($0, pressed: pressed) }
        if !pressed {
            touches.compactMap { findTouchedKey(touch: $0, with: event, previous: true) }
                .forEach { setKeyPressed($0, pressed: pressed) }
        }
    }

    private func findTouchedKey(touch: UITouch, with event: UIEvent?, previous: Bool = false) -> Key? {
        let point = previous ? touch.previousLocation(in: view) : touch.location(in: view)
        if let found = visibleKeys.first(where: { $0.point(inside: view.convert(point, to: $0), with: event) }) {
            if !found.note.accented {
                let next = allKeys[found.note.midiNoteValue + 1]
                if next.note.accented && next.point(inside: view.convert(point, to: next), with: event) {
                    return next
                }
            }
            return found
        }
        return nil
    }

    private func setKeyPressed(_ key: Key, pressed: Bool) {
        if pressed != key.pressed {
            key.pressed = pressed
            if pressed {
                delegate?.noteOn(key.note)
            }
            else {
                delegate?.noteOff(key.note)
            }
        }
    }
}

// MARK: - Keyboard Protocol

extension KeyboardController: Keyboard {

    var lowestNote: Note {
        get { Note(midiNoteValue: firstMidiNoteValue) }
        set { shiftKeys(by: newValue.midiNoteValue - firstMidiNoteValue) }
    }

    var highestNote: Note { Note(midiNoteValue: lastMidiNoteValue) }

    func releaseAllKeys() {
        visibleKeys.forEach { setKeyPressed($0, pressed: false) }
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

    private func updateVisibleKeys() {
        let offset = keyboardLeadingConstraint.constant
        let visible = allKeys.keySpan(for: view.bounds.offsetBy(dx: -offset, dy: 0.0))
        firstMidiNoteValue = visible.startIndex
        lastMidiNoteValue = visible.endIndex - 1
        infoBar?.setVisibleKeyLabels(from: lowestNote.label, to: highestNote.label)
    }
}

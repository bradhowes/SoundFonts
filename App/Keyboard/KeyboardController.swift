// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import SoundFontsFramework

extension SettingKeys {
    static let lowestKeyNote = SettingKey<Int>("lowestKeyNote", defaultValue: 48)
}

/**
 Controller for the keyboard view. Creates the individual key views and handles touch event detection within them.
 */
final class KeyboardController: UIViewController {

    weak var delegate: KeyboardDelegate?

    /// MIDI value of the first note in the keyboard
    private var firstMidiNoteValue = 48 {
        didSet {
            Settings[.lowestKeyNote] = firstMidiNoteValue
        }
    }

    /// MIDI value of the last note in the keyboard
    private var lastMidiNoteValue = -1

    /// Collection of Key instances for the keyboard. Note that in here the 'black' keys appear before the 'white' keys
    /// so that touch processing happens correctly.
    private var keys = [Key]()

    /// How wide each key will be
    private let keyWidth: CGFloat = 64.0

    private typealias SetVisibleKeyLabelsProc = (String, String) -> Void
    private var setVisibleKeyLabels: SetVisibleKeyLabelsProc?

    /// Flag indicating that the audio is currently muted, and playing a note will not generate any sound
    var isMuted: Bool = false {
        didSet {
            Key.isMuted = self.isMuted
            keys.forEach { $0.setNeedsDisplay() }
        }
    }

    override func viewDidLoad() {
        let lowestNote = Settings[.lowestKeyNote]
        firstMidiNoteValue = max(lowestNote, 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        createKeys()
    }
}

// MARK: - Configuration
extension KeyboardController: ControllerConfiguration {

    func establishConnections(_ router: ComponentContainer) {
        router.infoBar.addTarget(.shiftKeyboardUp, target: self, action: #selector(shiftKeyboardUp))
        router.infoBar.addTarget(.shiftKeyboardDown, target: self, action: #selector(shiftKeyboardDown))
        setVisibleKeyLabels = { router.infoBar.setVisibleKeyLabels(from: $0, to: $1) }
        router.favorites.subscribe(self, closure: favoritesChange)
    }

    private func favoritesChange(_ event: FavoritesEvent) {
        switch event {
        case let .selected(index: _, favorite: favorite):
            if let lowest = favorite.keyboardLowestNote {
                lowestNote = lowest
            }
        default:
            break
        }
    }
}

// MARK: - Keyboard Shifting

extension KeyboardController {

    @IBAction private func shiftKeyboardUp(_ sender: UIButton) {
        assert(!keys.isEmpty)
        if lastMidiNoteValue < Sampler.maxMidiValue {
            let shift: Int = {
                if firstMidiNoteValue % 12 == 0 {
                    return min(keys.count, 12)
                }
                else {
                    return 12 - firstMidiNoteValue % 12
                }
            }()

            shiftKeys(by: min(shift, Sampler.maxMidiValue - lastMidiNoteValue))
        }
    }

    @IBAction private func shiftKeyboardDown(_ sender: UIButton) {
        assert(!keys.isEmpty)
        if firstMidiNoteValue > 0 {
            let shift: Int = {
                if firstMidiNoteValue % 12 == 0 {
                    return min(firstMidiNoteValue, min(keys.count, 12))
                }
                else {
                    return firstMidiNoteValue % 12
                }
            }()

            if shift > 0 {
                shiftKeys(by: -shift)
            }
        }
    }

    private func shiftKeys(by: Int) {
        assert(!keys.isEmpty)
        if by != 0 {
            releaseAllKeys() // Cancel any touched keys before remaking the keyboard
            firstMidiNoteValue += by
            view.setNeedsLayout()
        }
    }
}

// MARK: - Touch Processing

extension KeyboardController {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // New touches will always cause pressed keys
        updateTouchedKeys(touches, with: event, pressed: true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Moved touches may become associated with a new key (releasing the old one)
        reviseTouchedKeys(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Touches no longer in view
        updateTouchedKeys(touches, with: event, pressed: false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Stop everything -- system has interrupted us.
        updateTouchedKeys(touches, with: event, pressed: false)
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
        let found = keys.first { $0.point(inside: view.convert(point, to: $0), with: event) }
        return found
    }

    /**
     Handle the pressed state change for a Key instance. Commuunicates the change to the delegate.
     
     - parameter key: the Key that changed
     - parameter pressed: the new state of the key
     */
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
        keys.forEach { setKeyPressed($0, pressed: false) }
    }
}

// MARK: - Key Generation

extension KeyboardController {

    private func createKeys() {
        keys.forEach { $0.removeFromSuperview() }

        let newKeyDefs = Array(KeyParamsSequence(midiNoteStart: firstMidiNoteValue, limit: view.bounds.size.width,
                                                 stride: keyWidth, height: view.bounds.size.height))

        // Handle edge-case where we generated a key with a MIDI value that is too big. This *could* be detected and
        // dealt with in KeyParamSequence, but this is a bit cleaner, and rarely executed.
        lastMidiNoteValue = firstMidiNoteValue + newKeyDefs.count - 1
        if lastMidiNoteValue > Sampler.maxMidiValue {
            firstMidiNoteValue -= lastMidiNoteValue - Sampler.maxMidiValue
            createKeys()
            return
        }

        // Transform the key definitions into Key instances and partition into two groups, one for the black keys and
        // another for the white keys.
        let partitionedKeys = newKeyDefs.reduce(into: (black: [Key](), white: [Key]())) { acc, def in
            let key = Key(frame: def.0, note: def.1)
            if key.note.accented {
                acc.black.append(key)
            }
            else {
                acc.white.append(key)
            }
        }

        // Create the white keys first so that they will appear below the black keys, but store the 'black' keys
        // first so that they will receive a touch before a 'white' key if there is an overlap.
        partitionedKeys.white.forEach { view.addSubview($0) }
        partitionedKeys.black.forEach { view.addSubview($0) }
        keys = partitionedKeys.black + partitionedKeys.white

        setVisibleKeyLabels?(lowestNote.label, highestNote.label)
    }

    // Custom sequence / iterator that will spit out 2-tuples of CGRect and Note values for the next key
    // in a keyboard view.
    private struct KeyParamsSequence: Sequence, IteratorProtocol {
        private var nextMidiNote: Int
        private var nextX: CGFloat
        private let xLimit: CGFloat
        private let xStride: CGFloat
        private let height: CGFloat

        private let blackKeyHeightScale: CGFloat = 0.6

        init(midiNoteStart: Int, limit: CGFloat, stride: CGFloat, height: CGFloat) {
            self.nextMidiNote = midiNoteStart
            self.nextX = 0
            self.xLimit = limit
            self.xStride = stride
            self.height = height
        }

        func makeIterator() -> KeyParamsSequence {
            return self
        }

        mutating func next() -> (CGRect, Note)? {
            guard nextX < xLimit else { return nil }

            // Obtain the next note. If it is a sharp, then make sure we replay the `x` value for the next 'white' key
            let note = Note(midiNoteValue: nextMidiNote)
            let advance = note.accented ? 0 : xStride

            // Update sequence values upon exit
            defer {
                nextMidiNote += 1
                nextX += advance
            }

            // The 'black' keys are positioned between the last key and the next 'white' one, and it is
            // not as high
            let xPos = note.accented ? nextX - xStride / 2 : nextX
            let height = note.accented ? self.height * blackKeyHeightScale : self.height

            return (CGRect(x: xPos, y: 0, width: xStride, height: height), note)
        }
    }
}

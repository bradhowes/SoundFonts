// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Visual representation of a piano key. Each key has an associated Note value which determines what MIDI note the key
 will emit when touched.
 */
final class Key: UIView {

    /// If true, audio is muted
    static var isMuted: Bool = false

    /// If true, show note on key
    static var keyLabelOption = KeyLabelOption.savedSetting

    static var keyWidth: CGFloat = CGFloat(settings.keyWidth)

    /// The note to play when touched
    let note: Note

    /// State of the key -- true when touched/pressed
    var pressed: Bool = false {
        didSet {
            if oldValue != pressed {
                self.setNeedsDisplay()
            }
        }
    }

    /**
     Create new Key instance

     - parameter frame: location of the key
     - parameter note: the note that the key playes
     */
    init(frame: CGRect, note: Note) {
        self.note = note
        super.init(frame: frame)
        configure()
    }

    /**
     Regenerate a Key using contents of an NSCoder

     - parameter coder: data container to use
     */
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    /**
     Draw the key. Relies on the KeyboardRender methods to do the work.

     - parameter rect: the region to draw in
     */
    override func draw(_ rect: CGRect) {
        // let roundedCorner: CGFloat = 12.0
        let roundedCorner: CGFloat = (0.1875 * rect.width).rounded()
        if note.accented {
            KeyboardRender.drawBlackKey(keySize: frame.size, roundedCorner: roundedCorner, pressed: pressed,
                                        isMuted: Self.isMuted)
        }
        else {
            let label: String = {
                switch Self.keyLabelOption {
                case .all: return note.label
                case .cOnly where note.midiNoteValue % 12 == 0: return note.label
                default: return ""
                }
            }()

            KeyboardRender.drawWhiteKey(keySize: frame.size, roundedCorner: roundedCorner, pressed: pressed,
                                        isMuted: Self.isMuted, note: label)
        }
    }

    override var description: String { "Key(\(note),\(pressed))" }

    private func configure() {
        self.backgroundColor = .clear
        self.contentMode = .redraw
        self.accessibilityLabel = self.note.label
        self.isAccessibilityElement = true
    }
}

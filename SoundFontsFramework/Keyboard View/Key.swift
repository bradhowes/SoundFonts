// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Visual representation of a piano key. Each key has an associated Note value which determines what MIDI note the key
 will emit when touched.
 */
public final class Key: UIView {

    /// If true, audio is muted
    static var isMuted: Bool = false

    /// How to label the key
    static var keyLabelOption = KeyLabelOption.savedSetting

    static var keyWidth: CGFloat = CGFloat(Settings.shared.keyWidth)

    /// The note to play when touched
    public let note: Note

    /// State of the key -- true when touched/pressed
    public var pressed: Bool = false {
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
    public init(frame: CGRect, note: Note) {
        self.note = note
        super.init(frame: frame)
        configure()
    }

    /**
     Regenerate a Key using contents of an NSCoder

     - parameter coder: data container to use
     */
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    /**
     Draw the key. Relies on the KeyboardRender methods to do the work.

     - parameter rect: the region to draw in
     */
    public override func draw(_ rect: CGRect) {
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

    public override var description: String { "Key(\(note),\(pressed))" }

    private func configure() {
        self.backgroundColor = .clear
        self.contentMode = .redraw
        self.accessibilityLabel = self.note.label
        self.isAccessibilityElement = true
    }
}

extension RandomAccessCollection where Element == Key {

    public func orderedInsertionIndex(for point: CGPoint) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high) / 2)
            let key = self[mid]

            if key.frame.contains(point) {
                low = mid
                break
            }

            if key.frame.midX <= point.x {
                low = index(after: mid)
            }
            else {
                high = mid
            }
        }

        // Don't continue if outside of collection
        guard low < endIndex else { return low }

        // Don't continue if referencing an accented note
        let key = self[low]
        guard !key.note.accented else { return low }

        // Check if following key is accented and has the point
        let next = index(after: low)
        if next != endIndex && self[next].note.accented && self[next].frame.contains(point) { return next }

        // Check if previous key is accented and has the point
        let prev = index(before: low)
        if prev >= startIndex && self[prev].frame.contains(point) { return prev }

        return low
    }

    public func touched(by point: CGPoint) -> Key? {
        let pos = orderedInsertionIndex(for: point)
        return pos < endIndex && self[pos].frame.contains(point) ? self[pos] : nil
    }

    public func keySpan(for rect: CGRect) -> Self.SubSequence {
        let first = orderedInsertionIndex(for: rect.origin)
        let last = orderedInsertionIndex(for: rect.offsetBy(dx: rect.width, dy: 0.0).origin)
        return last == endIndex ? self[first..<last] : self[first...last]
    }
}

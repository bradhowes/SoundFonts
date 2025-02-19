// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/// Visual representation of a piano key. Each key has an associated Note value which determines what MIDI note the key
/// will emit when touched.
final class Key: UIView {

  private let settings: Settings

  /// If true, audio is muted
  static var isMuted: Bool = false

  /// How to label the key
  private var keyLabelOption: KeyLabelOption { KeyLabelOption(rawValue: settings.keyLabelOption) ?? .off }

  /// Current user-adjustable key width from settings
  private var keyWidth: CGFloat { CGFloat(settings.keyWidth) }

  /// The note to play when touched
  let note: Note

  /// State of the key -- true when touched/pressed
   var pressed: Bool = false {
    didSet {
      if oldValue != pressed {
        DispatchQueue.main.async {
          self.setNeedsDisplay()
        }
      }
    }
  }

  /**
   Create new Key instance

   - parameter frame: location of the key
   - parameter note: the note that the key plays
   */
  init(frame: CGRect, note: Note, settings: Settings) {
    self.note = note
    self.settings = settings
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
    let roundedCorner: CGFloat = (0.1875 * rect.width).rounded()
    if note.accented {
      KeyboardRender.drawBlackKey(
        keySize: frame.size, roundedCorner: roundedCorner, pressed: pressed,
        isMuted: Self.isMuted)
    } else {
      let label: String = {
        switch keyLabelOption {
        case .all: return note.label
        case .cOnly where note.midiNoteValue % 12 == 0: return note.label
        default: return ""
        }
      }()

      KeyboardRender.drawWhiteKey(
        keySize: frame.size, roundedCorner: roundedCorner, pressed: pressed,
        isMuted: Self.isMuted, note: label)
    }
  }

  /// Description of Key instance for logging
  override var description: String { "Key(\(note),\(pressed))" }

  private func configure() {
    self.backgroundColor = .clear
    self.contentMode = .redraw
    self.accessibilityLabel = self.note.label
    self.isAccessibilityElement = true
  }
}

extension RandomAccessCollection where Element == Key {

  /**
   Obtain the key that is touched by the given point.

   - parameter point: the location to consider
   - returns: Key instance that contains the point, or nil if none.
   */
  func touched(by point: CGPoint) -> Key? {
    let pos = orderedInsertionIndex(for: point)
    return pos < endIndex && self[pos].frame.contains(point) ? self[pos] : nil
  }

  /**
   Obtain the sequence of keys that fill the given rect. Only considers the horizontal span for inclusion.

   - parameter rect: the region to consider
   - returns: sequence of Key instances that are in the given region
   */
  func keySpan(for rect: CGRect) -> Self.SubSequence {
    let first = orderedInsertionIndex(for: rect.origin)
    let last = orderedInsertionIndex(for: rect.offsetBy(dx: rect.width, dy: 0.0).origin)
    return last == endIndex ? self[first..<last] : self[first...last]
  }

  /**
   Obtain the index of the key in the collection that corresponds to the given position. Performs a binary search to
   locate the right key.

   - parameter point: the location to consider
   - returns: index where to insert
   */
  func orderedInsertionIndex(for point: CGPoint) -> Index {
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
      } else {
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
    if next != endIndex && self[next].note.accented && self[next].frame.contains(point) {
      return next
    }

    // Check if previous key is accented and has the point
    let prev = index(before: low)
    if prev >= startIndex && self[prev].frame.contains(point) { return prev }

    return low
  }
}

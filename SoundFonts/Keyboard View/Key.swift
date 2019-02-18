//
//  Key.swift
//  SoundFonts
//
//  Created by Brad Howes on 11/1/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import UIKit

/**
 Visual representation of a piano key. Each key has an associated Note value which determines what MIDI note the key
 will emit when touched.
 */
final class Key : UIView {

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

    init(frame: CGRect, note: Note) {
        self.note = note
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.note = Note(midiNoteValue: aDecoder.decodeInteger(forKey: "note"))
        super.init(coder: aDecoder)
        configure()
    }

    override func draw(_ rect: CGRect) {
        let roundedCorner: CGFloat = 12.0
      
        if note.accented {
            KeyboardRender.drawBlackKey(keySize: frame.size, roundedCorner: roundedCorner, pressed: pressed)
        }
        else {
            KeyboardRender.drawWhiteKey(keySize: frame.size, roundedCorner: roundedCorner, pressed: pressed)
        }
    }

    override var description: String {
        return "Key(\(note),\(pressed))"
    }

    private func configure() {
        self.backgroundColor = .clear
        self.contentMode = .redraw
    }
}

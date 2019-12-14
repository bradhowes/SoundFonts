// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Provides an editing facility for Favorite instances.
 */
final class FavoriteEditor : UIViewController {

    var favorite: Favorite! = nil
    var position: IndexPath = IndexPath(row: -1, section: -1)
    var currentLowestNote: Note = Note(midiNoteValue: 0)
    var delegate: FavoriteDetailControllerDelegate? = nil

    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var lowestNote: UIButton!
    @IBOutlet weak var lowestNoteStepper: UIStepper!
    @IBOutlet weak var soundFontName: UILabel!
    @IBOutlet weak var patchName: UILabel!
    @IBOutlet weak var bank: UILabel!
    @IBOutlet weak var index: UILabel!
    @IBOutlet weak var gainValue: UILabel!
    @IBOutlet weak var gainSlider: UISlider!
    @IBOutlet weak var panValue: UILabel!
    @IBOutlet weak var panSlider: UISlider!
    
    override var preferredStatusBarStyle : UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        lowestNoteStepper.minimumValue = 0
        lowestNoteStepper.maximumValue = Double(KeyboardController.maxMidiValue)

        gainSlider.minimumValue = -90.0
        gainSlider.maximumValue = 12.0
        
        panSlider.minimumValue = -1.0
        panSlider.maximumValue = 1.0
    }

    override func viewWillAppear(_ animated: Bool) {
        precondition(favorite != nil)
        let soundFontPatch = favorite.soundFontPatch

        name.text = favorite.name
        name.delegate = self

        lowestNote.setTitle(favorite.keyboardLowestNote.label, for: .normal)
        lowestNoteStepper.value = Double(favorite.keyboardLowestNote.midiNoteValue)

        soundFontName.text = soundFontPatch.soundFont.displayName
        patchName.text = soundFontPatch.patch.name
        bank.text = "Bank: \(soundFontPatch.patch.bank)"
        index.text = "Index: \(soundFontPatch.patch.patch)"

        gainValue.text = formatFloat(favorite.gain)
        gainSlider.value = favorite.gain

        panValue.text = formatFloat(favorite.pan)
        panSlider.value = favorite.pan

        super.viewWillAppear(animated)
    }
    
    /**
     Set the Favorite and its index in preparation for editing in the view.

     - parameter favorite: the Favorite instance to edit
     - parameter position: the associated IndexPath for the Favorite instance. Not used internally, but it will be
       conveyed to the delegate in the `dismissed` delegate call.
     */
    func editFavorite(_ favorite: Favorite, position: IndexPath, currentLowestNote: Note) {
        self.favorite = favorite
        self.position = position
        self.currentLowestNote = currentLowestNote
    }
}

// MARK: - UITextFieldDelegate

extension FavoriteEditor: UITextFieldDelegate {

    /**
     Configure name field so that pressing RETURN will exit the editor.

     - parameter textField: the name UITextField to work with
     - returns false
     */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        donePressed(doneButton)
        return false
    }
}

// MARK: - Private

extension FavoriteEditor {

    /**
     Event handler for the `Done` button. Updates the Favorite instance with new values from the editing view.
     
     - parameter sender: the `Done` button
     */
    @IBAction private func donePressed(_ sender: UIBarButtonItem) {
        let newName = self.name.text ?? ""
        if !newName.isEmpty {
            favorite.name = newName
        }
        
        let lowestNoteValue = Int(lowestNoteStepper.value)
        let lowestNote = Note(midiNoteValue: lowestNoteValue)

        favorite.keyboardLowestNote = lowestNote
        favorite.gain = roundFloat(gainSlider.value)
        favorite.pan = roundFloat(panSlider.value)
        
        delegate?.dismissed(position, reason: .done(update: favorite))
    }
    
    /**
     Event handler for the `Cancel` button. Does nothing but asks for the delegate to dismiss the view.
     
     - parameter sender: the `Cancel` button.
     */
    @IBAction private func cancelPressed(_ sender: UIBarButtonItem) {
        favorite = nil
        delegate?.dismissed(position, reason: .cancel)
    }
    
    /**
     Event handler for the lowest key stepper.
     
     - parameter sender: UIStepper control
     */
    @IBAction private func changeLowestKey(_ sender: UIStepper) {
        lowestNote.setTitle(Note(midiNoteValue:  Int(sender.value)).label, for: .normal)
    }
    
    /**
     Event handler for the volume slider
    
     - parameter sender: UISlider
     */
    @IBAction private func volumeChanged(_ sender: UISlider) {
        gainValue.text = formatFloat(sender.value)
    }
    
    /**
     Event handler for the pan slider
     
     - parameter sender: UISlider
     */
    @IBAction private func panChanged(_ sender: UISlider) {
        panValue.text = formatFloat(sender.value)
    }
    
    @IBAction private func useCurrentLowestNote(_ sender: Any) {
        lowestNote.setTitle(currentLowestNote.label, for: .normal)
        lowestNoteStepper.value = Double(currentLowestNote.midiNoteValue)
    }

    /**
     Format a Float value so that it shows only two digits after the decimal point.

     - parameter value: the value to format
     - returns: formatted value
     */
    private func formatFloat(_ value: Float) -> String {
        String(format: "%.2f", locale: Locale.current, arguments: [value])
    }

    /**
     Obtain a rounded value.

     - parameter value: the value to round
     - returns: the rounded result
     */
    private func roundFloat(_ value: Float) -> Float { (value * 100.0).rounded() / 100.0 }
}


// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Provides an editing facility for Favorite instances.
 */
final class FavoriteDetailController : UIViewController {

    var favorite: Favorite? = nil
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
    
    override func viewDidLoad() {
        lowestNoteStepper.minimumValue = 0
        lowestNoteStepper.maximumValue = Double(KeyboardController.maxMidiValue)

        gainSlider.minimumValue = -90.0
        gainSlider.maximumValue = 12.0
        
        panSlider.minimumValue = -1.0
        panSlider.maximumValue = 1.0
    }

    /**
     Set the Favorite and its index in preparation for editing in the view.
    
     - parameter favorite: the Favorite instance to edit
     - parameter position: the associated IndexPath for the Favorite instance. Not used internally, but it will be
       conveyed to the delegate in the `dismissed` delegate call.
     */
    func editFavorite(_ favorite: Favorite, position: IndexPath, lowestNote: Note) {
        self.favorite = favorite
        self.position = position
        self.currentLowestNote = lowestNote
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        precondition(favorite != nil)
        guard let favorite = self.favorite else { return }
        let patch = favorite.patch

        name.text = favorite.name
        lowestNote.setTitle(favorite.keyboardLowestNote.label, for: .normal)
        lowestNoteStepper.value = Double(favorite.keyboardLowestNote.midiNoteValue)
        title = favorite.name
        soundFontName.text = patch.soundFont.displayName
        patchName.text = patch.name
        bank.text = "Bank: \(patch.bank)"
        index.text = "Index: \(patch.index)"
        gainValue.text = formatFloat(favorite.gain)
        gainSlider.value = favorite.gain
        panValue.text = formatFloat(favorite.pan)
        panSlider.value = favorite.pan

        super.viewWillAppear(animated)
    }
    
    /**
     Event handler for the `Done` button. Updates the Favorite instance with new values from the editing view.
     
     - parameter sender: the `Done` button
     */
    @IBAction private func donePressed(_ sender: UIBarButtonItem) {
        guard let favorite = favorite else { return }
        
        self.favorite = nil
        let newName = self.name.text ?? ""
        if !newName.isEmpty {
            favorite.name = newName
        }
        
        let lowestNoteValue = Int(lowestNoteStepper.value)
        let lowestNote = Note(midiNoteValue: lowestNoteValue)
        favorite.keyboardLowestNote = lowestNote
        favorite.gain = roundFloat(gainSlider.value)
        favorite.pan = roundFloat(panSlider.value)
        
        delegate?.dismissed(position, reason: .done)
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
        let newValue = Int(sender.value)
        let newNote = Note(midiNoteValue: newValue)
        lowestNote.setTitle(newNote.label, for: .normal)
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
    @IBAction func panChanged(_ sender: UISlider) {
        panValue.text = formatFloat(sender.value)
    }
    
    /**
     Format a Float value so that it shows only two digits after the decimal point.
    
     - parameter value: the value to format
     - returns: formatted value
     */
    private func formatFloat(_ value: Float) -> String {
        return String(format: "%.2f", locale: Locale.current, arguments: [value])
    }

    /**
     Obtain a rounded value.
    
     - parameter value: the value to round
     - returns: the rounded result
     */
    private func roundFloat(_ value: Float) -> Float {
        return (value * 100.0).rounded() / 100.0
    }
    
    @IBAction func useCurrentLowestNote(_ sender: Any) {
        lowestNote.setTitle(currentLowestNote.label, for: .normal)
        lowestNoteStepper.value = Double(currentLowestNote.midiNoteValue)
    }
    
    @IBAction func deleteFavorite(_ sender: Any) {
        let alertController = UIAlertController(title: "Confirm Delete", message: "Deleting the favorite cannot be undone.",
                                   preferredStyle: .actionSheet)
        let delete = UIAlertAction(title: "Delete", style:.destructive) { action in
            self.favorite = nil
            self.delegate?.dismissed(self.position, reason: .delete)
        }

        let cancel = UIAlertAction(title: "Cancel", style:.cancel) { action in
        }
        
        alertController.addAction(delete)
        alertController.addAction(cancel)
        
        if let popoverController = alertController.popoverPresentationController {
          popoverController.sourceView = self.view
          popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
          popoverController.permittedArrowDirections = []
        }

        self.present(alertController, animated: true, completion: nil)
    }
}

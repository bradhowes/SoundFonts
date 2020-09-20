// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Provides an editing facility for Favorite instances.
 */
final public class FavoriteEditor: UIViewController {

    public struct Config {
        let indexPath: IndexPath
        let view: UIView
        let rect: CGRect
        let favorite: LegacyFavorite
        let currentLowestNote: Note?
        let completionHandler: UIContextualAction.CompletionHandler?
        let soundFont: LegacySoundFont
        let patch: LegacyPatch
    }

    private var favorite: LegacyFavorite! = nil
    private var position: IndexPath = IndexPath(row: -1, section: -1)
    private var currentLowestNote: Note?
    private var completionHandler: UIContextualAction.CompletionHandler?
    private var soundFont: LegacySoundFont?
    private var patch: LegacyPatch?

    weak var delegate: FavoriteEditorDelegate?

    override public var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var lowestNoteCollection: UIStackView!
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

    func configure(_ config: Config) {
        self.favorite = config.favorite
        self.position = config.indexPath
        self.currentLowestNote = config.currentLowestNote
        self.completionHandler = config.completionHandler
        self.soundFont = config.soundFont
        self.patch = config.patch
    }

    override public func viewDidLoad() {
        lowestNoteStepper.minimumValue = 0
        lowestNoteStepper.maximumValue = Double(Sampler.maxMidiValue)

        gainSlider.minimumValue = -90.0
        gainSlider.maximumValue = 12.0

        panSlider.minimumValue = -1.0
        panSlider.maximumValue = 1.0
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        precondition(favorite != nil)

        name.text = favorite.name
        name.delegate = self

        if let currentLowestNote = self.currentLowestNote {
            lowestNoteCollection.isHidden = false
            lowestNote.setTitle(currentLowestNote.label, for: .normal)
            lowestNoteStepper.value = Double(currentLowestNote.midiNoteValue)
        }
        else {
            lowestNoteCollection.isHidden = true
        }

        soundFontName.text = soundFont?.displayName
        patchName.text = patch?.name
        bank.text = "Bank: \(patch!.bank)"
        index.text = "Index: \(patch!.program)"

        gainValue.text = formatFloat(favorite.gain)
        gainSlider.value = favorite.gain

        panValue.text = formatFloat(favorite.pan)
        panSlider.value = favorite.pan

        preferredContentSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}

// MARK: - UITextFieldDelegate

extension FavoriteEditor: UITextFieldDelegate {

    /**
     Configure name field so that pressing RETURN will exit the editor.

     - parameter textField: the name UITextField to work with
     - returns: false
     */
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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

        AskForReview.maybe()
        delegate?.dismissed(position, reason: .done(update: favorite))
        completionHandler?(true)
    }

    /**
     Event handler for the `Cancel` button. Does nothing but asks for the delegate to dismiss the view.
     
     - parameter sender: the `Cancel` button.
     */
    @IBAction private func cancelPressed(_ sender: UIBarButtonItem) {
        favorite = nil
        AskForReview.maybe()
        delegate?.dismissed(position, reason: .cancel)
        completionHandler?(false)
    }

    /**
     Event handler for the lowest key stepper.
     
     - parameter sender: UIStepper control
     */
    @IBAction private func changeLowestKey(_ sender: UIStepper) {
        lowestNote.setTitle(Note(midiNoteValue: Int(sender.value)).label, for: .normal)
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
        guard let currentLowestNote = self.currentLowestNote else { return }
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

extension FavoriteEditor: UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate {

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        donePressed(doneButton)
    }

    /**
     Treat touches outside of the popover as a signal to dismiss via Dones button

     - parameter popoverPresentationController: the controller being monitored
     */
    public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        donePressed(doneButton)
    }
}

// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/**
 Provides an editing facility for SoundFont names.
 */
final class FontEditor: UIViewController {

    var soundFont: SoundFont!
    var favoriteCount: Int = 0
    var position: IndexPath = IndexPath()
    weak var delegate: FontEditorDelegate?

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var originalNameLabel: UILabel!
    @IBOutlet weak var embeddedNameLabel: UILabel!
    @IBOutlet weak var patchCountLabel: UILabel!
    @IBOutlet weak var favoriteCountLabel: UILabel!

    /**
     Set the SoundFont and its index in preparation for editing in the view.
    
     - parameter soundFont: the SoundFont instance to edit
     - parameter favoriteCount: number of favorites associated with this soundFont
     - parameter position: the associated IndexPath for the Favorite instance. Not used internally, but it will be
       conveyed to the delegate in the `dismissed` delegate call.
     */
    func edit(soundFont: SoundFont, favoriteCount: Int, position: IndexPath) {
        self.soundFont = soundFont
        self.favoriteCount = favoriteCount
        self.position = position
    }

    override func viewWillAppear(_ animated: Bool) {
        guard let soundFont = self.soundFont else { fatalError() }
        name.text = soundFont.displayName
        name.delegate = self
        originalNameLabel.text = soundFont.originalDisplayName
        embeddedNameLabel.text = soundFont.embeddedName
        patchCountLabel.text = Formatters.formatted(patchCount: soundFont.patches.count)
        favoriteCountLabel.text = Formatters.formatted(favoriteCount: favoriteCount)
        super.viewWillAppear(animated)
    }

    /**
     Event handler for the `Done` button. Updates the SoundFont instance with new title from the editing view.
     
     - parameter sender: the `Done` button
     */
    @IBAction private func donePressed(_ sender: UIBarButtonItem) {
        let newName = self.name.text ?? ""
        if !newName.isEmpty {
            soundFont.displayName = newName
        }

        delegate?.dismissed(reason: .done(index: position.row, soundFont: soundFont))
    }

    /**
     Event handler for the `Cancel` button. Does nothing but asks for the delegate to dismiss the view.
     
     - parameter sender: the `Cancel` button.
     */
    @IBAction private func cancelPressed(_ sender: UIBarButtonItem) {
        delegate?.dismissed(reason: .cancel)
    }
}

extension FontEditor: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        donePressed(doneButton)
        return true
    }
}

// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/**
 Provides an editing facility for SoundFont names.
 */
final class FontEditor : UIViewController {

    var soundFont: SoundFont!
    var favoriteCount: Int = 0
    var position: IndexPath = IndexPath()
    var delegate: SoundFontDetailControllerDelegate? = nil

    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var originalNameLabel: UILabel!
    @IBOutlet weak var patchCountLabel: UILabel!
    @IBOutlet weak var favoriteCountLabel: UILabel!

    /**
     Set the SoundFont and its index in preparation for editing in the view.
    
     - parameter favorite: the Favorite instance to edit
     - parameter position: the associated IndexPath for the Favorite instance. Not used internally, but it will be
       conveyed to the delegate in the `dismissed` delegate call.
     */
    func edit(soundFont: SoundFont, favoriteCount: Int, position: IndexPath) {
        self.soundFont = soundFont
        self.favoriteCount = favoriteCount
        self.position = position
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        guard let soundFont = self.soundFont else { fatalError() }
        name.text = soundFont.displayName
        name.delegate = self
        originalNameLabel.text = soundFont.originalDisplayName
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
        delegate?.dismissed(reason: .done(index: position.row, name: newName))
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

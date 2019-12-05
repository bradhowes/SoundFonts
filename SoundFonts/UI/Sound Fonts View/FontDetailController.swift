// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/**
 Provides an editing facility for SoundFont names.
 */
final class FontDetailController : UIViewController {

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
        title = soundFont.displayName
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
        guard let soundFont = soundFont else { fatalError() }
        let newName = self.name.text ?? ""
        if !newName.isEmpty {
            soundFont.displayName = newName
        }
        delegate?.dismissed(reason: .done(indexPath: position, soundFont: soundFont))
    }
    
    /**
     Event handler for the `Cancel` button. Does nothing but asks for the delegate to dismiss the view.
     
     - parameter sender: the `Cancel` button.
     */
    @IBAction private func cancelPressed(_ sender: UIBarButtonItem) {
        delegate?.dismissed(reason: .cancel)
    }
    
    @IBAction func deleteSoundFont(_ sender: Any) {
        let alertController = UIAlertController(title: "Confirm Delete", message: "Deleting the SoundFont cannot be undone.",
                                   preferredStyle: .actionSheet)
        let delete = UIAlertAction(title: "Delete", style:.destructive) { action in
            self.delegate?.dismissed(reason: .delete(indexPath: self.position, soundFont: self.soundFont))
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

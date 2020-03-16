// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/**
 Provides an editing facility for SoundFont names.
 */
final class FontEditor: UIViewController {

    public struct Config {
        let indexPath: IndexPath
        let view: UIView
        let rect: CGRect
        let soundFont: SoundFont
        let favoriteCount: Int
        let completionHandler: UIContextualAction.CompletionHandler?
    }

    private var soundFont: SoundFont!
    private var favoriteCount: Int = 0
    private var position: IndexPath = IndexPath()
    private var completionHandler: UIContextualAction.CompletionHandler?

    weak var delegate: FontEditorDelegate?

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var originalNameLabel: UILabel!
    @IBOutlet weak var embeddedNameLabel: UILabel!
    @IBOutlet weak var patchCountLabel: UILabel!
    @IBOutlet weak var favoriteCountLabel: UILabel!

    func configure(_ config: Config) {
        self.position = config.indexPath
        self.soundFont = config.soundFont
        self.favoriteCount = config.favoriteCount
        self.completionHandler = config.completionHandler
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let soundFont = self.soundFont else { fatalError() }
        name.text = soundFont.displayName
        name.delegate = self
        originalNameLabel.text = soundFont.originalDisplayName
        embeddedNameLabel.text = soundFont.embeddedName
        patchCountLabel.text = Formatters.formatted(patchCount: soundFont.patches.count)
        favoriteCountLabel.text = Formatters.formatted(favoriteCount: favoriteCount)

        preferredContentSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
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

        AskForReview.maybe()
        delegate?.dismissed(reason: .done(index: position.row, soundFont: soundFont))
        completionHandler?(true)
    }

    /**
     Event handler for the `Cancel` button. Does nothing but asks for the delegate to dismiss the view.
     
     - parameter sender: the `Cancel` button.
     */
    @IBAction private func cancelPressed(_ sender: UIBarButtonItem) {
        AskForReview.maybe()
        delegate?.dismissed(reason: .cancel)
        completionHandler?(false)
    }
}

extension FontEditor: UITextFieldDelegate {

    /**
     Since the font editor only has this one field, treat a RETURN on the keyboard as clicking on Done

     - parameter textField: the text field being monitored
     - returns: always true
     */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        donePressed(doneButton)
        return true
    }
}

extension FontEditor: UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate {

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        donePressed(doneButton)
    }

    /**
     Treat touches outside of the popover as a signal to dismiss via Done button

     - parameter popoverPresentationController: the controller being monitored
     */
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        donePressed(doneButton)
    }
}


// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/**
 Provides an editing facility for SoundFont meta-data and tags.
 */
final class FontEditor: UIViewController {

    /**
     A Config instance communicates values for the editor to use to do its job. It is setup during the segue that will
     show the editor.
     */
    public struct Config {
        /// The index of the sound font entry being edited
        let indexPath: IndexPath
        /// The cell view that holds the sound font entry
        let view: UIView
        /// The rect to use for presenting
        let rect: CGRect
        /// The collection of all sound fonts
        let soundFonts: SoundFonts
        /// The unique key for the sound font being edited
        let soundFontKey: LegacySoundFont.Key
        /// The number of favorites associated with the sound font being edited
        let favoriteCount: Int
        /// The tags assigned to this sound font
        let tags: Tags
        /// The function to call when dismissing the editor. Sole parameter indicates if an activity was completed.
        let completionHandler: ((Bool) -> Void)?
    }

    private var config: Config!
    private var activeTags = Set<LegacyTag.Key>()

    weak var delegate: FontEditorDelegate?

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var doneButton: UIBarButtonItem!
    @IBOutlet private weak var name: UITextField!
    @IBOutlet private weak var tagsLabel: UILabel!
    @IBOutlet private weak var tagsEdit: UIButton!
    @IBOutlet private weak var originalNameLabel: UILabel!
    @IBOutlet private weak var embeddedNameLabel: UILabel!
    @IBOutlet private weak var kindLabel: UILabel!
    @IBOutlet private weak var presetsCountLabel: UILabel!
    @IBOutlet private weak var favoritesCountLabel: UILabel!
    @IBOutlet private weak var hiddenCountLabel: UILabel!
    @IBOutlet private weak var resetVisibilityButton: UIButton!
    @IBOutlet private weak var embeddedComment: UILabel!
    @IBOutlet private weak var embeddedCopyright: UILabel!
    @IBOutlet private weak var embeddedAuthor: UILabel!
    @IBOutlet private weak var path: UILabel!

    private var textFieldKeyboardMonitor: TextFieldKeyboardMonitor!

    private var soundFont: LegacySoundFont {
        guard let soundFont = config.soundFonts.getBy(key: config.soundFontKey) else { fatalError() }
        return soundFont
    }
}

extension FontEditor {

    /**
     Set the configuration for the editor.
     */
    func configure(_ config: Config) {
        self.config = config
        config.soundFonts.reloadEmbeddedInfo(key: config.soundFontKey)
        activeTags = soundFont.tags
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let soundFont = self.soundFont
        name.text = soundFont.displayName
        name.delegate = self
        originalNameLabel.text = soundFont.originalDisplayName
        embeddedNameLabel.text = soundFont.embeddedName
        embeddedComment.text = soundFont.embeddedComment
        embeddedAuthor.text = soundFont.embeddedAuthor
        embeddedCopyright.text = soundFont.embeddedCopyright

        kindLabel.text = {
            switch soundFont.kind {
            case .builtin: return "app resource"
            case .installed: return "file copy"
            case .reference: return "file reference"
            }
        }()

        presetsCountLabel.text = Formatters.format(presetCount: soundFont.patches.count)
        favoritesCountLabel.text = Formatters.format(favoriteCount: config.favoriteCount)

        updateHiddenCount()

        path.text = "Path: " + soundFont.fileURL.path
        let value = config.tags.names(of: activeTags).joined(separator: ", ")
        tagsLabel.text = value

        textFieldKeyboardMonitor = TextFieldKeyboardMonitor(view: view, scrollView: scrollView)
    }
}

extension FontEditor {

    @IBAction private func close(_ sender: UIBarButtonItem) {
        if let soundFont = config.soundFonts.getBy(key: config.soundFontKey) {
            let newName = name.text ?? ""
            if !newName.isEmpty {
                soundFont.displayName = newName
            }
            soundFont.tags = activeTags
            delegate?.dismissed(reason: .done(soundFontKey: config.soundFontKey))
        }

        self.dismiss(animated: true)
        config.completionHandler?(true)
        AskForReview.maybe()
    }

    @IBAction private func makeAllVisible(_ sender: UIButton) {
        config.soundFonts.makeAllVisible(key: config.soundFontKey)
        updateHiddenCount()
    }

    @IBAction func copyOriginalName(_ sender: Any) { name.text = originalNameLabel.text }

    @IBAction func copyEmbeddedName(_ sender: Any) { name.text = embeddedNameLabel.text }
}

extension FontEditor: UITextFieldDelegate {

    /**
     Notification that user wishes to interact with a text field. Keep it visible.
     */
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textFieldKeyboardMonitor.viewToKeepVisible = textField
        return true
    }

    /**
     Notification that the user has hit a "return" key. Stop editing in the field.
     */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    /**
     Notification that editing in a text field is coming to an end
     */
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textFieldKeyboardMonitor.viewToKeepVisible = nil
        return true
    }
}

extension FontEditor: UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate {

    /**
     Notification that the font editor is being dismissed. Treat as a close.
     */
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        close(doneButton)
    }

    /**
     Notification that the font editor is being dismissed. Treat as a close.
     */
    func popoverPresentationControllerDidDismissPopover(
        _ popoverPresentationController: UIPopoverPresentationController) {
        close(doneButton)
    }
}

extension FontEditor: SegueHandler {

    /// Segues available from this view controller. A SegueHandler protocol requirement.
    public enum SegueIdentifier: String {
        /// Tag editor
        case tagsEdit
    }

    /**
     User wishes to edit the collection of tags assigned to the sound font.

     - parameter segue: the segue to be performed
     - parameter sender: the origin of the segue request
     */
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .tagsEdit: prepareToEdit(segue)
        }
    }
}

extension FontEditor {

    private func updateHiddenCount() {
        let hiddenCount = soundFont.patches.filter { $0.presetConfig.isHidden ?? false }.count
        if hiddenCount > 0 {
            hiddenCountLabel.text = "\(hiddenCount) hidden"
            resetVisibilityButton.isHidden = false
        }
        else {
            hiddenCountLabel.text = ""
            resetVisibilityButton.isHidden = true
        }
    }

    private func prepareToEdit(_ segue: UIStoryboardSegue) {
        guard let viewController = segue.destination as? TagsTableViewController else {
            fatalError("unexpected view configuration")
        }

        let config = TagsTableViewController.Config(tags: self.config.tags, active: activeTags) { tags in
            self.activeTags = tags
        }

        viewController.configure(config)
    }
}

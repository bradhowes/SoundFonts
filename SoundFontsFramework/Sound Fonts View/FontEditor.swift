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
        let soundFonts: SoundFonts
        let soundFontKey: LegacySoundFont.Key
        let favoriteCount: Int
        let tags: Tags
        let completionHandler: ((Bool) -> Void)?
    }

    private var soundFonts: SoundFonts!
    private var soundFontKey: LegacySoundFont.Key!
    private var favoriteCount: Int = 0
    private var position: IndexPath = IndexPath()
    private var tags: Tags!
    private var activeTags = Set<LegacyTag.Key>()

    private var completionHandler: ((Bool) -> Void)?

    weak var delegate: FontEditorDelegate?

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    @IBOutlet weak var scrollView: UIScrollView!
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

    func configure(_ config: Config) {
        position = config.indexPath
        soundFonts = config.soundFonts
        soundFontKey = config.soundFontKey
        favoriteCount = config.favoriteCount
        tags = config.tags
        completionHandler = config.completionHandler

        soundFonts.reloadEmbeddedInfo(key: soundFontKey)

        guard let soundFont = soundFonts.getBy(key: soundFontKey) else { fatalError() }
        activeTags = soundFont.tags
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let soundFont = soundFonts.getBy(key: soundFontKey) else { fatalError() }
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

        presetsCountLabel.text = Formatters.formatted(presetCount: soundFont.patches.count)
        favoritesCountLabel.text = Formatters.formatted(favoriteCount: favoriteCount)

        updateHiddenCount()

        path.text = "Path: " + soundFont.fileURL.path
        let value = tags.names(of: activeTags).joined(separator: ", ")
        tagsLabel.text = value

        textFieldKeyboardMonitor = TextFieldKeyboardMonitor(view: view, scrollView: scrollView)
    }

    private func updateHiddenCount() {
        guard let soundFont = soundFonts.getBy(key: soundFontKey) else { fatalError() }
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

    @IBAction private func close(_ sender: UIBarButtonItem) {
        if let soundFont = soundFonts.getBy(key: soundFontKey) {
            let newName = name.text ?? ""
            if !newName.isEmpty {
                soundFont.displayName = newName
            }
            soundFont.tags = activeTags
            delegate?.dismissed(reason: .done(soundFontKey: soundFontKey))
        }

        self.dismiss(animated: true)
        completionHandler?(true)
        AskForReview.maybe()
    }

    @IBAction private func makeAllVisible(_ sender: UIButton) {
        soundFonts.makeAllVisible(key: soundFontKey)
        updateHiddenCount()
    }

    @IBAction func copyOriginalName(_ sender: Any) {
        name.text = originalNameLabel.text
    }

    @IBAction func copyEmbeddedName(_ sender: Any) {
        name.text = embeddedNameLabel.text
    }
}

extension FontEditor: UITextFieldDelegate {

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textFieldKeyboardMonitor.viewToKeepVisible = textField
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textFieldKeyboardMonitor.viewToKeepVisible = nil
        return true
    }
}

extension FontEditor: UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        close(doneButton)
    }

    func popoverPresentationControllerDidDismissPopover(
        _ popoverPresentationController: UIPopoverPresentationController) {
        close(doneButton)
    }
}

extension FontEditor: SegueHandler {

    public enum SegueIdentifier: String {
        case tagsEdit
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .tagsEdit: prepareToEdit(segue)
        }
    }

    private func prepareToEdit(_ segue: UIStoryboardSegue) {
        guard let viewController = segue.destination as? TagsTableViewController else {
            fatalError("unexpected view configuration")
        }

        let config = TagsTableViewController.Config(tags: tags, active: activeTags) { tags in
            self.activeTags = tags
        }

        viewController.configure(config)
    }
}

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
        let completionHandler: ((Bool) -> Void)?
    }

    private var soundFonts: SoundFonts!
    private var soundFontKey: LegacySoundFont.Key!
    private var favoriteCount: Int = 0
    private var position: IndexPath = IndexPath()
    private var completionHandler: ((Bool) -> Void)?

    weak var delegate: FontEditorDelegate?

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    @IBOutlet private weak var doneButton: UIBarButtonItem!
    @IBOutlet private weak var name: UITextField!
    @IBOutlet private weak var tags: UILabel!
    @IBOutlet private weak var tagsEdit: UIButton!
    @IBOutlet private weak var originalNameLabel: UILabel!
    @IBOutlet private weak var embeddedNameLabel: UILabel!
    @IBOutlet private weak var kindLabel: UILabel!
    @IBOutlet private weak var presetsCountLabel: UILabel!
    @IBOutlet private weak var favoritesCountLabel: UILabel!
    @IBOutlet private weak var hiddenCountLabel: UILabel!
    @IBOutlet private weak var resetVisibilityButton: UIButton!
    @IBOutlet private weak var path: UILabel!

    func configure(_ config: Config) {
        self.position = config.indexPath
        self.soundFonts = config.soundFonts
        self.soundFontKey = config.soundFontKey
        self.favoriteCount = config.favoriteCount
        self.completionHandler = config.completionHandler
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let soundFont = soundFonts.getBy(key: soundFontKey) else { fatalError() }
        name.text = soundFont.displayName
        name.delegate = self
        originalNameLabel.text = soundFont.originalDisplayName
        embeddedNameLabel.text = soundFont.embeddedName
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

        preferredContentSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    private func updateHiddenCount() {
        guard let soundFont = soundFonts.getBy(key: soundFontKey) else { fatalError() }
        let hiddenCount = soundFont.patches.filter { $0.isVisible == false}.count
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
            delegate?.dismissed(reason: .done(index: position.row, soundFont: soundFont))
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

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        close(doneButton)
        return true
    }
}

extension FontEditor: UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        close(doneButton)
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        close(doneButton)
    }
}

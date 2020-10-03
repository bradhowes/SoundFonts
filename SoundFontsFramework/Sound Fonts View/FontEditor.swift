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
        let soundFont: LegacySoundFont
        let favoriteCount: Int
        let completionHandler: ((Bool) -> Void)?
    }

    private var soundFont: LegacySoundFont!
    private var favoriteCount: Int = 0
    private var position: IndexPath = IndexPath()
    private var completionHandler: ((Bool) -> Void)?

    weak var delegate: FontEditorDelegate?

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    @IBOutlet private weak var doneButton: UIBarButtonItem!
    @IBOutlet private weak var name: UITextField!
    @IBOutlet private weak var originalNameLabel: UILabel!
    @IBOutlet private weak var embeddedNameLabel: UILabel!
    @IBOutlet private weak var presetsCountLabel: UILabel!
    @IBOutlet private weak var favoritesCountLabel: UILabel!
    @IBOutlet private weak var hiddenCountLabel: UILabel!
    @IBOutlet private weak var resetVisibilityButton: UIButton!

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
        originalNameLabel.text = "Original: \(soundFont.originalDisplayName)"
        embeddedNameLabel.text = "Embedded: \(soundFont.embeddedName)"
        presetsCountLabel.text = Formatters.formatted(presetCount: soundFont.patches.count)
        favoritesCountLabel.text = Formatters.formatted(favoriteCount: favoriteCount)
        hiddenCountLabel.text = "\(soundFont.patches.filter { $0.isVisible == false}.count) hidden"

        preferredContentSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    @IBAction private func close(_ sender: UIBarButtonItem) {
        let newName = self.name.text ?? ""
        if !newName.isEmpty { soundFont.displayName = newName }
        self.dismiss(animated: true)
        delegate?.dismissed(reason: .done(index: position.row, soundFont: soundFont))
        completionHandler?(true)
        AskForReview.maybe()
    }

    @IBAction private func makeAllVisible(_ sender: UIButton) {
        let newName = self.name.text ?? ""
        if !newName.isEmpty { soundFont.displayName = newName }
        self.dismiss(animated: true)
        delegate?.dismissed(reason: .done(index: position.row, soundFont: soundFont))
        completionHandler?(true)
        AskForReview.maybe()
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
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) { close(doneButton) }
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) { close(doneButton) }
}

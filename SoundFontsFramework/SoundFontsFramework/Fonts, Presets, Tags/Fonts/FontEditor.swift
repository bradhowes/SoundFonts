// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/// Provides an editing facility for SoundFont meta-data and tags.
final class FontEditor: UIViewController {

  /**
   A Config instance communicates values for the editor to use to do its job. It is setup during the segue that will
   show the editor.
   */
  struct Config {
    /// The index of the sound font entry being edited
    let indexPath: IndexPath
    /// The cell view that holds the sound font entry
    let view: UIView
    /// The rect to use for presenting
    let rect: CGRect
    /// The collection of all sound fonts
    let soundFonts: SoundFontsProvider
    /// The unique key for the sound font being edited
    let soundFontKey: SoundFont.Key
    /// The number of favorites associated with the sound font being edited
    let favoriteCount: Int
    /// The collection of known tags
    let tags: TagsProvider
    /// The function to call when dismissing the editor. Sole parameter indicates if an activity was completed.
    let completionHandler: ((Bool) -> Void)?
  }

  private var config: Config!
  private var activeTags = Set<Tag.Key>()

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

  private var soundFont: SoundFont {
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
    // Don't show the stock tags that don't make sense for the user to change
    activeTags = soundFont.tags.subtracting(Tag.stockTagSet)
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

    presetsCountLabel.text = Formatters.format(presetCount: soundFont.presets.count)
    favoritesCountLabel.text = Formatters.format(favoriteCount: config.favoriteCount)

    updateHiddenCount()

    path.text = "Path: " + soundFont.fileURL.path
    let value = config.tags.names(of: activeTags).sorted().joined(separator: ", ")
    tagsLabel.text = value

    textFieldKeyboardMonitor = TextFieldKeyboardMonitor(view: view, scrollView: scrollView)
  }
}

extension FontEditor: UITextFieldDelegate {

  /**
   Notification that user wishes to interact with a text field. Keep it visible.
   */
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
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
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
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
  enum SegueIdentifier: String {
    /// Tag editor
    case tagsEdit
  }

  /**
   User wishes to edit the collection of tags assigned to the sound font.

   - parameter segue: the segue to be performed
   - parameter sender: the origin of the segue request
   */
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segueIdentifier(for: segue) {
    case .tagsEdit: prepareToEdit(segue)
    }
  }
}

private extension FontEditor {

  @IBAction func close(_ sender: UIBarButtonItem) {
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

  @IBAction func makeAllVisible(_ sender: UIButton) {
    config.soundFonts.makeAllVisible(key: config.soundFontKey)
    updateHiddenCount()
  }

  @IBAction func copyOriginalName(_ sender: Any) { name.text = originalNameLabel.text }

  @IBAction func copyEmbeddedName(_ sender: Any) { name.text = embeddedNameLabel.text }

  func updateHiddenCount() {
    let hiddenCount = soundFont.presets.filter { $0.presetConfig.isHidden ?? false }.count
    if hiddenCount > 0 {
      hiddenCountLabel.text = "\(hiddenCount) hidden"
      resetVisibilityButton.isHidden = false
    } else {
      hiddenCountLabel.text = ""
      resetVisibilityButton.isHidden = true
    }
  }

  func prepareToEdit(_ segue: UIStoryboardSegue) {
    guard let viewController = segue.destination as? TagsEditorTableViewController else {
      fatalError("unexpected controller relationships")
    }

    let config = TagsEditorTableViewController.Config(tags: self.config.tags, active: activeTags,
                                                      builtIn: soundFont.kind.builtin) { [weak self] tags in
      self?.activeTags = tags
    }

    viewController.configure(config)
  }
}

// Copyright © 2018 Brad Howes. All rights reserved.

import UniformTypeIdentifiers
import UIKit
import os

/**
 View controller for the SoundFont / Presets UITableView combination. Much of the UITableView management is handled
 by embedded view controllers. This controller mainly serves to manage the active preset state, plus the switching
 between normal preset table view display and preset search results display. Apart from the adopted protocols, there
 is no API for this class.
 */
final class SoundFontsViewController: UIViewController {
  private lazy var log = Logging.logger("SoundFontsViewController")

  @IBOutlet private weak var fontsView: UIView!
  @IBOutlet private weak var presetsView: UIView!
  @IBOutlet private weak var tagsViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet private weak var tagsBottomConstraint: NSLayoutConstraint!
  @IBOutlet private weak var dividerControl: UIView!
  @IBOutlet private weak var presetsWidthConstraint: NSLayoutConstraint!

  private weak var fontsTableViewController: FontsTableViewController!
  private weak var presetsTableViewController: PresetsTableViewController!
  private weak var tagsTableViewController: TagsTableViewController!

  private var maxTagsViewHeightConstraint: CGFloat = 0.0
  private var soundFonts: SoundFontsProvider!
  private var favorites: FavoritesProvider!
  private var infoBar: AnyInfoBar!
  private var tags: TagsProvider!
  private var settings: Settings!

  private var selectedSoundFontManager: SelectedSoundFontManager!
  private var activeTagManager: ActiveTagManager!
  private var keyboard: AnyKeyboard?
  private var tagsVisibilityManager: TagsVisibilityManager!

  private var dividerDragGesture = UIPanGestureRecognizer()
  private var lastDividerPos: CGFloat = .zero

  let swipeLeft = UISwipeGestureRecognizer()
  let swipeRight = UISwipeGestureRecognizer()
}

extension SoundFontsViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    fontsView.isAccessibilityElement = false
    fontsView.accessibilityIdentifier = "FontsTableList"
    fontsView.accessibilityHint = "List of available fonts"
    fontsView.accessibilityLabel = "FontsTableList"

    presetsView.isAccessibilityElement = false
    presetsView.accessibilityIdentifier = "PresetsTableList"
    presetsView.accessibilityHint = "List of presets in selected font"
    presetsView.accessibilityLabel = "PresetTableList"

    swipeLeft.direction = .left
    swipeLeft.numberOfTouchesRequired = 2
    view.addGestureRecognizer(swipeLeft)

    swipeRight.direction = .right
    swipeRight.numberOfTouchesRequired = 2
    view.addGestureRecognizer(swipeRight)

    maxTagsViewHeightConstraint = tagsViewHeightConstraint.constant

    dividerDragGesture.maximumNumberOfTouches = 1
    dividerDragGesture.minimumNumberOfTouches = 1
    dividerDragGesture.addTarget(self, action: #selector(moveDivider(_:)))
    dividerControl.addGestureRecognizer(dividerDragGesture)
  }

  @objc func moveDivider(_ gesture: UIPanGestureRecognizer) {
    switch gesture.state {
    case .began:
      os_log(.debug, log: log, "moveDivider - BEGIN")
      lastDividerPos = gesture.location(in: view).x

    case .changed:
      os_log(.debug, log: log, "moveDivider - CHANGED")
      let pos = gesture.location(in: self.view)
      let change = CGFloat(Int(pos.x - lastDividerPos))
      guard abs(change) > 0 else { return }

      os_log(.debug, log: log, "moveDivider - CHANGE: %f", change)
      lastDividerPos += change
      gesture.setTranslation(.zero, in: view)

      let presetsWidth = presetsView.frame.width - change

      // Don't allow the preset view to shrink below 80 but do let it grow if it was below 80.
      if presetsWidth < 80.0 && change > 0 { return }

      let fontsWidth = fontsView.frame.width + change

      // Likewise, don't allow the fonts view to shrink below 80 but do let it grow if it was below 80.
      if fontsWidth < 80.0 && change < 0 { return }

      let multiplier = presetsWidth / fontsWidth
      os_log(
        .debug, log: log, "moveDivider - old: %f new: %f",
        presetsWidthConstraint.multiplier,
        multiplier)
      presetsWidthConstraint = presetsWidthConstraint.setMultiplier(multiplier)
      settings.presetsWidthMultiplier = Double(multiplier)

    default: break
    }
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    if tagsVisibilityManager.showingTags {
      tagsVisibilityManager.hideTags()
    }
  }
}

extension SoundFontsViewController: UIDocumentPickerDelegate {

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    os_log(.debug, log: log, "documentPicker didPickDocumentAt")
    addSoundFonts(urls: urls)
  }
}

// MARK: - ControllerConfiguration Protocol

extension SoundFontsViewController: ControllerConfiguration {

  func establishConnections(_ router: ComponentContainer) {
    settings = router.settings
    soundFonts = router.soundFonts
    favorites = router.favorites
    keyboard = router.keyboard
    selectedSoundFontManager = router.selectedSoundFontManager
    infoBar = router.infoBar
    tags = router.tags

    let multiplier = settings.presetsWidthMultiplier
    presetsWidthConstraint = presetsWidthConstraint.setMultiplier(CGFloat(multiplier))

    router.infoBar.addEventClosure(.addSoundFont, self.showSoundFontPicker(_:))

    tagsVisibilityManager = .init(tagsBottonConstraint: tagsBottomConstraint,
                                  tagsViewHeightConstrain: tagsViewHeightConstraint,
                                  fontsView: fontsView,
                                  containerView: self.view,
                                  tagsTableViewController: tagsTableViewController,
                                  infoBar: infoBar)
  }
}

// MARK: - FontsViewManager Protocol

extension SoundFontsViewController: FontsViewManager {

  func dismissSearchKeyboard() {
    presetsTableViewController.searchBar.endSearch()
  }

  func addSoundFonts(urls: [URL]) {
    os_log(.info, log: log, "addSoundFonts - BEGIN %{public}s", String.pointer(self))
    guard !urls.isEmpty else { return }

    var ok = [String]()
    var failures = [SoundFontFileLoadFailure]()
    var toActivate: SoundFontAndPreset?

    for each in urls {
      os_log(.debug, log: log, "processing %{public}s", each.path)
      switch soundFonts.add(url: each) {
      case .success(let (_, soundFont)):
        toActivate = soundFont.makeSoundFontAndPreset(at: 0)
        ok.append(soundFont.fileURL.lastPathComponent)
      case .failure(let failure):
        failures.append(failure)
      }
    }

    // Activate the first preset of the last valid sound font that was added
    if let soundFontAndPreset = toActivate {
      self.fontsTableViewController.activate(soundFontAndPreset)
    }

    if urls.count > 1 || !failures.isEmpty {
      let message = Formatters.makeAddSoundFontBody(ok: ok, failures: failures, total: urls.count)
      let alert = UIAlertController(title: Formatters.strings.addSoundFontsStatusTitle, message: message,
                                    preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      self.present(alert, animated: true, completion: nil)
    }
  }
}

// MARK: - FontEditorActionGenerator Protocol

extension SoundFontsViewController: FontActionManager {

  /**
   Create right-swipe action to edit a SoundFont.

   - parameter at: the FontCell that will hold the swipe action
   - parameter with: the SoundFont that will be edited by the swipe action
   - returns: new UIContextualAction that will perform the edit
   */
  func createEditSwipeAction(at: IndexPath, cell: TableCell, soundFont: SoundFont) -> UIContextualAction {
    UIContextualAction(icon: .edit, color: .systemTeal) { [weak self] _, _, completionHandler in
      guard let self = self else { return }
      self.beginEditingFont(at: at, cell: cell, soundFont: soundFont, completionHandler: completionHandler)
    }
  }

  func beginEditingFont(at: IndexPath, cell: TableCell, soundFont: SoundFont,
                        completionHandler: ((Bool) -> Void)? = nil) {
    let config = FontEditor.Config(indexPath: at, view: cell, rect: cell.bounds, soundFonts: soundFonts,
                                   soundFontKey: soundFont.key,
                                   favoriteCount: favorites.count(associatedWith: soundFont), tags: tags,
                                   completionHandler: completionHandler)
    self.performSegue(withIdentifier: .fontEditor, sender: config)
  }

  /**
   Create left-swipe action to *delete* a SoundFont. When activated, the action will display a prompt to the user
   asking for confirmation about the SoundFont deletion.

   - parameter at: the FontCell that will hold the swipe action
   - parameter with: the SoundFont that will be edited by the swipe action
   - parameter indexPath: the IndexPath of the FontCell that would be removed by the action
   - returns: new UIContextualAction that will perform the edit
   */
  func createDeleteSwipeAction(at: IndexPath, cell: TableCell, soundFont: SoundFont) -> UIContextualAction {
    UIContextualAction(icon: .remove, color: .red) { [weak self] _, _, completionHandler in
      self?.remove(soundFont: soundFont, completionHandler: completionHandler)
    }
  }
}

extension SoundFontsViewController: SegueHandler {

  /// Segues that we support.
  enum SegueIdentifier: String {
    case fontsTableView
    case presetsTableView
    case tagsTableView
    case fontEditor
    case fontBrowser
    case tagsEditor
    case fontsEditor
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segueIdentifier(for: segue) {
    case .fontsTableView: prepareForFontTableView(segue)
    case .presetsTableView: prepareForPresetsTableView(segue)
    case .tagsTableView: prepareForTagsTableView(segue)
    case .fontEditor: prepareForFontEditor(segue, sender: sender)
    case .fontBrowser: break
    case .tagsEditor: prepareForTagsEditor(segue, sender: sender)
    case .fontsEditor: prepareForFontsEditor(segue, sender: sender)
    }
  }
}

private extension SoundFontsViewController {

  func prepareForFontTableView(_ segue: UIStoryboardSegue) {
    guard let destination = segue.destination as? FontsTableViewController else {
      fatalError("expected FontsTableViewController for segue destination")
    }
    fontsTableViewController = destination
  }

  func prepareForPresetsTableView(_ segue: UIStoryboardSegue) {
    guard let destination = segue.destination as? PresetsTableViewController else {
      fatalError("expected PresetsTableViewController for segue destination")
    }
    presetsTableViewController = destination
  }

  func prepareForTagsTableView(_ segue: UIStoryboardSegue) {
    guard let destination = segue.destination as? TagsTableViewController else {
      fatalError("expected TagsTableViewController for segue destination")
    }
    tagsTableViewController = destination
  }

  func prepareForFontEditor(_ segue: UIStoryboardSegue, sender: Any?) {
    guard let config = sender as? FontEditor.Config else { fatalError("expected FontEditor.Config") }
    prepareToEditFont(segue, config: config)
  }

  func prepareForTagsEditor(_ segue: UIStoryboardSegue, sender: Any?) {
    guard let config = sender as? TagsEditorTableViewController.Config else {
      fatalError("expected TagsEditorTableViewController.Config")
    }
    prepareToEditTags(segue, config: config)
  }

  func prepareForFontsEditor(_ segue: UIStoryboardSegue, sender: Any?) {
    guard let config = sender as? FontsEditorTableViewController.Config else {
      fatalError("expected FontsEditorTableViewController.Config")
    }
    prepareToEditFonts(segue, config: config)
  }

  func prepareToEditFont(_ segue: UIStoryboardSegue, config: FontEditor.Config) {
    guard let navController = segue.destination as? UINavigationController,
          let viewController = navController.topViewController as? FontEditor
    else {
      fatalError("unexpected view configuration")
    }

    viewController.delegate = self
    viewController.configure(config)

    if keyboard == nil {
      viewController.modalPresentationStyle = .fullScreen
      navController.modalPresentationStyle = .fullScreen
    }

    if let ppc = navController.popoverPresentationController {
      ppc.sourceView = config.view
      ppc.sourceRect = config.rect
      ppc.permittedArrowDirections = [.up, .down]
      ppc.delegate = viewController
    }

    navController.presentationController?.delegate = viewController
  }

  func prepareToEditTags(_ segue: UIStoryboardSegue, config: TagsEditorTableViewController.Config) {
    guard let navController = segue.destination as? UINavigationController,
          let viewController = navController.topViewController as? TagsEditorTableViewController
    else {
      fatalError("unexpected view configuration")
    }

    viewController.configure(config)

    if keyboard == nil {
      viewController.modalPresentationStyle = .fullScreen
      navController.modalPresentationStyle = .fullScreen
    }

    if let ppc = navController.popoverPresentationController {
      ppc.sourceView = view
      ppc.sourceRect = view.frame
      ppc.permittedArrowDirections = []
      ppc.delegate = viewController
    }

    navController.presentationController?.delegate = viewController
  }

  func prepareToEditFonts(_ segue: UIStoryboardSegue, config: FontsEditorTableViewController.Config) {
    guard let navController = segue.destination as? UINavigationController,
          let viewController = navController.topViewController as? FontsEditorTableViewController
    else {
      fatalError("unexpected view configuration")
    }

    viewController.configure(config)
    viewController.navigationItem.title = "Remove Fonts"

    if keyboard == nil {
      viewController.modalPresentationStyle = .fullScreen
      navController.modalPresentationStyle = .fullScreen
    }

    if let ppc = navController.popoverPresentationController {
      ppc.sourceView = view
      ppc.sourceRect = view.frame
      ppc.permittedArrowDirections = []
      ppc.delegate = viewController
    }

    navController.presentationController?.delegate = viewController
  }

  func showSoundFontPicker(_ button: AnyObject) {
    let types = ["com.braysoftware.sf2", "com.soundblaster.soundfont"].compactMap { UTType($0) }
    let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: types,
                                                        asCopy: settings.copyFilesWhenAdding)
    documentPicker.delegate = self
    documentPicker.modalPresentationStyle = .automatic
    documentPicker.allowsMultipleSelection = true
    present(documentPicker, animated: true)
  }

  func remove(soundFont: SoundFont, completionHandler: ((_ completed: Bool) -> Void)?) {
    let promptTitle = Formatters.strings.deleteFontTitle
    let promptMessage = Formatters.strings.deleteFontMessage
    let alertController = UIAlertController(title: promptTitle, message: promptMessage, preferredStyle: .alert)

    let delete = UIAlertAction(title: Formatters.strings.deleteAction, style: .destructive) { [weak self ] _ in
      guard let self = self else { return }
      self.soundFonts.remove(key: soundFont.key)
      self.favorites.removeAll(associatedWith: soundFont)
      let url = soundFont.fileURL
      if soundFont.kind.deletable {
        DispatchQueue.global(qos: .userInitiated).async {
          try? FileManager.default.removeItem(at: url)
        }
      }
      completionHandler?(true)
    }

    let cancel = UIAlertAction(title: Formatters.strings.cancelAction, style: .cancel) { _ in
      completionHandler?(false)
    }

    alertController.addAction(delete)
    alertController.addAction(cancel)

    if let popoverController = alertController.popoverPresentationController {
      popoverController.sourceView = self.view
      popoverController.sourceRect = CGRect(
        x: self.view.bounds.midX, y: self.view.bounds.midY,
        width: 0, height: 0)
      popoverController.permittedArrowDirections = []
    }

    present(alertController, animated: true, completion: nil)
  }
}

// MARK: - FontEditorDelegate Protocol

extension SoundFontsViewController: FontEditorDelegate {
  func dismissed(reason: FontEditorDismissedReason) {
    if case let .done(soundFontKey) = reason {
      guard let soundFont = soundFonts.getBy(key: soundFontKey) else { return }
      soundFonts.rename(key: soundFontKey, name: soundFont.displayName)
    }
    dismiss(animated: true, completion: nil)
  }
}

// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 View controller for the SoundFont / Presets UITableView combination. Much of the UITableView management is handled
 by embedded view controllers. This controller mainly serves to manage the active preset state, plus the switching
 between normal preset table view display and preset search results display. Apart from the adopted protocols, there
 is no API for this class.
 */
public final class SoundFontsViewController: UIViewController {
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
  private var soundFonts: SoundFonts!
  private var favorites: Favorites!
  private var infoBar: InfoBar!
  private var tags: Tags!
  private var settings: Settings!

  private var fontsTableViewManager: FontsTableViewManager!
  private var selectedSoundFontManager: SelectedSoundFontManager!
  private var activeTagManager: ActiveTagManager!
  private var keyboard: Keyboard?

  private var dividerDragGesture = UIPanGestureRecognizer()
  private var lastDividerPos: CGFloat = .zero

  public let swipeLeft = UISwipeGestureRecognizer()
  public let swipeRight = UISwipeGestureRecognizer()
}

extension SoundFontsViewController {

  public override func viewDidLoad() {
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

//    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
//    longPressGesture.minimumPressDuration = 0.5
//    fontsTableView.addGestureRecognizer(longPressGesture)
  }

  @objc func moveDivider(_ gesture: UIPanGestureRecognizer) {
    switch gesture.state {
    case .began:
      os_log(.info, log: log, "moveDivider - BEGIN")
      lastDividerPos = gesture.location(in: view).x

    case .changed:
      os_log(.info, log: log, "moveDivider - CHANGED")
      let pos = gesture.location(in: self.view)
      let change = CGFloat(Int(pos.x - lastDividerPos))
      guard abs(change) > 0 else { return }

      os_log(.info, log: log, "moveDivider - CHANGE: %f", change)
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
        .info, log: log, "moveDivider - old: %f new: %f",
        presetsWidthConstraint.multiplier,
        multiplier)
      presetsWidthConstraint = presetsWidthConstraint.setMultiplier(multiplier)
      settings.presetsWidthMultiplier = Double(multiplier)

    default: break
    }
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    fontsTableViewManager?.selectActive()
  }

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    if showingTags {
      hideTags()
    }
  }
}

extension SoundFontsViewController {

  private func addSoundFont(_ button: AnyObject) {
    let documentPicker = UIDocumentPickerViewController(
      documentTypes: ["com.braysoftware.sf2", "com.soundblaster.soundfont"],
      in: settings.copyFilesWhenAdding ? .import : .open)
    documentPicker.delegate = self
    if #available(iOS 13, *) {
      documentPicker.modalPresentationStyle = .automatic
    } else {
      documentPicker.modalPresentationStyle = .overFullScreen
    }
    documentPicker.allowsMultipleSelection = true
    present(documentPicker, animated: true)
  }

  private func remove(soundFont: SoundFont, completionHandler: ((_ completed: Bool) -> Void)?)
  {
    let promptTitle = Formatters.strings.deleteFontTitle
    let promptMessage = Formatters.strings.deleteFontMessage
    let alertController = UIAlertController(title: promptTitle, message: promptMessage, preferredStyle: .alert)

    let delete = UIAlertAction(title: Formatters.strings.deleteAction, style: .destructive) { [weak self ] _ in
      guard let self = self else { return }
      self.soundFonts.remove(key: soundFont.key)
      self.favorites.removeAll(associatedWith: soundFont)
      let url = soundFont.fileURL
      if soundFont.removable {
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

extension SoundFontsViewController: UIDocumentPickerDelegate {

  public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    os_log(.info, log: log, "documentPicker didPickDocumentAt")
    addSoundFonts(urls: urls)
  }
}

// MARK: - ControllerConfiguration Protocol

extension SoundFontsViewController: ControllerConfiguration {

  public func establishConnections(_ router: ComponentContainer) {
    settings = router.settings
    soundFonts = router.soundFonts
    favorites = router.favorites
    keyboard = router.keyboard
    selectedSoundFontManager = router.selectedSoundFontManager
    infoBar = router.infoBar
    tags = router.tags

    let multiplier = settings.presetsWidthMultiplier
    presetsWidthConstraint = presetsWidthConstraint.setMultiplier(CGFloat(multiplier))

    router.infoBar.addEventClosure(.addSoundFont, self.addSoundFont)
    router.infoBar.addEventClosure(.showTags, self.toggleShowTags)

//    fontsTableViewController.establishConnections(router)
//    presetsTableViewController.establishConnections(router)

    fontsTableViewManager?.selectActive()
  }
}

// MARK: - FontsViewManager Protocol

extension SoundFontsViewController: FontsViewManager {

  public func dismissSearchKeyboard() {
    presetsTableViewController.searchBar.endSearch()
  }

  public func addSoundFonts(urls: [URL]) {
    guard !urls.isEmpty else { return }
    var ok = [String]()
    var failures = [SoundFontFileLoadFailure]()
    for each in urls {
      os_log(.info, log: log, "processing %{public}s", each.path)
      switch soundFonts.add(url: each) {
      case .success(let (_, soundFont)): ok.append(soundFont.fileURL.lastPathComponent)
      case .failure(let failure): failures.append(failure)
      }
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

extension SoundFontsViewController: FontSwipeActionGenerator {

  /**
   Create right-swipe action to edit a SoundFont.

   - parameter at: the FontCell that will hold the swipe action
   - parameter with: the SoundFont that will be edited by the swipe action
   - returns: new UIContextualAction that will perform the edit
   */
  public func createEditSwipeAction(at: IndexPath, cell: TableCell, soundFont: SoundFont) -> UIContextualAction {
    UIContextualAction(icon: .edit, color: .systemTeal) { [weak self] _, _, completionHandler in
      guard let self = self else { return }
      self.beginEditingFont(at: at, cell: cell, soundFont: soundFont, completionHandler: completionHandler)
    }
  }

  public func beginEditingFont(at: IndexPath, cell: TableCell, soundFont: SoundFont, completionHandler: ((Bool) -> Void)? = nil) {
    let config = FontEditor.Config(indexPath: at, view: cell, rect: cell.bounds, soundFonts: self.soundFonts,
                                   soundFontKey: soundFont.key,
                                   favoriteCount: self.favorites.count(associatedWith: soundFont), tags: self.tags,
                                   completionHandler: completionHandler)
    self.performSegue(withIdentifier: .fontEditor, sender: config)
  }

//  @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
//    switch sender.state {
//    case .began:
//      let pos = sender.location(in: view)
//      guard let indexPath = fonts.indexPathForItem(at: pos) else { return }
//      guard let cell: TableCell = fontsTableView.cellForItem(at: indexPath) else { return }
//      beginEditingFont(at: indexPath, cell: cell, soundFont: <#T##SoundFont#>, completionHandler: <#T##((Bool) -> Void)?##((Bool) -> Void)?##(Bool) -> Void#>)
//
//    default:
//      view.cancelInteractiveMovement()
//      cell?.moving = false
//    }
//  }
//
  /**
   Create left-swipe action to *delete* a SoundFont. When activated, the action will display a prompt to the user
   asking for confirmation about the SoundFont deletion.

   - parameter at: the FontCell that will hold the swipe action
   - parameter with: the SoundFont that will be edited by the swipe action
   - parameter indexPath: the IndexPath of the FontCell that would be removed by the action
   - returns: new UIContextualAction that will perform the edit
   */
  public func createDeleteSwipeAction(at: IndexPath, cell: TableCell, soundFont: SoundFont) -> UIContextualAction {
    UIContextualAction(icon: .remove, color: .red) { [weak self] _, _, completionHandler in
      self?.remove(soundFont: soundFont, completionHandler: completionHandler)
    }
  }
}

extension SoundFontsViewController: SegueHandler {

  /// Segues that we support.
  public enum SegueIdentifier: String {
    case fontsTableView
    case presetsTableView
    case tagsTableView
    case fontEditor
    case fontBrowser
    case tagsEditor
  }

  public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segueIdentifier(for: segue) {
    case .fontsTableView:
      guard let destination = segue.destination as? FontsTableViewController else {
        fatalError("expected FontsTableViewController for segue destination")
      }
      fontsTableViewController = destination

    case .presetsTableView:
      guard let destination = segue.destination as? PresetsTableViewController else {
        fatalError("expected PresetsTableViewController for segue destination")
      }
      presetsTableViewController = destination

    case .tagsTableView:
      guard let destination = segue.destination as? TagsTableViewController else {
        fatalError("expected TagsTableViewController for segue destination")
      }
      tagsTableViewController = destination
      // tagsTableViewController.soundFontsViewController = self

    case .fontEditor:
      guard let config = sender as? FontEditor.Config else { fatalError("expected FontEditor.Config") }
      prepareToEditFont(segue, config: config)

    case .fontBrowser: break

    case .tagsEditor:
      guard let config = sender as? TagsEditorTableViewController.Config else {
        fatalError("expected TagsEditorTableViewController.Config")
      }
      prepareToEditTags(segue, config: config)
    }
  }

  private func prepareToEditFont(_ segue: UIStoryboardSegue, config: FontEditor.Config) {
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

  private func prepareToEditTags(_ segue: UIStoryboardSegue, config: TagsEditorTableViewController.Config) {
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
}

// MARK: - FontEditorDelegate Protocol

extension SoundFontsViewController: FontEditorDelegate {
  public func dismissed(reason: FontEditorDismissedReason) {
    if case let .done(soundFontKey) = reason {
      guard let soundFont = soundFonts.getBy(key: soundFontKey) else { return }
      soundFonts.rename(key: soundFontKey, name: soundFont.displayName)
    }
    dismiss(animated: true, completion: nil)
  }
}

extension SoundFontsViewController {

  private var showingTags: Bool { tagsBottomConstraint.constant == 0.0 }

  private func toggleShowTags(_ sender: AnyObject) {
    let button = sender as? UIButton
    if tagsBottomConstraint.constant == 0.0 {
      hideTags()
    } else {
      button?.tintColor = .systemOrange
      showTags()
    }
  }

  private func showTags() {
    let maxHeight = fontsView.frame.height - 8
    let midHeight = maxHeight / 2.0
    let minHeight = CGFloat(120.0)

    var bestHeight = midHeight
    if bestHeight > maxHeight { bestHeight = maxHeight }
    if bestHeight < minHeight { bestHeight = maxHeight }

    tagsViewHeightConstraint.constant = bestHeight
    tagsBottomConstraint.constant = 0.0
    UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.25, delay: 0.0,
                                                   options: [.allowUserInteraction, .curveEaseIn],
                                                   animations: self.view.layoutIfNeeded) { [weak self] _ in
      // self?.tagsTableViewManager.showActiveTag(animated: false)
    }
  }

  private func hideTags() {
    infoBar.resetButtonState(.showTags)
    tagsViewHeightConstraint.constant = maxTagsViewHeightConstraint
    tagsBottomConstraint.constant = tagsViewHeightConstraint.constant + 8
    UIViewPropertyAnimator.runningPropertyAnimator(
      withDuration: 0.25, delay: 0.0,
      options: [.allowUserInteraction, .curveEaseOut],
      animations: self.view.layoutIfNeeded,
      completion: nil
    )
  }
}

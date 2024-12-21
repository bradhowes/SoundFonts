// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/// Manages the view of Favorite items. Users can choose a Favorite by tapping it in order to apply the Favorite
/// settings. The user may long-touch on a Favorite to move it around. Double-tapping on it will open the editor.
final class FavoritesViewController: UIViewController, FavoritesViewManager {
  private lazy var log: Logger = Logging.logger("FavoritesViewController")
  private let serialQueue = DispatchQueue(label: "FavoritesViewController", qos: .userInteractive, attributes: [],
                                          autoreleaseFrequency: .inherit, target: .main)

  @IBOutlet private var favoritesView: UICollectionView!
  @IBOutlet private var longPressGestureRecognizer: UILongPressGestureRecognizer!
  @IBOutlet public var doubleTapGestureRecognizer: UITapGestureRecognizer!

  private var activePresetManager: ActivePresetManager!
  private var keyboard: AnyKeyboard?
  private var favorites: FavoritesProvider!
  private var soundFonts: SoundFontsProvider!
  private var tags: TagsProvider!
  private var settings: Settings!
  private var favoriteMover: FavoriteMover!

  public var swipeLeft = UISwipeGestureRecognizer()
  public var swipeRight = UISwipeGestureRecognizer()

  private var activePresetManagerSubscription: SubscriberToken?
  private var favoritesSubscription: SubscriberToken?
  private var soundFontsSubscription: SubscriberToken?
  private var tagsSubscription: SubscriberToken?

  private var monitorActionActivity: NotificationObserver?

  private lazy var cellFont = {
    guard let font = UIFont(name: "EurostileRegular", size: 20) else { fatalError("Failed to load font") }
    return font
  }()
}

extension FavoritesViewController {

  override func viewDidLoad() {

    favoritesView.register(FavoriteCell.self)

    doubleTapGestureRecognizer.numberOfTapsRequired = 2
    doubleTapGestureRecognizer.numberOfTouchesRequired = 1
    doubleTapGestureRecognizer.addTarget(self, action: #selector(editFavorite(_:)))
    doubleTapGestureRecognizer.delaysTouchesBegan = true

    favoriteMover = FavoriteMover(view: favoritesView, recognizer: longPressGestureRecognizer)

    swipeLeft.direction = .left
    swipeLeft.numberOfTouchesRequired = 2
    view.addGestureRecognizer(swipeLeft)

    swipeRight.direction = .right
    swipeRight.numberOfTouchesRequired = 2
    view.addGestureRecognizer(swipeRight)

    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 8
    layout.minimumLineSpacing = 8

    favoritesView.setCollectionViewLayout(layout, animated: false)

    favoritesView.isAccessibilityElement = false
    favoritesView.accessibilityIdentifier = "FavoritesView"
    favoritesView.accessibilityHint = "View holding favorites"
    favoritesView.accessibilityLabel = "FavoritesView"

    checkIfRestored()

    monitorActionActivity = MIDIEventRouter.monitorActionActivity { self.handleAction(payload: $0) }
  }

  override func viewDidAppear(_ animated: Bool) {
    log.debug("viewWillAppear BEGIN")
    super.viewDidAppear(animated)
    guard let favorite = activePresetManager?.activeFavorite else { return }
    updateCell(with: favorite)
    log.debug("viewWillAppear END")
  }
}

extension FavoritesViewController: ControllerConfiguration {

  func establishConnections(_ router: ComponentContainer) {
    activePresetManager = router.activePresetManager
    favorites = router.favorites
    keyboard = router.keyboard
    soundFonts = router.soundFonts
    tags = router.tags
    settings = router.settings

    activePresetManagerSubscription = activePresetManager.subscribe(self, notifier: activePresetChangedNotificationInBackground)
    favoritesSubscription = favorites.subscribe(self, notifier: favoritesChangedNotificationInBackground)
    soundFontsSubscription = soundFonts.subscribe(self, notifier: soundFontsChangedNotificationInBackground)
    tagsSubscription = tags.subscribe(self, notifier: tagsChangedNotificationInBackground)

    checkIfRestored()
  }
}

extension FavoritesViewController: SegueHandler {

  enum SegueIdentifier: String {
    case favoriteEditor
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segueIdentifier(for: segue) {
    case .favoriteEditor:
      guard let config = sender as? FavoriteEditor.Config else {
        fatalError("expected FavoriteEditor.Config")
      }
      prepareToEdit(segue, config: config)
    }
  }
}

extension FavoritesViewController: FavoriteEditorDelegate {

  func dismissed(_ indexPath: IndexPath, reason: FavoriteEditorDismissedReason) {
    if case let .done(response) = reason {
      switch response {
      case .favorite(let config):
        favorites.update(index: indexPath.item, config: config)
        favoritesView.reloadItems(at: [indexPath])
        favoritesView.collectionViewLayout.invalidateLayout()
      case .preset(let soundFontAndPreset, let config):
        soundFonts.updatePreset(soundFontAndPreset: soundFontAndPreset, config: config)
      }
    }

    if let presetConfig = activePresetManager.activePresetConfig {
      PresetConfig.changedNotification.post(value: presetConfig)
    }

    self.dismiss(animated: true, completion: nil)
  }
}

extension FavoritesViewController: UICollectionViewDataSource {

  func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    favorites.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    update(cell: collectionView.dequeueReusableCell(for: indexPath), with: favorites.getBy(index: indexPath.row))
  }
}

extension FavoritesViewController: UICollectionViewDelegate {

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    favorites.selected(index: indexPath.row)
  }

  func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
    favorites.count > 1
  }

  func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath,
                      to destinationIndexPath: IndexPath) {
    favorites.move(from: sourceIndexPath.item, to: destinationIndexPath.item)
    collectionView.reloadItems(at: [sourceIndexPath, destinationIndexPath])
  }
}

extension FavoritesViewController: UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    if let favorite = favorites.getBy(index: indexPath.item) {
      return CGSize(width: favorite.presetConfig.name.size(
        withAttributes: [NSAttributedString.Key.font: cellFont]).width + 25, height: 30)
    }
    self.log.error("Invalid favorite index \(indexPath.item)")
    return .zero
  }
}

private extension FavoritesViewController {

  func handleAction(payload: MIDIEventRouter.ActionActivityPayload) {
    guard case .editFavorite = payload.action  else { return }
    if payload.value > 64 { self.editCurrentFavorite() }
  }

  func doEditFavorite(indexPath: IndexPath, viewCell: UICollectionViewCell, favorite: Favorite) {
    if activePresetManager.resolveToSoundFont(favorite.soundFontAndPreset) == nil {
      favorites.remove(key: favorite.key)
      postNotice(msg: "Removed favorite that was invalid.")
      return
    }

    let isActive = activePresetManager.activeFavorite?.key == favorite.key
    let configState = FavoriteEditor.State(indexPath: indexPath, sourceView: favoritesView, sourceRect: view.frame,
                                           currentLowestNote: self.keyboard?.lowestNote, completionHandler: nil,
                                           soundFonts: self.soundFonts, soundFontAndPreset: favorite.soundFontAndPreset,
                                           isActive: isActive, settings: settings)
    let config = FavoriteEditor.Config.favorite(state: configState, favorite: favorite)
    showEditor(config: config)
  }

  func showEditor(config: FavoriteEditor.Config) {
    performSegue(withIdentifier: .favoriteEditor, sender: config)
  }

  func activePresetChangedNotificationInBackground(_ event: ActivePresetEvent) {
    log.debug("activePresetChanged BEGIN - \(event.description, privacy: .public)")
    guard favorites.isRestored && soundFonts.isRestored else { return }
    switch event {
    case let .changed(old: old, new: new, playSample: _):
      if case let .favorite(oldFaveKey, _) = old, let favorite = favorites.getBy(key: oldFaveKey) {
        log.debug("updating previous favorite cell")
        serialQueue.async { self.updateCell(with: favorite) }
      }
      if case let .favorite(newFaveKey, _) = new, let favorite = favorites.getBy(key: newFaveKey) {
        log.debug("updating new favorite cell")
        serialQueue.async { self.updateCell(with: favorite) }
      }
    case let .loaded(preset: preset):
      if case let .favorite(key, _) = preset, let favorite = favorites.getBy(key: key) {
        serialQueue.async { self.updateCell(with: favorite) }
      }
    }
  }

  func favoritesChangedNotificationInBackground(_ event: FavoritesEvent) {
    log.debug("favoritesChanged")
    switch event {
    case let .added(index: index, favorite: favorite):
      serialQueue.async { self.handleFavoriteAdded(index: index, favorite: favorite) }
    case let .selected(index: _, favorite: favorite):
      serialQueue.async { self.activePresetManager.setActive(favorite: favorite, playSample: true) }
    case let .beginEdit(config: config):
      serialQueue.async { self.showEditor(config: config) }
    case let .changed(index: _, favorite: favorite):
      serialQueue.async { self.updateCell(with: favorite) }
    case let .removed(index: index, favorite: _):
      serialQueue.async { self.handleFavoriteRemoved(index: index) }
    case .removedAll:
      serialQueue.async { self.favoritesView.reloadData() }
    case .restored:
      serialQueue.async { self.checkIfRestored() }
    }
  }

  func handleFavoriteAdded(index: Int, favorite: Favorite) {
    log.debug("added item \(index)")
    favoritesView.insertItems(at: [IndexPath(item: index, section: 0)])
    if favorite == activePresetManager.activeFavorite {
      favoritesView.selectItem(
        at: indexPath(of: favorite.key), animated: false,
        scrollPosition: .centeredVertically)
      updateCell(with: favorite)
    }
  }

  func handleFavoriteRemoved(index: Int) {
    log.debug("removed \(index)")
    guard favoritesView.delegate != nil else { return }
    let indexPath = IndexPath(item: index, section: 0)
    favoritesView.deleteItems(at: [indexPath])
    favoritesView.reloadData()
  }

  func soundFontsChangedNotificationInBackground(_ event: SoundFontsEvent) {
    switch event {
    case .restored: serialQueue.async { self.checkIfRestored() }
    default: break
    }
  }

  func tagsChangedNotificationInBackground(_ event: TagsEvent) {
    switch event {
    case .restored: serialQueue.async { self.checkIfRestored() }
    default: break
    }
  }

  func checkIfRestored() {
    guard soundFonts != nil,
          soundFonts.isRestored,
          favorites != nil,
          favorites.isRestored,
          tags != nil,
          tags.isRestored
    else {
      return
    }

    if favoritesView != nil {
      if favoritesView.dataSource == nil {
        favoritesView.dataSource = self
        favoritesView.delegate = self
      }

      soundFonts.validateCollections(favorites: self.favorites, tags: self.tags)
      favoritesView.reloadData()
    }
  }

  func prepareToEdit(_ segue: UIStoryboardSegue, config: FavoriteEditor.Config) {
    guard let navController = segue.destination as? UINavigationController,
          let viewController = navController.topViewController as? FavoriteEditor
    else {
      fatalError("unexpected controller relationships")
    }

    viewController.delegate = self
    viewController.configure(config)

    if keyboard == nil {

      // Constrained layout due to being an AUv3.
      viewController.modalPresentationStyle = .fullScreen
      viewController.modalPresentationStyle = .fullScreen
    }

    if let ppc = navController.popoverPresentationController {
      ppc.sourceView = config.state.sourceView
      ppc.sourceRect = config.state.sourceRect
      ppc.permittedArrowDirections = [.up, .down]
      ppc.delegate = viewController
    }

    navController.presentationController?.delegate = viewController
  }

  @objc func editFavorite(_ recognizer: UITapGestureRecognizer) {
    let pos = recognizer.location(in: view)
    guard let indexPath = favoritesView.indexPathForItem(at: pos) else { return }
    guard let favorite = favorites.getBy(index: indexPath.item) else { return }
    guard let view = favoritesView.cellForItem(at: indexPath) else { fatalError() }

    if activePresetManager.resolveToSoundFont(favorite.soundFontAndPreset) == nil {
      favorites.remove(key: favorite.key)
      postNotice(msg: "Removed favorite that was invalid.")
      return
    }

    let isActive = activePresetManager.activeFavorite?.key == favorite.key
    let configState = FavoriteEditor.State(indexPath: indexPath, sourceView: favoritesView, sourceRect: view.frame,
                                           currentLowestNote: self.keyboard?.lowestNote, completionHandler: nil,
                                           soundFonts: self.soundFonts, soundFontAndPreset: favorite.soundFontAndPreset,
                                           isActive: isActive, settings: settings)
    let config = FavoriteEditor.Config.favorite(state: configState, favorite: favorite)
    showEditor(config: config)
  }

  func editCurrentFavorite() {
    guard let favorite = activePresetManager.activeFavorite else { return }
    guard let index = favorites.index(of: favorite.key) else { return }

    let indexPath: IndexPath = .init(item: index, section: 0)
    guard let view = favoritesView.cellForItem(at: indexPath) else { return }
    doEditFavorite(indexPath: indexPath, viewCell: view, favorite: favorite)
  }

  func indexPath(of key: Favorite.Key) -> IndexPath? {
    guard let index = favorites.index(of: key) else { return nil }
    return IndexPath(item: index, section: 0)
  }

  func updateCell(with favorite: Favorite) {
    guard favorites.contains(key: favorite.key) else { return }
    if let indexPath = self.indexPath(of: favorite.key),
       let cell: FavoriteCell = favoritesView.cellForItem(at: indexPath) {
      update(cell: cell, with: favorite)
    }
  }

  func postNotice(msg: String) {
    let alertController = UIAlertController(
      title: "Favorites", message: msg, preferredStyle: .alert)
    let cancel = UIAlertAction(title: "OK", style: .cancel) { _ in }
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

  @discardableResult
  func update(cell: FavoriteCell, with favorite: Favorite?) -> FavoriteCell {
    guard let favorite else {
      self.log.error("Favorite is nil -- not good!")
      return cell
    }
    let isActive = favorite == activePresetManager.activeFavorite
    cell.update(favoriteName: favorite.presetConfig.name, isActive: isActive)
    return cell
  }
}

// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Manages the view of Favorite items. Users can choose a Favorite by tapping it in order to apply the Favorite
 settings. The user may long-touch on a Favorite to move it around. Double-tapping on it will open the editor.
 */
public final class FavoritesViewController: UIViewController, FavoritesViewManager {
    private lazy var log = Logging.logger("FavsVC")

    @IBOutlet private var favoritesView: UICollectionView!
    @IBOutlet private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    @IBOutlet public var doubleTapGestureRecognizer: UITapGestureRecognizer!

    private var activePatchManager: ActivePatchManager!
    private var keyboard: Keyboard?
    private var favorites: Favorites!
    private var soundFonts: SoundFonts!

    private var favoriteMover: FavoriteMover!

    public var swipeLeft = UISwipeGestureRecognizer()
    public var swipeRight = UISwipeGestureRecognizer()

    private var activePatchManagerSubscription: SubscriberToken?
    private var favoritesSubscription: SubscriberToken?

    public override func viewDidLoad() {
        favoritesView.register(FavoriteCell.self)
        favoritesView.dataSource = self
        favoritesView.delegate = self

        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.numberOfTouchesRequired = 1
        doubleTapGestureRecognizer.addTarget(self, action: #selector(editFavorite))
        doubleTapGestureRecognizer.delaysTouchesBegan = true

        favoriteMover = FavoriteMover(view: favoritesView, lpgr: longPressGestureRecognizer)

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
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        favoritesView.reloadData()
    }

    public override func viewWillAppear(_ animated: Bool) {
        os_log(.info, log: log, "viewWillAppear")
        super.viewWillAppear(animated)

        if activePatchManagerSubscription == nil {
            activePatchManagerSubscription = activePatchManager.subscribe(self, notifier: activePatchChange)
        }

        if favoritesSubscription == nil {
            favoritesSubscription = favorites.subscribe(self, notifier: favoritesChange)
        }

        guard let favorite = activePatchManager.favorite else { return }
        updateCell(with: favorite)
    }
}

extension FavoritesViewController: ControllerConfiguration {

    public func establishConnections(_ router: ComponentContainer) {
        activePatchManager = router.activePatchManager
        favorites = router.favorites
        keyboard = router.keyboard
        soundFonts = router.soundFonts
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        os_log(.info, log: log, "activePatchChange")
        guard favorites.restored else { return }
        switch event {
        case let .active(old: old, new: new, playSample: _):
            if case let .favorite(oldFave) = old {
                os_log(.info, log: log, "updating previous favorite cell")
                updateCell(with: oldFave)
            }
            if case let .favorite(newFave) = new {
                os_log(.info, log: log, "updating new favorite cell")
                updateCell(with: newFave)
            }
        }
    }

    private func favoritesChange(_ event: FavoritesEvent) {
        os_log(.info, log: log, "favoritesChange")
        switch event {
        case let .added(index: index, favorite: favorite):
            os_log(.info, log: log, "added item %d", index)
            favoritesView.insertItems(at: [IndexPath(item: index, section: 0)])
            if favorite == activePatchManager.favorite {
                favoritesView.selectItem(at: indexPath(of: favorite), animated: false,
                                         scrollPosition: .centeredVertically)
                updateCell(with: favorite)
            }

        case let .selected(index: index, favorite: favorite):
            os_log(.info, log: log, "selected %d", index)
            activePatchManager.setActive(favorite: favorite, playSample: true)

        case let .beginEdit(config: config):
            showEditor(config: config)

        case let .changed(index: index, favorite: favorite):
            os_log(.info, log: log, "changed %d", index)
            updateCell(with: favorite)

        case let .removed(index: index, favorite: _):
            os_log(.info, log: log, "removed %d", index)
            let indexPath = IndexPath(item: index, section: 0)
            favoritesView.deleteItems(at: [indexPath])
            favoritesView.reloadData()

        case .removedAll: favoritesView.reloadData()
        case .restored: favoritesView.reloadData()
        }
    }
}

extension FavoritesViewController: SegueHandler {

    public enum SegueIdentifier: String {
        case favoriteEditor
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .favoriteEditor:
            guard let config = sender as? FavoriteEditor.Config else { fatalError("expected FavoriteEditor.Config") }
            prepareToEdit(segue, config: config)
        }
    }

    private func prepareToEdit(_ segue: UIStoryboardSegue, config: FavoriteEditor.Config) {
        guard let navController = segue.destination as? UINavigationController,
            let viewController = navController.topViewController as? FavoriteEditor else {
                return
        }

        viewController.delegate = self
        viewController.configure(config)

        if keyboard == nil {
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

    @objc private func editFavorite(_ gr: UITapGestureRecognizer) {
        let pos = gr.location(in: view)
        guard let indexPath = favoritesView.indexPathForItem(at: pos) else { return }
        let favorite = favorites.getBy(index: indexPath.item)
        guard let view = favoritesView.cellForItem(at: indexPath) else { fatalError() }

        if activePatchManager.resolveToSoundFont(favorite.soundFontAndPatch) == nil {
            favorites.remove(key: favorite.key)
            postNotice(msg: "Removed favorite that was invalid.")
            return
        }

        let configState = FavoriteEditor.State(indexPath: indexPath,
                                               sourceView: favoritesView, sourceRect: view.frame,
                                               currentLowestNote: self.keyboard?.lowestNote,
                                               completionHandler: nil, soundFonts: self.soundFonts,
                                               soundFontAndPatch: favorite.soundFontAndPatch)
        let config = FavoriteEditor.Config.favorite(state: configState, favorite: favorite)
        showEditor(config: config)
    }

    func showEditor(config: FavoriteEditor.Config) {
        performSegue(withIdentifier: .favoriteEditor, sender: config)
    }

    private func postNotice(msg: String) {
        let alertController = UIAlertController(title: "Favorites", message: msg, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "OK", style: .cancel) { _ in }
        alertController.addAction(cancel)

        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY,
                                                  width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        present(alertController, animated: true, completion: nil)
    }

}

extension FavoritesViewController: FavoriteEditorDelegate {

    public func dismissed(_ indexPath: IndexPath, reason: FavoriteEditorDismissedReason) {
        if case let .done(response) = reason {
            switch response {
            case .favorite(let config):
                favorites.update(index: indexPath.item, config: config)
                favoritesView.reloadItems(at: [indexPath])
                favoritesView.collectionViewLayout.invalidateLayout()
            case .preset(let soundFontAndPatch, let config):
                soundFonts.updatePreset(soundFontAndPatch: soundFontAndPatch, config: config)
            }
        }

        if let presetConfig = activePatchManager.favorite?.presetConfig ?? activePatchManager.patch?.presetConfig {
            PresetConfig.changedNotification.post(value: presetConfig)
        }

        self.dismiss(animated: true, completion: nil)
    }
}

extension FavoritesViewController: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        favorites.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        update(cell: collectionView.dequeueReusableCell(for: indexPath),
               with: favorites.getBy(index: indexPath.row))
    }
}

extension FavoritesViewController: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        favorites.selected(index: indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        favorites.count > 1
    }

    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath,
                               to destinationIndexPath: IndexPath) {
        favorites.move(from: sourceIndexPath.item, to: destinationIndexPath.item)
        collectionView.reloadItems(at: [sourceIndexPath, destinationIndexPath])
    }
}

extension FavoritesViewController: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let favorite = favorites.getBy(index: indexPath.item)
        let cell = update(cell: collectionView.dequeueReusableCell(for: indexPath), with: favorite)
        let size = cell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: min(size.width, collectionView.bounds.width), height: size.height)
    }
}

extension FavoritesViewController {

    private func indexPath(of favorite: LegacyFavorite) -> IndexPath? {
        guard let index = favorites.index(of: favorite.key) else { return nil }
        return IndexPath(row: index, section: 0)
    }

    private func updateCell(with favorite: LegacyFavorite) {
        guard let indexPath = self.indexPath(of: favorite) else { return }
        if let cell: FavoriteCell = favoritesView.cellForItem(at: indexPath) {
            update(cell: cell, with: favorite)
        }
    }

    @discardableResult
    private func update(cell: FavoriteCell, with favorite: LegacyFavorite) -> FavoriteCell {
        cell.update(favoriteName: favorite.presetConfig.name, isActive: favorite == activePatchManager.favorite)
        return cell
    }
}

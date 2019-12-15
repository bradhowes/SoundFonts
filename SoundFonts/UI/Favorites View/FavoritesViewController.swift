// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Manages the view of Favorite items. Users can choose a Favorite by tapping it in order to apply the Favorite
 settings. The user may long-touch on a Favorite to move it around. Double-tapping on it will open the editor.
 */
final class FavoritesViewController: UIViewController {
    private lazy var log = Logging.logger("FavsVC")

    private let favoriteCell = FavoriteCell.nib.instantiate(withOwner: nil, options: nil)[0] as! FavoriteCell

    @IBOutlet private var favoritesView: UICollectionView!
    @IBOutlet private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    @IBOutlet var doubleTapGestureRecognizer: UITapGestureRecognizer!
    
    private var activePatchManager: ActivePatchManager!
    private var keyboard: Keyboard!
    private var favorites: Favorites!

    private var favoriteMover: FavoriteMover!

    private var swipeLeft = UISwipeGestureRecognizer()
    private var swipeRight = UISwipeGestureRecognizer()

    override func viewDidLoad() {
        favoriteCell.translatesAutoresizingMaskIntoConstraints = false

        favoritesView.register(FavoriteCell.self)
        favoritesView.dataSource = self
        favoritesView.delegate = self

        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.numberOfTouchesRequired = 1
        doubleTapGestureRecognizer.addTarget(self, action: #selector(handleTap))
        doubleTapGestureRecognizer.delaysTouchesBegan = true

        favoriteMover = FavoriteMover(view: favoritesView, gr: longPressGestureRecognizer)

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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        favoritesView.reloadData()
    }
}

extension FavoritesViewController: ControllerConfiguration {

    func establishConnections(_ router: Router) {
        activePatchManager = router.activePatchManager
        favorites = router.favorites
        keyboard = router.keyboard

        activePatchManager.subscribe(self, closure: activePatchChange)
        favorites.subscribe(self, closure: favoritesChange)
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        os_log(.info, log: log, "activePatchChange")
        switch event {
        case let .active(old: old, new: new):
            if let favorite = old.favorite, favorite != new.favorite {
                os_log(.info, log: log, "updating previous favorite cell")
                updateCell(with: favorites.getBy(soundFontPatch: favorite.soundFontPatch)!)
            }
            if let favorite = new.favorite {
                os_log(.info, log: log, "updating new favorite cell")
                updateCell(with: favorite)
            }
        }
    }

    private func favoritesChange(_ event: FavoritesEvent) {
        os_log(.info, log: log, "favoritesChange")
        switch event {
        case let .added(index: index, favorite: _):
            os_log(.info, log: log, "added item %d", index)
            favoritesView.insertItems(at: [IndexPath(item: index, section: 0)])
            break
        case let .selected(index: index, favorite: favorite):
            os_log(.info, log: log, "selected %d", index)
            activePatchManager.setActive(.favorite(favorite: favorite))
        case let .beginEdit(index: index, favorite: favorite, view: view):
            os_log(.info, log: log, "begin editing %d", index)
            edit(favorite: favorite, sender: view)
        case let .changed(index: index, favorite: favorite):
            os_log(.info, log: log, "changed %d", index)
            update(cell: favoritesView.dequeueReusableCell(for: IndexPath(item: index, section: 0)), with: favorite)
        case let .removed(index: index, favorite: _, bySwiping: _):
            os_log(.info, log: log, "removed %d", index)
            favoritesView.deleteItems(at: [IndexPath(item: index, section: 0)])
        }
    }
}

// MARK: - Editing

extension FavoritesViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nc = segue.destination as? UINavigationController,
            let vc = nc.topViewController as? FavoriteEditor,
            let (favorite, view) = sender as? (Favorite, UIView) else { return }

        vc.delegate = self
        vc.editFavorite(favorite, position: indexPath(of: favorite), currentLowestNote: keyboard.lowestNote)

        if let ppc = nc.popoverPresentationController {
            ppc.barButtonItem = nil
            ppc.sourceView = view
            let rect = view.bounds
            ppc.sourceRect = view.convert(CGRect(origin: rect.offsetBy(dx: rect.width - 32, dy: 0).origin,
                                                 size: CGSize(width: 32.0, height: rect.height)), to: nil)
        }
    }

    /**
     Event handler for the double-tap esture recognizer. We use this to begin editing a favorite.
     
     - parameter gr: the gesture recognizer that fired the event
     */
    @objc private func handleTap(_ gr: UITapGestureRecognizer) {
        let pos = gr.location(in: view)
        guard let indexPath = favoritesView.indexPathForItem(at: pos) else { return }
        let favorite = favorites.getBy(index: indexPath.item)
        let cell = favoritesView.cellForItem(at: indexPath)!
        edit(favorite: favorite, sender: cell)
    }

    func edit(favorite: Favorite, sender: UIView) {
        performSegue(withIdentifier: "favoriteDetail", sender: (favorite, sender))
    }
}

// MARK: - FavoriteDetailControllerDelegate

extension FavoritesViewController: FavoriteDetailControllerDelegate {

    func dismissed(_ indexPath: IndexPath, reason: FavoriteDetailControllerDismissedReason) {
        switch reason {
        case .done(let favorite):
            favorites.update(index: indexPath.item, with: favorite)
            favoritesView.reloadItems(at: [indexPath])
            favoritesView.collectionViewLayout.invalidateLayout()

        case .cancel:
            break

        case .delete:
            favorites.remove(index: indexPath.item, bySwiping: false)
            break
        }

        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UICollectionViewDataSource

extension FavoritesViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        favorites.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        limitWidth(cell: update(cell: collectionView.dequeueReusableCell(for: indexPath),
                                with: favorites.getBy(index: indexPath.row)))
    }
}

// MARK: - UICollectionViewDelegate

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

// MARK: - UICollectionViewDelegateFlowLayout

extension FavoritesViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let favorite = favorites.getBy(index: indexPath.item)
        let cell = update(cell: favoriteCell, with: favorite)
        let size = cell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let constrainedSize = CGSize(width: min(size.width, collectionView.bounds.width), height: size.height)
        return constrainedSize
    }
}

// MARK: - FavoritesManager

extension FavoritesViewController: FavoritesViewManager {

    func addTarget(_ event: SwipingEvent, target: Any, action: Selector) {
        switch event {
        case .swipeLeft: swipeLeft.addTarget(target, action: action)
        case .swipeRight: swipeRight.addTarget(target, action: action)
        }
    }
}

// MARK: - Private

extension FavoritesViewController {

    private func indexPath(of favorite: Favorite) -> IndexPath {
        IndexPath(row: favorites.index(of: favorite), section: 0)
    }

    private func updateCell(with favorite: Favorite) {
        if let cell: FavoriteCell = favoritesView.cellForItem(at: indexPath(of: favorite)) {
            update(cell: cell, with: favorite)
        }
    }

    @discardableResult
    private func update(cell: FavoriteCell, with favorite: Favorite) -> FavoriteCell {
        cell.update(favoriteName: favorite.name, isActive: favorite.soundFontPatch == activePatchManager.soundFontPatch)
        return cell
    }

    private func limitWidth(cell: FavoriteCell) -> FavoriteCell {
        cell.maxWidth = cell.bounds.width - 15
        return cell
    }
}

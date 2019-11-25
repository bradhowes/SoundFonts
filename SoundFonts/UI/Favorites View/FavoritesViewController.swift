// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Manages the view of Favorite items. Users can choose a Favorite by tapping it in order to apply the Favorite
 settings. The user may long-touch on a Favorite to bring up an editing panel.
 */
final class FavoritesViewController: UIViewController, ControllerConfiguration {
    private lazy var logger = Logging.logger("FavVC")

    @IBOutlet private var favoritesView: UICollectionView!
    @IBOutlet private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    @IBOutlet var doubleTapGestureRecognizer: UITapGestureRecognizer!
    
    private var activePatchManager: ActivePatchManager!
    private var keyboardManager: KeyboardManager!
    private let favoriteCollection = FavoriteCollection.build()
    private var notifiers = [UUID: (FavoriteChangeKind, Favorite) -> Void]()
    private var favoriteCell: FavoriteCell!
    private var favoriteMover: FavoriteMover!

    private var swipeLeft = UISwipeGestureRecognizer()
    private var swipeRight = UISwipeGestureRecognizer()

    override func viewDidLoad() {
        favoritesView.register(FavoriteCell.self)
        favoritesView.dataSource = self
        favoritesView.delegate = self

        favoriteCell = FavoriteCell.nib.instantiate(withOwner: nil, options: nil)[0] as? FavoriteCell
        precondition(favoriteCell != nil, "failed to instantiate a FavoriteCell instance from nil")

        favoriteCell.translatesAutoresizingMaskIntoConstraints = false

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
        favoritesView!.setCollectionViewLayout(layout, animated: false)
    }

    func establishConnections(_ context: RunContext) {
        activePatchManager = context.activePatchManager
        keyboardManager = context.keyboardManager
        activePatchManager.addPatchChangeNotifier(self) { old, new in self.patchChanged(old, new) }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nc = segue.destination as? UINavigationController,
            let vc = nc.topViewController as? FavoriteDetailController,
            let cell = sender as? FavoriteCell,
            let indexPath = favoritesView.indexPath(for: cell) else { return }

        vc.delegate = self

        let favorite = favoriteCollection[indexPath.row]
        vc.editFavorite(favorite, position: indexPath, lowestNote: keyboardManager.lowestNote)
        
        // Now if showing a popover, position it in the right spot
        //
        if let ppc = nc.popoverPresentationController {
            ppc.barButtonItem = nil // !!! Muy importante !!!
            ppc.sourceView = cell
            
            // Focus on the indicator -- this may not be correct for all locales.
            let rect = cell.bounds
            ppc.sourceRect = view.convert(CGRect(origin: rect.offsetBy(dx: rect.width - 32, dy: 0).origin,
                                                 size: CGSize(width: 32.0, height: rect.height)), to: nil)
            // vc.preferredContentSize.width = self.preferredContentSize.width
        }
    }

    /**
     Event handler for the double-tap esture recognizer. We use this to begin editing a favorite.
     
     - parameter gr: the gesture recognizer that fired the event
     */
    @objc func handleTap(_ gr: UITapGestureRecognizer) {
        let pos = gr.location(in: view)
        guard let indexPath = favoritesView.indexPathForItem(at: pos) else { return }
        let cell = favoritesView.cellForItem(at: indexPath)!
        performSegue(withIdentifier: "favoriteDetail", sender: cell)
    }
    
    private func updateFavoriteCell(at indexPath: IndexPath, cell: FavoriteCell? = nil) {
        os_log(.info, log: logger, "updateFavoriteCell: %d.%d %s", indexPath.section, indexPath.row,
               cell?.description ?? "N/A")
        guard let aCell = (cell ?? (favoritesView.cellForItem(at: indexPath) as? FavoriteCell)) else {
            os_log(.info, log: logger, "updateFavoriteCell: no cell")
            return
        }

        let favorite = favoriteCollection[indexPath.row]
        aCell.update(name: favorite.name, isActive: favorite.patch == activePatchManager.activePatch)
    }

    private func patchChanged(_ old: Patch, _ new: Patch) {
        os_log(.info, log: logger, "patchChanged: %s, %s", old.description, new.description)
        if let fave = favoriteCollection.getFavorite(patch: old) {
            os_log(.info, log: logger, "updating prev cell - %s", fave.description)
            updateFavoriteCell(at: IndexPath(row: favoriteCollection.getIndex(of: fave), section: 0))
        }

        if let fave = favoriteCollection.getFavorite(patch: new) {
            os_log(.info, log: logger, "updating new cell - %s", fave.description)
            updateFavoriteCell(at: IndexPath(row: favoriteCollection.getIndex(of: fave), section: 0))
        }
    }

    private func selected(_ favorite: Favorite) {
        os_log(.info, log: logger, "setting active patch")
        activePatchManager.activePatch = favorite.patch

        os_log(.info, log: logger, "setting lowest note")
        keyboardManager.lowestNote = favorite.keyboardLowestNote
        notify(.selected, favorite)
    }
    
    private func notify(_ kind: FavoriteChangeKind, _ favorite: Favorite) {
        notifiers.values.forEach { $0(kind, favorite) }
    }
}

// MARK: - UICollectionViewDataSource
extension FavoritesViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favoriteCollection.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: FavoriteCell = collectionView.dequeueReusableCell(for: indexPath)
        updateFavoriteCell(at: indexPath, cell: cell)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FavoritesViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let favorite = favoriteCollection[indexPath.row]
        os_log(.info, log: logger, "selecting %d %s", indexPath.row, favorite.name)
        selected(favorite)
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return favoriteCollection.count > 1
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {
        favoriteCollection.move(from: sourceIndexPath.item, to: destinationIndexPath.item)
        collectionView.reloadItems(at: [sourceIndexPath, destinationIndexPath])
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FavoritesViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        updateFavoriteCell(at: indexPath, cell: favoriteCell)
        return favoriteCell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}

// MARK: - FavoriteDetailControllerDelegate
extension FavoritesViewController: FavoriteDetailControllerDelegate {
    func dismissed(_ indexPath: IndexPath, reason: FavoriteDetailControllerDismissedReason) {
        switch reason {
        case .done:
            let favorite = favoriteCollection[indexPath.row]
            favoritesView.collectionViewLayout.invalidateLayout()
            updateFavoriteCell(at: indexPath)
            notify(.changed, favorite)
            favoriteCollection.save()
        case .cancel:
            break
            
        case .delete:
            let favorite = self.favoriteCollection[indexPath.row]
            remove(patch: favorite.patch)
            break
        }

        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - FavoritesManager

extension FavoritesViewController: FavoritesManager {

    func addTarget(_ event: SwipingEvent, target: Any, action: Selector) {
        switch event {
        case .swipeLeft: swipeLeft.addTarget(target, action: action)
        case .swipeRight: swipeRight.addTarget(target, action: action)
        }
    }

    func isFavored(patch: Patch) -> Bool { return favoriteCollection.isFavored(patch: patch) }
    
    func add(patch: Patch, keyboardLowestNote: Note) {
        let favorite = Favorite(patch: patch, keyboardLowestNote: keyboardLowestNote)
        favoriteCollection.add(favorite)
        notify(.added, favorite)
        favoritesView.reloadData()
    }
    
    func remove(patch: Patch) {
        let favorite = favoriteCollection.remove(patch: patch)
        notify(.removed, favorite)
        favoritesView.reloadData()
    }

    func addFavoriteChangeNotifier<O: AnyObject>(_ observer: O, closure: @escaping Notifier<O>) -> NotifierToken {
        let uuid = UUID()
        let token = NotifierToken { [weak self] in self?.notifiers.removeValue(forKey: uuid) }
        notifiers[uuid] = { [weak observer] kind, favorite in
            if observer != nil {
                closure(kind, favorite)
            }
            else {
                token.cancel()
            }
        }

        return token
    }
    
    func removeNotifier(forKey key: UUID) {
        notifiers.removeValue(forKey: key)
    }
}

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
    private let favoriteCollection = FavoriteCollection.shared
    private var notifiers = [UUID: (FavoriteChangeKind) -> Void]()
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
        favoriteCell.translatesAutoresizingMaskIntoConstraints = true

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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        favoritesView.reloadData()
    }

    func establishConnections(_ context: RunContext) {
        activePatchManager = context.activePatchManager
        keyboardManager = context.keyboardManager
        activePatchManager.addPatchChangeNotifier(self) { old, new in self.patchChanged(old, new) }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nc = segue.destination as? UINavigationController,
            let vc = nc.topViewController as? FavoriteDetailController,
            let (favorite, view) = sender as? (Favorite, UIView) else { return }

        vc.delegate = self

        let indexPath = IndexPath(item: favoriteCollection.getIndex(of: favorite), section: 0)
        vc.editFavorite(favorite, position: indexPath, currentLowestNote: keyboardManager.lowestNote)

        // Now if showing a popover, position it in the right spot
        //
        if let ppc = nc.popoverPresentationController {

            ppc.barButtonItem = nil // !!! Muy importante !!!
            ppc.sourceView = view
            
            // Focus on the indicator -- this may not be correct for all locales.
            let rect = view.bounds
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
        let favorite = favoriteCollection[indexPath.row]
        let cell = favoritesView.cellForItem(at: indexPath)!
        edit(favorite: favorite, sender: cell)
    }

    func edit(favorite: Favorite, sender: UIView) {
        performSegue(withIdentifier: "favoriteDetail", sender: (favorite, sender))
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

    private func patchChanged(_ old: Patch?, _ new: Patch) {
        os_log(.info, log: logger, "patchChanged: %s, %s", old?.description ?? "nil", new.description)
        if let old = old {
            if let fave = favoriteCollection.getFavorite(patch: old) {
                os_log(.info, log: logger, "updating prev cell - %s", fave.description)
                updateFavoriteCell(at: IndexPath(row: favoriteCollection.getIndex(of: fave), section: 0))
            }
        }

        if let fave = favoriteCollection.getFavorite(patch: new) {
            os_log(.info, log: logger, "updating new cell - %s", fave.description)
            updateFavoriteCell(at: IndexPath(row: favoriteCollection.getIndex(of: fave), section: 0))
        }
    }

    private func selected(_ favorite: Favorite) {
        os_log(.info, log: logger, "setting active patch")
        activePatchManager.changePatch(kind: .favorite(favorite: favorite))

        os_log(.info, log: logger, "setting lowest note")
        keyboardManager.lowestNote = favorite.keyboardLowestNote
        notify(.selected(favorite))
    }
    
    private func notify(_ kind: FavoriteChangeKind) {
        notifiers.values.forEach { $0(kind) }
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
        let cell = collectionView.dequeueReusableCell(for: indexPath) as FavoriteCell
        updateFavoriteCell(at: indexPath, cell: cell)

        // Make sure that the label in the cell is constrained to the be within the cell bounds minus margin.
        cell.maxWidth = cell.bounds.width - 16
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

        // Make sure that the width of the cell is no bigger than the collectionView.
        let size = favoriteCell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let constrainedSize = CGSize(width: min(size.width, collectionView.bounds.width), height: size.height)
        return constrainedSize
    }
}

// MARK: - FavoriteDetailControllerDelegate
extension FavoritesViewController: FavoriteDetailControllerDelegate {
    func dismissed(_ indexPath: IndexPath, reason: FavoriteDetailControllerDismissedReason) {
        switch reason {
        case .done:
            let favorite = favoriteCollection[indexPath.row]
            favoritesView.reloadItems(at: [indexPath])
            favoritesView.collectionViewLayout.invalidateLayout()
            notify(.changed(favorite))
            favoriteCollection.save()
        case .cancel:
            break
            
        case .delete:
            let favorite = self.favoriteCollection[indexPath.row]
            remove(patch: favorite.patch, bySwiping: false)
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
        notify(.added(favorite))
        favoritesView.reloadData()
    }

    func remove(patch: Patch, bySwiping: Bool) {
        let favorite = favoriteCollection.remove(patch: patch)
        self.notify(.removed(favorite, bySwiping: bySwiping))
        favoritesView.reloadData()
    }

    func removeAll(associatedWith soundFont: SoundFont) {
        let favorites = favoriteCollection.removeAll(associatedWith: soundFont)
        favorites.forEach { self.notify(.removed($0, bySwiping: false)) }
        favoritesView.reloadData()
    }

    func count(associatedWith soundFont: SoundFont) -> Int {
        favoriteCollection.findAll(associatedWith: soundFont).count
    }

    func addFavoriteChangeNotifier<O: AnyObject>(_ observer: O, closure: @escaping Notifier<O>) -> NotifierToken {
        let uuid = UUID()
        let token = NotifierToken { [weak self] in self?.notifiers.removeValue(forKey: uuid) }
        notifiers[uuid] = { [weak observer] kind in
            if observer != nil {
                closure(kind)
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

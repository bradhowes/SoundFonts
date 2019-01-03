//
//  FavoritesManager.swift
//  SoundFonts
//
//  Created by Brad Howes on 12/22/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import UIKit

/**
 Manages the view of Favorite items. Users can choose a Favorite by tapping it in order to apply the Favorite
 settings. The user may long-touch on a Favorite to bring up an editing panel.
 */
final class FavoritesViewController: UIViewController, ControllerConfiguration {

    @IBOutlet private var favoritesView: UICollectionView!
    @IBOutlet private var longPressGestureRecognizer: UILongPressGestureRecognizer!

    private var activePatchManager: ActivePatchManager!
    private var keyboardManager: KeyboardManager!
    private let favoriteCollection = FavoriteCollection()
    private var notifiers = [(FavoriteChangeKind, Favorite)->Void]()

    override func viewDidLoad() {
        favoritesView.dataSource = self
        favoritesView.delegate = self

        longPressGestureRecognizer.minimumPressDuration = 0.5
        longPressGestureRecognizer.addTarget(self, action: #selector(handleLongPress))
    }

    func establishConnections(_ context: RunContext) {
        activePatchManager = context.activePatchManager
        keyboardManager = context.keyboardManager
        activePatchManager.addPatchChangeNotifier { patch in self.patchChanged(patch) }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nc = segue.destination as? UINavigationController,
            let vc = nc.topViewController as? FavoriteDetailController,
            let cell = sender as? FavoriteCell,
            let indexPath = favoritesView.indexPath(for: cell) else { return }

        vc.delegate = self

        let favorite = favoriteCollection[indexPath.row]
        vc.editFavorite(favorite, position: indexPath)
        
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
     Event handler for the long-press gesture recognizer.
    
     - parameter lpgr: the gesture recognizer that fired the event
     */
    @objc func handleLongPress(_ lpgr: UILongPressGestureRecognizer) {
        if lpgr.state != .began {
            return
        }

        let p = lpgr.location(in: view)
        if let indexPath = favoritesView.indexPathForItem(at: p) {
            let cell = favoritesView.cellForItem(at: indexPath)!
            performSegue(withIdentifier: "favoriteDetail", sender: cell)
        }
    }
    
    private func updateFavoriteCell(at indexPath: IndexPath, cell: FavoriteCell? = nil) {
        guard let cell = cell ?? favoritesView.cellForItem(at: indexPath) as? FavoriteCell else { return }
        let favorite = favoriteCollection[indexPath.row]
        cell.update(name: favorite.name, isActive: favorite.patch == activePatchManager.activePatch)
    }

    private func patchChanged(_ patch: Patch) {
        favoritesView.reloadData()
    }
    
    private func selected(_ favorite: Favorite) {
        let prevFave = favoriteCollection[activePatchManager.activePatch]
        activePatchManager.activePatch = favorite.patch
        keyboardManager.lowestNote = favorite.keyboardLowestNote
        if prevFave != nil {
            updateFavoriteCell(at: IndexPath(row: favoriteCollection.getIndex(of: prevFave!), section: 0))
        }
        updateFavoriteCell(at: IndexPath(row: favoriteCollection.getIndex(of: favorite), section: 0))
        notify(.selected, favorite)
    }
    
    private func notify(_ kind: FavoriteChangeKind, _ favorite: Favorite) {
        notifiers.forEach { $0(kind, favorite) }
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "favorite", for: indexPath) as! FavoriteCell
        updateFavoriteCell(at: indexPath, cell: cell)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FavoritesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let favorite = favoriteCollection[indexPath.row]
        selected(favorite)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FavoritesViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let favorite = favoriteCollection[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "favorite", for: indexPath) as! FavoriteCell
        cell.name.text = favorite.name
        let textSize = cell.name.sizeThatFits(CGSize(width: 1000.0, height: 1000.0))
        return CGSize(width: textSize.width + 48, height: textSize.height + 48)
    }
}

// MARK: - FavoriteDetailControllerDelegate
extension FavoritesViewController: FavoriteDetailControllerDelegate {
    func dismissed(_ indexPath: IndexPath, reason: FavoriteDetailControllerDismissedReason) {
        if reason == .done {
            let favorite = favoriteCollection[indexPath.row]
            favoritesView.collectionViewLayout.invalidateLayout()
            updateFavoriteCell(at: indexPath)
            notify(.changed, favorite)
            favoriteCollection.save()
        }

        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - FavoritesManager
extension FavoritesViewController: FavoritesManager {

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

    func addFavoriteChangeNotifier(_ notifier: @escaping (FavoriteChangeKind, Favorite) -> Void) {
        notifiers.append(notifier)
    }
}

// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 View controller for the SoundFont / Patches UITableView combination. Much of the UITableView management is handled
 by specific *DataSource classes. This controller mainly serves to manage the active Patch state, plus the switching
 between normal Patch table view display and Patch search results display. Apart from the adopted protocols, there is no
 API for this class.

 Perhaps this should be split into two, one for a soundfont view, and one for the patches view.
 */
final class SoundFontsViewController: UIViewController {
    private lazy var logger = Logging.logger("SFVC")

    @IBOutlet private weak var soundFontsView: UITableView!
    @IBOutlet private weak var patchesView: UITableView!
    @IBOutlet private weak var searchBar: UISearchBar!

    private var soundFonts: SoundFonts!
    private var soundFontsTableViewDataSource: FontsTableViewDataSource!
    private var patchesTableViewDataSource: PatchesTableViewDataSource!
    private var activePatchManager: ActivePatchManager!
    private var favorites: Favorites!

    private var swipeLeft = UISwipeGestureRecognizer()
    private var swipeRight = UISwipeGestureRecognizer()

    override func viewDidLoad() {
        super.viewDidLoad()

        swipeLeft.direction = .left
        swipeLeft.numberOfTouchesRequired = 2
        view.addGestureRecognizer(swipeLeft)

        swipeRight.direction = .right
        swipeRight.numberOfTouchesRequired = 2
        view.addGestureRecognizer(swipeRight)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nc = segue.destination as? UINavigationController,
            let vc = nc.topViewController as? FontEditor,
            let cell = sender as? FontCell,
            let indexPath = soundFontsView.indexPath(for: cell) else { return }

        vc.delegate = self

        let soundFont = soundFonts.getBy(index: indexPath.row)
        vc.edit(soundFont: soundFont, favoriteCount: favorites.count(associatedWith: soundFont),
                position: indexPath)

        if let ppc = nc.popoverPresentationController {
            ppc.barButtonItem = nil
            ppc.sourceView = cell
            let rect = cell.bounds
            ppc.sourceRect = view.convert(CGRect(origin: rect.offsetBy(dx: rect.width - 32, dy: 0).origin,
                                                 size: CGSize(width: 32.0, height: rect.height)), to: nil)
        }
    }
}

// MARK: - ControllerConfiguration

extension SoundFontsViewController: ControllerConfiguration {

    func establishConnections(_ router: Router) {
        soundFonts = router.soundFonts
        activePatchManager = router.activePatchManager
        favorites = router.favorites

        soundFontsTableViewDataSource = FontsTableViewDataSource(view: soundFontsView,
                                                                 selectedSoundFontManager: router.selectedSoundFontManager,
                                                                 activePatchManager: router.activePatchManager,
                                                                 soundFontEditor: self,
                                                                 soundFonts: router.soundFonts)
        patchesTableViewDataSource = PatchesTableViewDataSource(view: patchesView,
                                                                searchBar: searchBar,
                                                                activePatchManager: router.activePatchManager,
                                                                selectedSoundFontManager: router.selectedSoundFontManager,
                                                                favorites: favorites,
                                                                keyboard: router.keyboard)
    }
}

extension SoundFontsViewController: PatchesViewManager {

    /**
     Attach an event notification to the given object/selector pair so that future events will invoke the selector.

     - parameter event: the event to attach to
     - parameter target: the object to notify
     - parameter action: the selector to invoke
     */
    func addTarget(_ event: SwipingEvent, target: Any, action: Selector) {
        switch event {
        case .swipeLeft: swipeLeft.addTarget(target, action: action)
        case .swipeRight: swipeRight.addTarget(target, action: action)
        }
    }

    func dismissSearchKeyboard() {
        if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
            searchBar.resignFirstResponder()
        }
    }
}

extension SoundFontsViewController: SoundFontEditor {

    func createEditSwipeAction(at cell: FontCell, with soundFont: SoundFont) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: nil) {
            (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
            self.performSegue(withIdentifier: "soundFontDetail", sender: cell)
            completionHandler(true)
        }

        action.image = UIImage(named: "Edit")
        action.backgroundColor = UIColor.orange
        return action
    }

    func createDeleteSwipeAction(at cell: FontCell, with soundFont: SoundFont, indexPath: IndexPath) -> UIContextualAction {
        let promptTitle = NSLocalizedString("DeleteFontTitle", comment: "Title of confirmation prompt")
        let promptMessage = NSLocalizedString("DeleteFontMessage", comment: "Body of confirmation prompt")
        let action = UIContextualAction(style: .destructive, title: nil) { (_, _, completionHandler) in
            let alertController = UIAlertController(title: promptTitle, message: promptMessage, preferredStyle: .alert)

            let deleteTitle = NSLocalizedString("Delete", comment: "The delete action")
            let delete = UIAlertAction(title: deleteTitle, style:.destructive) { action in
                self.soundFonts.remove(index: indexPath.row)
                completionHandler(true)
            }

            let cancelTitle = NSLocalizedString("Cancel", comment: "The cancel action")
            let cancel = UIAlertAction(title: cancelTitle, style:.cancel) { action in
                completionHandler(false)
            }

            alertController.addAction(delete)
            alertController.addAction(cancel)

            if let popoverController = alertController.popoverPresentationController {
              popoverController.sourceView = self.view
              popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY,
                                                    width: 0, height: 0)
              popoverController.permittedArrowDirections = []
            }

            self.present(alertController, animated: true, completion: nil)
        }

        action.image = UIImage(named: "Trash")
        action.backgroundColor = UIColor.red

        return action
    }
}

// MARK: - SoundFontDetailControllerDelegate

extension SoundFontsViewController: SoundFontDetailControllerDelegate {
    func dismissed(reason: SoundFontDetailControllerDismissedReason) {
        switch reason {
        case let .done(index, newName):
            soundFonts.rename(index: index, name: newName)

        case let .delete(_, soundFont):
            print("delete \(soundFont.displayName)")

        default:
            break
        }

        self.dismiss(animated: true, completion: nil)
    }
}



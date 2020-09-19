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
public final class SoundFontsViewController: UIViewController {
    private lazy var log = Logging.logger("SFVC")

    @IBOutlet private weak var soundFontsView: UITableView!
    @IBOutlet private weak var patchesView: UITableView!
    @IBOutlet private weak var searchBar: UISearchBar!

    private var soundFonts: SoundFonts!
    private var soundFontsTableViewDataSource: FontsTableViewManager!
    private var patchesTableViewDataSource: PatchesTableViewManager!
    private var favorites: Favorites!
    private var selectedSoundFontManager: SelectedSoundFontManager!
    private var keyboard: Keyboard?

    private var swipeLeft = UISwipeGestureRecognizer()
    private var swipeRight = UISwipeGestureRecognizer()

    public override func viewDidLoad() {
        super.viewDidLoad()

        swipeLeft.direction = .left
        swipeLeft.numberOfTouchesRequired = 2
        view.addGestureRecognizer(swipeLeft)

        swipeRight.direction = .right
        swipeRight.numberOfTouchesRequired = 2
        view.addGestureRecognizer(swipeRight)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        soundFontsTableViewDataSource.selectActive()
        patchesTableViewDataSource.selectActive()
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        patchesTableViewDataSource.hideSearchBar()
    }

    private func addSoundFont() {
        let documentPicker = UIDocumentPickerViewController(
            documentTypes: ["com.braysoftware.sf2", "com.soundblaster.soundfont"], in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .fullScreen
        documentPicker.allowsMultipleSelection = true

        present(documentPicker, animated: true)
    }

    private func remove(soundFont: LegacySoundFont, completionHandler: ((_ completed: Bool) -> Void)?) {
        guard let index = soundFonts.index(of: soundFont.key) else {
            completionHandler?(false)
            return
        }

        let promptTitle = "DeleteFontTitle".localized(comment: "Title of confirmation prompt")
        let promptMessage = "DeleteFontMessage".localized(comment: "Body of confirmation prompt")
        let alertController = UIAlertController(title: promptTitle, message: promptMessage, preferredStyle: .alert)
        let deleteTitle = "Delete".localized(comment: "The delete action")

        let delete = UIAlertAction(title: deleteTitle, style: .destructive) { _ in
            self.soundFonts.remove(index: index)
            self.favorites.removeAll(associatedWith: soundFont)
            let url = soundFont.fileURL
            if soundFont.removable {
                DispatchQueue.global(qos: .userInitiated).async { try? FileManager.default.removeItem(at: url) }
            }
            completionHandler?(true)
        }

        let cancelTitle = "Cancel".localized(comment: "The cancel action")
        let cancel = UIAlertAction(title: cancelTitle, style: .cancel) { _ in completionHandler?(false) }

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

    public func reload() {
        soundFontsView.reloadData()
        patchesView.reloadData()
    }
}

extension SoundFontsViewController: UIDocumentPickerDelegate {

    public func documentPicker(_ dpvc: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        os_log(.info, log: log, "documentPicker didPickDocumentAt")
        for each in urls {
            let name = each.lastPathComponent
            os_log(.info, log: log, "processing %s", each.path)
            let alert: UIAlertController = {
                switch soundFonts.add(url: each) {
                case .success(let (_, soundFont)):
                    return UIAlertController(
                        title: "Added",
                        message: "\(name)\n\nNew SoundFont added under the name '\(soundFont.displayName)'",
                        preferredStyle: .alert)
                case .failure(let failure):
                    let reason: String = {
                        switch failure {
                        case .emptyFile: return "\(name)\n\nThe SF2 file must be downloaded before adding."
                        case .invalidSoundFont: return "\(name)\n\nThe SF2 file is invalid and cannot be used."
                        case .unableToCreateFile: return "\(name)\n\nNot enough space to keep the SF2 file."
                        }
                    }()
                    return UIAlertController(
                        title: "Add Failure",
                        message: reason,
                        preferredStyle: .alert)
                }
            }()

            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - ControllerConfiguration Protocol

extension SoundFontsViewController: ControllerConfiguration {

    public func establishConnections(_ router: ComponentContainer) {
        soundFonts = router.soundFonts
        favorites = router.favorites
        keyboard = router.keyboard
        selectedSoundFontManager = router.selectedSoundFontManager

        soundFontsTableViewDataSource = FontsTableViewManager(
            view: soundFontsView, selectedSoundFontManager: selectedSoundFontManager,
            activePatchManager: router.activePatchManager, fontEditorActionGenerator: self,
            soundFonts: router.soundFonts)
        patchesTableViewDataSource = PatchesTableViewManager(
            view: patchesView, searchBar: searchBar, activePatchManager: router.activePatchManager,
            selectedSoundFontManager: selectedSoundFontManager, favorites: favorites,
            keyboard: router.keyboard,
            sampler: router.sampler)

        router.infoBar.addEventClosure(.addSoundFont) { self.addSoundFont() }
    }
}

// MARK: - PatchesViewManager Protocol

extension SoundFontsViewController: PatchesViewManager {

    /**
     Attach an event notification to the given object/selector pair so that future events will invoke the selector.

     - parameter event: the event to attach to
     - parameter target: the object to notify
     - parameter action: the selector to invoke
     */
    public func addEventClosure(_ event: UpperViewSwipingEvent, _ closure: @escaping () -> Void) {
        switch event {
        case .swipeLeft: swipeLeft.addClosure(closure)
        case .swipeRight: swipeRight.addClosure(closure)
        }
    }

    public func dismissSearchKeyboard() {
        if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
            searchBar.resignFirstResponder()
        }
    }
}

// MARK: - FontEditorActionGenerator Protocol

extension SoundFontsViewController: FontEditorActionGenerator {

    /**
     Create right-swipe action to edit a SoundFont.

     - parameter at: the FontCell that will hold the swipe action
     - parameter with: the SoundFont that will be edited by the swipe action
     - returns: new UIContextualAction that will perform the edit
     */
    public func createEditSwipeAction(at: IndexPath, cell: TableCell, soundFont: LegacySoundFont) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: nil) { action, view, completionHandler in
            let config = FontEditor.Config(indexPath: at, view: view, rect: view.bounds, soundFont: soundFont,
                                           favoriteCount: self.favorites.count(associatedWith: soundFont),
                                           completionHandler: completionHandler)
            self.performSegue(withIdentifier: .fontEditor, sender: config)
        }

        action.image = getActionImage("Edit")
        action.backgroundColor = UIColor.orange
        action.accessibilityLabel = "FontEditButton"
        action.isAccessibilityElement = true
        return action
    }

    /**
     Create left-swipe action to *delete* a SoundFont. When activated, the action will display a prompt to the user
     asking for confirmation about the SoundFont deletion.

     - parameter at: the FontCell that will hold the swipe action
     - parameter with: the SoundFont that will be edited by the swipe action
     - parameter indexPath: the IndexPath of the FontCell that would be removed by the action
     - returns: new UIContextualAction that will perform the edit
     */
    public func createDeleteSwipeAction(at: IndexPath, cell: TableCell, soundFont: LegacySoundFont) -> UIContextualAction {
        let action = UIContextualAction(style: .destructive, title: nil) { action, view, completionHandler in
            self.remove(soundFont: soundFont, completionHandler: completionHandler)
        }

        action.image = getActionImage("Trash")
        action.backgroundColor = UIColor.red
        return action
    }

    private func getActionImage(_ name: String) -> UIImage? {
        return UIImage(named: name, in: Bundle(for: Self.self), compatibleWith: .none)
    }
}

extension SoundFontsViewController: SegueHandler {

    /// Segues that we support.
    public enum SegueIdentifier: String {
        case fontEditor
        case fontBrowser
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .fontEditor:
            guard let config = sender as? FontEditor.Config else {
                fatalError("expected FontEditor.Config")
            }
            prepareToEdit(segue, config: config)

        case .fontBrowser:
            break
        }
    }

    private func prepareToEdit(_ segue: UIStoryboardSegue, config: FontEditor.Config) {
        guard let nc = segue.destination as? UINavigationController,
            let vc = nc.topViewController as? FontEditor else {
                return
        }

        vc.delegate = self
        vc.configure(config)

        if keyboard == nil {
            vc.modalPresentationStyle = .fullScreen
            nc.modalPresentationStyle = .fullScreen
        }

        if let ppc = nc.popoverPresentationController {
            ppc.sourceView = config.view
            ppc.sourceRect = config.rect
            ppc.permittedArrowDirections = [.up, .down]
            ppc.delegate = vc
        }

        // Doing this will catch the swipe-down action that we treat as a 'cancel'.
        nc.presentationController?.delegate = vc
    }
}

// MARK: - FontEditorDelegate Protocol

extension SoundFontsViewController: FontEditorDelegate {
    public func dismissed(reason: FontEditorDismissedReason) {
        if case let .done(index, soundFont) = reason {
            soundFonts.rename(index: index, name: soundFont.displayName)
        }
        self.dismiss(animated: true, completion: nil)
    }
}

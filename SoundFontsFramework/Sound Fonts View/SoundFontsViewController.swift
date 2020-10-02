// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 View controller for the SoundFont / Patches UITableView combination. Much of the UITableView management is handled
 by specific *Manager classes. This controller mainly serves to manage the active Patch state, plus the switching
 between normal Patch table view display and Patch search results display. Apart from the adopted protocols, there is no
 API for this class.
 */
public final class SoundFontsViewController: UIViewController {
    private lazy var log = Logging.logger("SFVC")

    @IBOutlet private weak var soundFontsView: UITableView!
    @IBOutlet private weak var patchesView: UITableView!
    @IBOutlet private weak var visibilityView: UITableView!
    @IBOutlet private weak var searchBar: UISearchBar!

    private var soundFonts: SoundFonts!
    private var soundFontsTableViewDataSource: FontsTableViewManager!
    private var patchesTableViewDataSource: PatchesTableViewManager!
    private var favorites: Favorites!
    private var selectedSoundFontManager: SelectedSoundFontManager!
    private var keyboard: Keyboard?

    public var swipeLeft = UISwipeGestureRecognizer()
    public var swipeRight = UISwipeGestureRecognizer()

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
        patchesTableViewDataSource.selectActive(animated: false)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
        }, completion: { _ in
            self.soundFontsTableViewDataSource.selectActive()
            self.patchesTableViewDataSource.selectActive(animated: false)
        })
    }

    private func addSoundFont() {
        let documentPicker = UIDocumentPickerViewController(
            documentTypes: ["com.braysoftware.sf2", "com.soundblaster.soundfont"], in: .import)
        documentPicker.delegate = self
        if #available(iOS 13, *) {
            documentPicker.modalPresentationStyle = .automatic
        } else {
            documentPicker.modalPresentationStyle = .overFullScreen
        }
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
        addSoundFonts(urls: urls)
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
            view: patchesView, visibilityView: visibilityView, searchBar: searchBar, activePatchManager: router.activePatchManager,
            selectedSoundFontManager: selectedSoundFontManager, soundFonts: soundFonts, favorites: favorites, keyboard: router.keyboard, infoBar: router.infoBar)

        router.infoBar.addEventClosure(.addSoundFont) { self.addSoundFont() }
    }
}

// MARK: - PatchesViewManager Protocol

extension SoundFontsViewController: PatchesViewManager {

    public func dismissSearchKeyboard() {
        if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
            searchBar.resignFirstResponder()
        }
    }

    public func addSoundFonts(urls: [URL]) {
        guard !urls.isEmpty else { return }
        var ok = [String]()
        var failures = [SoundFontFileLoadFailure]()
        for each in urls {
            os_log(.info, log: log, "processing %s", each.path)
            switch soundFonts.add(url: each) {
            case .success(let (_, soundFont)):
                ok.append(soundFont.fileURL.lastPathComponent)
            case .failure(let failure):
                failures.append(failure)
            }
        }

        if urls.count > 1 || !failures.isEmpty {
            let message = Formatters.addSoundFontDoneMessage(ok: ok, failures: failures, total: urls.count)
            let alert = UIAlertController(
                title: "Add SoundFont",
                message: message,
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
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
        let action = UIContextualAction(tag: "Edit", color: .orange) { _, view, completionHandler in
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
        let action = UIContextualAction(style: .destructive, title: nil) { _, _, completionHandler in
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

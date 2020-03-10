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
public final class SoundFontsViewController: UIViewController, SegueHandler {
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

    public enum SegueIdentifier: String {
        case fontEditor
        case fontBrowser
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .fontEditor: beginEditFont(segue, sender: sender)
        case .fontBrowser: beginBrowseFont(segue, sender: sender)
        }
    }

    private func beginEditFont(_ segue: UIStoryboardSegue, sender: Any?) {
        guard let nc = segue.destination as? UINavigationController,
            let vc = nc.topViewController as? FontEditor,
            let cell = sender as? FontCell,
            let indexPath = soundFontsView.indexPath(for: cell) else { return }
        vc.delegate = self
        let soundFont = soundFonts.getBy(index: indexPath.row)
        vc.edit(soundFont: soundFont, favoriteCount: favorites.count(associatedWith: soundFont), position: indexPath)
        if keyboard == nil {
            vc.modalPresentationStyle = .fullScreen
            nc.modalPresentationStyle = .fullScreen
        }
        nc.popoverPresentationController?.setSourceView(cell)
    }

    private func beginBrowseFont(_ segue: UIStoryboardSegue, sender: Any?) {
        guard let nc = segue.destination as? UINavigationController,
            (nc.topViewController as? UIDocumentPickerViewController) != nil,
            let button = sender as? UIButton else { return }
        nc.popoverPresentationController?.setSourceView(button)
    }

    @IBAction
    public func addSoundFont(_ sender: UIButton) {
        let documentPicker = UIDocumentPickerViewController(
            documentTypes: ["com.braysoftware.sf2", "com.soundblaster.soundfont"], in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .fullScreen
        documentPicker.allowsMultipleSelection = true

        present(documentPicker, animated: true)
    }

    private func remove(soundFont: SoundFont, completionHandler: ((_ completed: Bool) -> Void)?) {
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
            os_log(.info, log: log, "processing %s", each.path)
            if let result = soundFonts.add(url: each) {
                os_log(.info, log: log, "soundFonts.add - %d %s", result.0, result.1.description)
            }
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
            keyboard: router.keyboard)

        router.infoBar.addTarget(.addSoundFont, target: self, action: #selector(addSoundFont(_:)))
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
    public func addTarget(_ event: UpperViewSwipingEvent, target: Any, action: Selector) {
        switch event {
        case .swipeLeft: swipeLeft.addTarget(target, action: action)
        case .swipeRight: swipeRight.addTarget(target, action: action)
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
    public func createEditSwipeAction(at cell: FontCell, with soundFont: SoundFont) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: nil) { _, _, completionHandler in
            self.performSegue(withIdentifier: .fontEditor, sender: cell)
            completionHandler(true)
        }

        action.image = getActionImage("Edit")
        action.backgroundColor = UIColor.orange
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
    public func createDeleteSwipeAction(at cell: FontCell, with soundFont: SoundFont,
                                 indexPath: IndexPath) -> UIContextualAction {
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

// MARK: - FontEditorDelegate Protocol

extension SoundFontsViewController: FontEditorDelegate {
    public func dismissed(reason: FontEditorDismissedReason) {
        if case let .done(index, soundFont) = reason {
            soundFonts.rename(index: index, name: soundFont.displayName)
        }
        self.dismiss(animated: true, completion: nil)
    }
}

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
    @IBOutlet private weak var tagsView: UITableView!
    @IBOutlet private weak var patchesView: UITableView!
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var tagsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tagsBottomConstraint: NSLayoutConstraint!

    private var maxTagsViewHeightConstraint: CGFloat = 0.0
    private var soundFonts: SoundFonts!
    private var favorites: Favorites!
    private var infoBar: InfoBar!
    private var tagsManager: LegacyTagsManager!

    private var fontsTableViewManager: FontsTableViewManager!
    private var patchesTableViewManager: PatchesTableViewManager!
    private var tagsTableViewManager: TagsTableViewManager!
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

        maxTagsViewHeightConstraint = tagsViewHeightConstraint.constant
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fontsTableViewManager.selectActive()
        patchesTableViewManager.selectActive(animated: false)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if showingTags {
            hideTags()
        }

        coordinator.animate(alongsideTransition: { _ in
        }, completion: { _ in
            self.fontsTableViewManager.selectActive()
            self.patchesTableViewManager.selectActive(animated: false)
        })
    }

    private func addSoundFont(_ button: AnyObject) {
        let documentPicker = UIDocumentPickerViewController(
            documentTypes: ["com.braysoftware.sf2", "com.soundblaster.soundfont"],
            in: Settings.shared.copyFilesWhenAdding ? .import : .open)
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
        let promptTitle = "DeleteFontTitle".localized(comment: "Title of confirmation prompt")
        let promptMessage = "DeleteFontMessage".localized(comment: "Body of confirmation prompt")
        let alertController = UIAlertController(title: promptTitle, message: promptMessage, preferredStyle: .alert)
        let deleteTitle = "Delete".localized(comment: "The delete action")

        let delete = UIAlertAction(title: deleteTitle, style: .destructive) { _ in
            self.soundFonts.remove(key: soundFont.key)
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

        present(alertController, animated: true, completion: nil)
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
        infoBar = router.infoBar
        tagsManager = router.tagsManager

        fontsTableViewManager = FontsTableViewManager(
            view: soundFontsView, selectedSoundFontManager: selectedSoundFontManager,
            activePatchManager: router.activePatchManager, fontEditorActionGenerator: self,
            soundFonts: router.soundFonts, tags: tagsManager)

        patchesTableViewManager = PatchesTableViewManager(
            view: patchesView, searchBar: searchBar, activePatchManager: router.activePatchManager,
            selectedSoundFontManager: selectedSoundFontManager, soundFonts: soundFonts,
            favorites: favorites, keyboard: router.keyboard, infoBar: router.infoBar, delay: router.delay,
            reverb: router.reverb)

        tagsTableViewManager = TagsTableViewManager(view: tagsView, tagsManager: router.tagsManager,
                                                    tagsHider: self.hideTags)

        router.infoBar.addEventClosure(.addSoundFont, self.addSoundFont)
        router.infoBar.addEventClosure(.showTags, self.toggleShowTags)
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
            os_log(.info, log: log, "processing %{public}s", each.path)
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
    public func createEditSwipeAction(at: IndexPath, cell: TableCell,
                                      soundFont: LegacySoundFont) -> UIContextualAction {
        let action = UIContextualAction(tag: "Edit", color: .orange) { _, view, completionHandler in
            let config = FontEditor.Config(indexPath: at, view: view, rect: view.bounds, soundFonts: self.soundFonts,
                                           soundFontKey: soundFont.key,
                                           favoriteCount: self.favorites.count(associatedWith: soundFont),
                                           tagsManager: self.tagsManager,
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
    public func createDeleteSwipeAction(at: IndexPath, cell: TableCell,
                                        soundFont: LegacySoundFont) -> UIContextualAction {
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
        guard let navController = segue.destination as? UINavigationController,
              let viewController = navController.topViewController as? FontEditor else {
            return
        }

        viewController.delegate = self
        viewController.configure(config)

        if keyboard == nil {
            viewController.modalPresentationStyle = .fullScreen
            navController.modalPresentationStyle = .fullScreen
        }

        if let ppc = navController.popoverPresentationController {
            ppc.sourceView = config.view
            ppc.sourceRect = config.rect
            ppc.permittedArrowDirections = [.up, .down]
            ppc.delegate = viewController
        }

        navController.presentationController?.delegate = viewController
    }
}

// MARK: - FontEditorDelegate Protocol

extension SoundFontsViewController: FontEditorDelegate {
    public func dismissed(reason: FontEditorDismissedReason) {
        if case let .done(soundFontKey) = reason {
            guard let soundFont = soundFonts.getBy(key: soundFontKey) else { return }
            soundFonts.rename(key: soundFontKey, name: soundFont.displayName)
        }
        self.dismiss(animated: true, completion: nil)
    }
}

extension SoundFontsViewController {

    private var showingTags: Bool { tagsBottomConstraint.constant == 0.0 }

    private func toggleShowTags(_ sender: AnyObject) {
        let button = sender as? UIButton
        if tagsBottomConstraint.constant == 0.0 {
            hideTags()
        }
        else {
            button?.tintColor = .systemOrange
            tagsTableViewManager.refresh()
            showTags()
        }
    }

    private func showTags() {
        let maxHeight = soundFontsView.frame.height - 8
        let midHeight = maxHeight / 2.0
        let minHeight = CGFloat(120.0)

        var bestHeight = midHeight
        if bestHeight > maxHeight { bestHeight = maxHeight }
        if bestHeight < minHeight { bestHeight = maxHeight }

        self.tagsViewHeightConstraint.constant = bestHeight
        self.tagsBottomConstraint.constant = 0.0
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.25, delay: 0.0,
                                                       options: [.allowUserInteraction, .curveEaseIn],
                                                       animations: self.view.layoutIfNeeded)
    }

    private func hideTags() {
        infoBar.resetButtonState(.showTags)
        self.tagsViewHeightConstraint.constant = maxTagsViewHeightConstraint
        self.tagsBottomConstraint.constant = tagsViewHeightConstraint.constant + 8
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.25, delay: 0.0,
                                                       options: [.allowUserInteraction, .curveEaseOut],
                                                       animations: self.view.layoutIfNeeded)
    }
}

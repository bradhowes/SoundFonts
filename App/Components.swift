// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import SoundFontsFramework

/**
 Collection of UIViewControllers and protocol facades which helps establish inter-controller relationships during the
 application launch. Each view controller is responsible for establishing the connections in their
 `establishConnections` method. The goal should be to have relations between a controller and protocols / facades, and
 not between controllers themselves. This is enforced here through access restrictions to known controllers.
 */
final class Components<T: UIViewController>: ComponentContainer where T: ControllerConfiguration {

    let sharedStateMonitor: SharedStateMonitor
    let soundFonts: SoundFonts
    let favorites: Favorites
    let activePatchManager: ActivePatchManager
    let selectedSoundFontManager: SelectedSoundFontManager

    private(set) var mainViewController: T! { didSet { oneTimeSet(oldValue) } }

    private var soundFontsControlsController: SoundFontsControlsController! { didSet { oneTimeSet(oldValue) } }
    private var infoBarController: InfoBarController! { didSet { oneTimeSet(oldValue) } }
    private var keyboardController: KeyboardController! { didSet { oneTimeSet(oldValue) } }

    private var soundFontsController: SoundFontsViewController! { didSet { oneTimeSet(oldValue) } }
    private var favoritesController: FavoritesViewController! { didSet { oneTimeSet(oldValue) } }

    var infoBar: InfoBar { infoBarController }
    var keyboard: Keyboard? { keyboardController }
    var patchesViewManager: PatchesViewManager { soundFontsController }
    var favoritesViewManager: FavoritesViewManager { favoritesController }
    var fontEditorActionGenerator: FontEditorActionGenerator { soundFontsController }

    init(sharedStateMonitor: SharedStateMonitor) {
        self.sharedStateMonitor = sharedStateMonitor
        self.soundFonts = SoundFontsManager(sharedStateMonitor: sharedStateMonitor)
        self.favorites = FavoritesManager(sharedStateMonitor: sharedStateMonitor)
        self.activePatchManager = ActivePatchManager(soundFonts: soundFonts)
        self.selectedSoundFontManager = SelectedSoundFontManager(activePatchManager: activePatchManager)
    }

    func addMainController(_ mc: T) {
        mainViewController = mc
        for obj in mc.children {
            switch obj {
            case let vc as SoundFontsControlsController:
                soundFontsControlsController = vc
                for inner in vc.children {
                    switch inner {
                    case let vc as InfoBarController: infoBarController = vc
                    case let vc as SoundFontsViewController: soundFontsController = vc
                    case let vc as FavoritesViewController: favoritesController = vc
                    default: assertionFailure("unknown child UIViewController")
                    }
                }
            case let vc as KeyboardController: keyboardController = vc
            default: assertionFailure("unknown child UIViewController")
            }
        }

        validate()
        establishConnections()
        sharedStateMonitor.delegate = self
    }

    /**
     Invoke `establishConnections` on each tracked view controller.
     */
    func establishConnections() {
        soundFontsController.establishConnections(self)
        favoritesController.establishConnections(self)
        infoBarController.establishConnections(self)
        keyboardController.establishConnections(self)
        soundFontsControlsController.establishConnections(self)
        mainViewController.establishConnections(self)
    }
}

extension Components: SharedStateMonitorDelegate {

    func favoritesChangedNotification() {
        favorites.reload()
        favoritesController.reload()
    }

    func soundFontsChangedNotification() {
        soundFonts.reload()
        soundFontsController.reload()
    }
}

extension Components {

    private func validate() {
        precondition(mainViewController != nil, "nil MainViewController")
        precondition(soundFontsControlsController != nil, "nil SoundFontsControlsController")
        precondition(soundFontsController != nil, "nil SoundFontsViewController")
        precondition(favoritesController != nil, "nil FavoritesViewController")
        precondition(infoBarController != nil, "nil InfoBarController")
        precondition(keyboardController != nil, "nil KeyboardController")
    }

    private func oneTimeSet<T>(_ oldValue: T?) {
        if oldValue != nil {
            preconditionFailure("expected nil value")
        }
    }
}

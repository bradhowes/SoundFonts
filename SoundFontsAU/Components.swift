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

    let soundFonts: SoundFonts = SoundFontsManager()
    let favorites: Favorites = FavoritesManager()

    lazy var activePatchManager = ActivePatchManager(soundFonts: soundFonts)
    lazy var selectedSoundFontManager = SelectedSoundFontManager(activePatchManager: activePatchManager)

    private(set) var mainViewController: T! { didSet { oneTimeSet(oldValue) } }

    private var soundFontsControlsController: SoundFontsControlsController! { didSet { oneTimeSet(oldValue) } }
    private var infoBarController: InfoBarController! { didSet { oneTimeSet(oldValue) } }

    private var soundFontsController: SoundFontsViewController! { didSet { oneTimeSet(oldValue) } }
    private var favoritesController: FavoritesViewController! { didSet { oneTimeSet(oldValue) } }

    var infoBar: InfoBar { infoBarController }
    var patchesViewManager: PatchesViewManager { soundFontsController }
    var favoritesViewManager: UpperViewSwipingActivity { favoritesController }
    var fontEditorActionGenerator: FontEditorActionGenerator { soundFontsController }

    var keyboard: Keyboard? { return nil }

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
            default: assertionFailure("unknown child UIViewController")
            }
        }

        validate()
        establishConnections()
    }

    /**
     Invoke `establishConnections` on each tracked view controller.
     */
    func establishConnections() {
        soundFontsController.establishConnections(self)
        favoritesController.establishConnections(self)
        infoBarController.establishConnections(self)
        soundFontsControlsController.establishConnections(self)
        mainViewController.establishConnections(self)
    }
}

extension Components {

    private func validate() {
        precondition(mainViewController != nil, "nil MainViewController")
        precondition(soundFontsControlsController != nil, "nil SoundFontsControlsController")
        precondition(soundFontsController != nil, "nil SoundFontsViewController")
        precondition(favoritesController != nil, "nil FavoritesViewController")
        precondition(infoBarController != nil, "nil InfoBarController")
    }

    private func oneTimeSet<T>(_ oldValue: T?) {
        if oldValue != nil {
            preconditionFailure("expected nil value")
        }
    }
}

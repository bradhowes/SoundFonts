// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Collection of UIViewControllers and protocol facades which helps establish inter-controller relationships during the
 application launch. Each view controller is responsible for establishing the connections in their
 `establishConnections` method. The goal should be to have relations between a controller and protocols / facades, and
 not between controllers themselves. This is enforced here through access restrictions to known controllers.
 */
public final class Components<T: UIViewController>: ComponentContainer where T: ControllerConfiguration {

    public let askForReview: AskForReview
    public let sharedStateMonitor: SharedStateMonitor
    public let soundFonts: SoundFonts
    public let favorites: Favorites
    public let activePatchManager: ActivePatchManager
    public let selectedSoundFontManager: SelectedSoundFontManager
    public let sampler: Sampler

    public private(set) var mainViewController: T! { didSet { oneTimeSet(oldValue) } }
    private var soundFontsControlsController: SoundFontsControlsController! { didSet { oneTimeSet(oldValue) } }
    private var infoBarController: InfoBarController! { didSet { oneTimeSet(oldValue) } }
    private var keyboardController: KeyboardController? { didSet { oneTimeSet(oldValue) } }
    private var soundFontsController: SoundFontsViewController! { didSet { oneTimeSet(oldValue) } }
    private var favoritesController: FavoritesViewController! { didSet { oneTimeSet(oldValue) } }
    private var guideController: GuideViewController! { didSet { oneTimeSet(oldValue) } }
    private var envelopeViewController: EnvelopeViewController! { didSet { oneTimeSet(oldValue )}}

    public var infoBar: InfoBar { infoBarController }
    public var keyboard: Keyboard? { keyboardController }
    public var patchesViewManager: PatchesViewManager { soundFontsController }
    public var favoritesViewManager: FavoritesViewManager { favoritesController }
    public var fontEditorActionGenerator: FontEditorActionGenerator { soundFontsController }
    public var guideManager: GuideManager { guideController }
    public var envelopeViewManager: EnvelopeViewManager { envelopeViewController }
    
    public init(changer: SharedStateMonitor.StateChanger) {

        let sharedStateMonitor = SharedStateMonitor(changer: changer)
        self.sharedStateMonitor = sharedStateMonitor
        self.askForReview = AskForReview(isMain: sharedStateMonitor.isMain)
        self.soundFonts = SoundFontsManager(sharedStateMonitor: sharedStateMonitor)
        self.favorites = FavoritesManager(sharedStateMonitor: sharedStateMonitor)
        self.sampler = Sampler(mode: sharedStateMonitor.isMain ? .standalone : .audiounit)

        self.activePatchManager = ActivePatchManager(soundFonts: soundFonts)
        self.selectedSoundFontManager = SelectedSoundFontManager(activePatchManager: activePatchManager)

        sharedStateMonitor.block = { stateChange in
            switch stateChange {
            case .favorites:
                self.favorites.reload()
                self.favoritesController.reload()
            case .soundFonts:
                self.soundFonts.reload()
                self.soundFontsController.reload()
            }
        }
    }

    public func setMainViewController(_ mvc: T) {
        mainViewController = mvc
        for obj in mvc.children {
            switch obj {
            case let vc as SoundFontsControlsController:
                soundFontsControlsController = vc
                for inner in vc.children {
                    switch inner {
                    case let vc as GuideViewController: guideController = vc
                    case let vc as SoundFontsViewController: soundFontsController = vc
                    case let vc as FavoritesViewController: favoritesController = vc
                    case let vc as InfoBarController: infoBarController = vc
                    case let vc as EnvelopeViewController: envelopeViewController = vc
                    default: assertionFailure("unknown child UIViewController")
                    }
                }
            case let vc as KeyboardController: keyboardController = vc
            default: assertionFailure("unknown child UIViewController")
            }
        }

        validate()
        establishConnections()
    }

    /**
     Invoke `establishConnections` on each tracked view controller.
     */
    public func establishConnections() {
        soundFontsController.establishConnections(self)
        favoritesController.establishConnections(self)
        infoBarController.establishConnections(self)
        keyboardController?.establishConnections(self)
        guideController.establishConnections(self)
        soundFontsControlsController.establishConnections(self)
        mainViewController.establishConnections(self)
    }
}

extension Components {

    private func validate() {
        precondition(mainViewController != nil, "nil MainViewController")
        precondition(soundFontsControlsController != nil, "nil SoundFontsControlsController")
        precondition(guideController != nil, "nil GuidesController")
        precondition(soundFontsController != nil, "nil SoundFontsViewController")
        precondition(favoritesController != nil, "nil FavoritesViewController")
        precondition(infoBarController != nil, "nil InfoBarController")
        precondition(envelopeViewController != nil, "nil envelopeViewController")
    }

    private func oneTimeSet<T>(_ oldValue: T?) {
        if oldValue != nil {
            preconditionFailure("expected nil value")
        }
    }
}

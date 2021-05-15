// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Collection of UIViewControllers and protocol facades which helps establish inter-controller relationships during the
 application launch. Each view controller is responsible for establishing the connections in their
 `establishConnections` method. The goal should be to have relations between a controller and protocols / facades, and
 not between controllers themselves. This is enforced here through access restrictions to known controllers.
 */
public final class Components<T: UIViewController>: SubscriptionManager<ComponentContainerEvent>,
                                                    ComponentContainer where T: ControllerConfiguration {
    public let consolidatedConfigFile: ConsolidatedConfigFile
    public let askForReview: AskForReview
    public let soundFonts: SoundFonts
    public let favorites: Favorites
    public let tags: Tags
    public let activePatchManager: ActivePatchManager
    public let selectedSoundFontManager: SelectedSoundFontManager
    public let inApp: Bool

    public private(set) var mainViewController: T! { didSet { oneTimeSet(oldValue) } }
    private var soundFontsControlsController: SoundFontsControlsController! { didSet { oneTimeSet(oldValue) } }
    private var infoBarController: InfoBarController! { didSet { oneTimeSet(oldValue) } }
    private var keyboardController: KeyboardController? { didSet { oneTimeSet(oldValue) } }
    private var soundFontsController: SoundFontsViewController! { didSet { oneTimeSet(oldValue) } }
    private var favoritesController: FavoritesViewController! { didSet { oneTimeSet(oldValue) } }
    private var favoriteEditor: FavoriteEditor! { didSet { oneTimeSet(oldValue) } }
    private var guideController: GuideViewController! { didSet { oneTimeSet(oldValue) } }
    private var effectsController: EffectsController? { didSet { oneTimeSet(oldValue) } }
    private var tagsController: TagsTableViewController! { didSet { oneTimeSet(oldValue) } }

    public var infoBar: InfoBar { infoBarController }
    public var keyboard: Keyboard? { keyboardController }
    public var patchesViewManager: PatchesViewManager { soundFontsController }
    public var favoritesViewManager: FavoritesViewManager { favoritesController }
    public var fontEditorActionGenerator: FontEditorActionGenerator { soundFontsController }
    public var alertManager: AlertManager { _alertManager! }

    public var sampler: Sampler { _sampler! }
    public var delayEffect: DelayEffect? {
        precondition(self.inApp == false || _delayEffect != nil)
        return _delayEffect
    }

    public var reverbEffect: ReverbEffect? {
        precondition(self.inApp == false || _reverbEffect != nil)
        return _reverbEffect
    }

    private var _alertManager: AlertManager?

    private var _sampler: Sampler? {
        didSet {
            if let sampler = _sampler { DispatchQueue.main.async { self.notify(.samplerAvailable(sampler)) } }
        }
    }
    private var _reverbEffect: ReverbEffect? {
        didSet {
            if let effect = _reverbEffect { DispatchQueue.main.async { self.notify(.reverbAvailable(effect)) } }
        }
    }
    private var _delayEffect: DelayEffect? {
        didSet {
            if let effect = _delayEffect { DispatchQueue.main.async { self.notify(.delayAvailable(effect)) } }
        }
    }

    public init(inApp: Bool) {
        self.inApp = inApp
        self.consolidatedConfigFile = ConsolidatedConfigFile()

        self.askForReview = AskForReview(isMain: inApp)

        let soundFontsManager = LegacySoundFontsManager(consolidatedConfigFile)
        self.soundFonts = soundFontsManager

        let favoritesManager = LegacyFavoritesManager(consolidatedConfigFile)
        self.favorites = favoritesManager

        self.tags = LegacyTagsManager(consolidatedConfigFile)

        self.selectedSoundFontManager = SelectedSoundFontManager()
        self.activePatchManager = ActivePatchManager(soundFonts: soundFonts,
                                                     selectedSoundFontManager: selectedSoundFontManager)
        super.init()

        if inApp {

            // Create audio components in background to free up main thread in application
            DispatchQueue.global(qos: .userInitiated).async {
                let reverb = inApp ? ReverbEffect() : nil
                self._reverbEffect = reverb
                let delay = inApp ? DelayEffect() : nil
                self._delayEffect = delay
                self._sampler = Sampler(mode: inApp ? .standalone : .audioUnit,
                                        activePatchManager: self.activePatchManager,
                                        reverb: reverb, delay: delay)
            }
        }
        else {

            // Do not create Sampler asynchronously when supporting AUv3 component.
            self._sampler = Sampler(mode: inApp ? .standalone : .audioUnit, activePatchManager: self.activePatchManager,
                                    reverb: nil, delay: nil)
        }
    }

    public func setMainViewController(_ mvc: T) {
        mainViewController = mvc
        _alertManager = AlertManager(presenter: mvc)
        for obj in mvc.children {
            processChildController(obj)
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
        effectsController?.establishConnections(self)
        mainViewController.establishConnections(self)
    }
}

extension Components {

    private func processChildController(_ obj: UIViewController) {
        switch obj {
        case let vc as SoundFontsControlsController:
            soundFontsControlsController = vc
            for inner in vc.children {
                processGrandchildController(inner)
            }
        case let vc as KeyboardController: keyboardController = vc
        default: assertionFailure("unknown child UIViewController")
        }
    }

    private func processGrandchildController(_ obj: UIViewController) {
        switch obj {
        case let vc as GuideViewController: guideController = vc
        case let vc as SoundFontsViewController: soundFontsController = vc
        case let vc as FavoritesViewController: favoritesController = vc
        case let vc as InfoBarController: infoBarController = vc
        case let vc as EffectsController: effectsController = vc
        default: assertionFailure("unknown child UIViewController")
        }
    }

    private func validate() {
        precondition(mainViewController != nil, "nil MainViewController")
        precondition(soundFontsControlsController != nil, "nil SoundFontsControlsController")
        precondition(guideController != nil, "nil GuidesController")
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

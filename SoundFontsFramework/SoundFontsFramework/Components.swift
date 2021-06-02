// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/// Collection of UIViewControllers and protocol facades which helps establish inter-controller relationships during the
/// application launch. Each view controller is responsible for establishing the connections in their
/// `establishConnections` method. The goal should be to have relations between a controller and protocols / facades, and
/// not between controllers themselves. This is enforced here through access restrictions to known controllers.
public final class Components<T: UIViewController>: SubscriptionManager<ComponentContainerEvent>,
  ComponentContainer
where T: ControllerConfiguration {
  /// The configuration file that defines what fonts are installed and customizations
  public let consolidatedConfigFile: ConsolidatedConfigFile
  /// Manager that controls when to ask for a review from the customer
  public let askForReview: AskForReview
  /// The manager for the collection of sound fonts
  public let soundFonts: SoundFonts
  /// The manager for the collection of favorites
  public let favorites: Favorites
  /// The manager for the collection of sound font tags
  public let tags: Tags
  /// The manager of the active preset
  public let activePatchManager: ActivePatchManager
  /// The manager of the selected sound font
  public let selectedSoundFontManager: SelectedSoundFontManager
  /// True if running in the app; false when running in the AUv3 app extension
  public let inApp: Bool
  /// The main view controller of the app
  public private(set) var mainViewController: T! { didSet { oneTimeSet(oldValue) } }

  private var soundFontsControlsController: SoundFontsControlsController! {
    didSet { oneTimeSet(oldValue) }
  }
  private var infoBarController: InfoBarController! { didSet { oneTimeSet(oldValue) } }
  private var keyboardController: KeyboardController? { didSet { oneTimeSet(oldValue) } }
  private var soundFontsController: SoundFontsViewController! { didSet { oneTimeSet(oldValue) } }
  private var favoritesController: FavoritesViewController! { didSet { oneTimeSet(oldValue) } }
  private var favoriteEditor: FavoriteEditor! { didSet { oneTimeSet(oldValue) } }
  private var guideController: GuideViewController! { didSet { oneTimeSet(oldValue) } }
  private var effectsController: EffectsController? { didSet { oneTimeSet(oldValue) } }
  private var tagsController: TagsTableViewController! { didSet { oneTimeSet(oldValue) } }

  /// The controller for the info bar
  public var infoBar: InfoBar { infoBarController }
  /// The controller for the keyboard (nil when running in the AUv3 app extension)
  public var keyboard: Keyboard? { keyboardController }
  /// The manager of the fonts/presets view
  public var fontsViewManager: FontsViewManager { soundFontsController }
  /// The manager of the favorites view
  public var favoritesViewManager: FavoritesViewManager { favoritesController }
  /// Swipe actions generator for sound font rows
  public var fontEditorActionGenerator: FontEditorActionGenerator { soundFontsController }
  /// The manager for posting alerts
  public var alertManager: AlertManager { _alertManager! }
  /// The sampler engine that generates audio from sound font files
  public var sampler: Sampler { _sampler! }
  /// The delay effect available for audio processing (app only)
  public var delayEffect: DelayEffect? {
    precondition(self.inApp == false || _delayEffect != nil)
    return _delayEffect
  }
  /// The reverb effect available for audio processing (app only)
  public var reverbEffect: ReverbEffect? {
    precondition(self.inApp == false || _reverbEffect != nil)
    return _reverbEffect
  }

  private var _alertManager: AlertManager?

  private var _sampler: Sampler? {
    didSet {
      if let sampler = _sampler {
        DispatchQueue.main.async { self.notify(.samplerAvailable(sampler)) }
      }
    }
  }

  private var _reverbEffect: ReverbEffect? {
    didSet {
      if let effect = _reverbEffect {
        DispatchQueue.main.async { self.notify(.reverbAvailable(effect)) }
      }
    }
  }

  private var _delayEffect: DelayEffect? {
    didSet {
      if let effect = _delayEffect {
        DispatchQueue.main.async { self.notify(.delayAvailable(effect)) }
      }
    }
  }

  /**
     Create a new instance

     - parameter inApp: true if running in the app
     */
  public init(inApp: Bool) {
    self.inApp = inApp
    self.consolidatedConfigFile = ConsolidatedConfigFile()

    self.askForReview = AskForReview(isMain: inApp)

    let soundFontsManager = SoundFontsManager(consolidatedConfigFile)
    self.soundFonts = soundFontsManager

    let favoritesManager = FavoritesManager(consolidatedConfigFile)
    self.favorites = favoritesManager

    self.tags = TagsManager(consolidatedConfigFile)

    self.selectedSoundFontManager = SelectedSoundFontManager()
    self.activePatchManager = ActivePatchManager(
      soundFonts: soundFonts,
      selectedSoundFontManager: selectedSoundFontManager)
    super.init()

    if inApp {

      // Create audio components in background to free up main thread in application
      DispatchQueue.global(qos: .userInitiated).async {
        let reverb = inApp ? ReverbEffect() : nil
        self._reverbEffect = reverb
        let delay = inApp ? DelayEffect() : nil
        self._delayEffect = delay
        self._sampler = Sampler(
          mode: inApp ? .standalone : .audioUnit,
          activePatchManager: self.activePatchManager,
          reverb: reverb, delay: delay)
      }
    } else {

      // Do not create Sampler asynchronously when supporting AUv3 component.
      self._sampler = Sampler(
        mode: inApp ? .standalone : .audioUnit, activePatchManager: self.activePatchManager,
        reverb: nil, delay: nil)
    }
  }

  /**
     Install the main view controller

     - parameter mvc: the main view controller to use
     */
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

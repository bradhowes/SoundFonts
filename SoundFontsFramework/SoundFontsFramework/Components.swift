// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import MorkAndMIDI
import os.log

/// Collection of UIViewControllers and protocol facades which helps establish inter-controller relationships during the
/// application launch. Each view controller is responsible for establishing the connections in their
/// `establishConnections` method. The goal should be to have relations between a controller and protocols / facades, and
/// not between controllers themselves. This is enforced here through access restrictions to known controllers.
public final class Components<T: UIViewController>: SubscriptionManager<ComponentContainerEvent>, ComponentContainer
where T: ControllerConfiguration {
  private let log: Logger
  private let accessQueue = DispatchQueue(label: "ComponentsQueue", qos: .background, attributes: [],
                                          autoreleaseFrequency: .inherit, target: .global(qos: .background))
  public static var configurationFileURL: URL { FileManager.default.sharedPath(for: "Consolidated.plist") }
  public let settings: Settings
  /// The configuration file that defines what fonts are installed and customizations
  public let consolidatedConfigProvider: ConsolidatedConfigProvider
  /// The unique identity associated with this instance (app or AUv3)
  public var identity: String { consolidatedConfigProvider.identity }
  /// Manager that controls when to ask for a review from the customer
  public let askForReview: AskForReview?
  /// The manager of the active preset
  public let activePresetManager: ActivePresetManager
  /// The manager for the collection of sound fonts
  public let soundFonts: SoundFontsProvider
  /// The manager for the collection of favorites
  public let favorites: FavoritesProvider
  /// The manager for the collection of sound font tags
  public let tags: TagsProvider
  /// The manager of the selected sound font
  public let selectedSoundFontManager: SelectedSoundFontManager
  /// The manager of the active tag for font filtering
  public let activeTagManager: ActiveTagManager

  /// True if running in the app; false when running in the AUv3 app extension
  public let inApp: Bool
  /// The main view controller of the app
  public private(set) weak var mainViewController: T! { didSet { oneTimeSet(oldValue) } }

  private weak var soundFontsControlsController: SoundFontsControlsController! {
    didSet {
      oneTimeSet(oldValue)
      processChildren(soundFontsControlsController)
    }
  }

  private weak var soundFontsViewController: SoundFontsViewController! {
    didSet {
      oneTimeSet(oldValue)
      processChildren(soundFontsViewController)
    }
  }

  private weak var infoBarController: InfoBarController! { didSet { oneTimeSet(oldValue) } }
  private weak var keyboardController: KeyboardController? { didSet { oneTimeSet(oldValue) } }
  private weak var favoritesController: FavoritesViewController! { didSet { oneTimeSet(oldValue) } }
  private weak var guideController: GuideViewController! { didSet { oneTimeSet(oldValue) } }
  private weak var effectsController: EffectsController? { didSet { oneTimeSet(oldValue) } }
  private weak var fontsTableViewController: FontsTableViewController! { didSet { oneTimeSet(oldValue) } }
  private weak var presetsTableViewController: PresetsTableViewController! { didSet { oneTimeSet(oldValue) } }
  private weak var tagsTableViewController: TagsTableViewController! { didSet { oneTimeSet(oldValue) } }

  /// The controller for the info bar
  public var infoBar: AnyInfoBar { infoBarController }

  /// The controller for the keyboard (nil when running in the AUv3 app extension)
  public var keyboard: AnyKeyboard? { keyboardController }

  /// The manager of the fonts/presets view
  public var fontsViewManager: FontsViewManager { soundFontsViewController }

  /// The manager of the favorites view
  public var favoritesViewManager: FavoritesViewManager { favoritesController }

  /// Swipe actions generator for sound font rows
  public var fontSwipeActionGenerator: FontActionManager { soundFontsViewController }

  /// The manager for posting alerts
  public var alertManager: AlertManager { _alertManager }
  private var _alertManager: AlertManager!

  /// The synth engine that generates audio from sound font files.
  public var audioEngine: AudioEngine? { accessQueue.sync { _audioEngine } }

  private var _audioEngine: AudioEngine? {
    didSet {
      if let audioEngine = _audioEngine {
        notify(.audioEngineAvailable(audioEngine))
      }
    }
  }

  /**
   Factory function to create a new instance.

   - parameter inApp: true if running in the app, false if running as audio unit
   - parameter identity: unique-ish identifier for this instance. Only used for logging purposes to distinguish between
   multiple AUv3 instances.
   */
  public static func make(inApp: Bool, identity: String) -> Components<T> {
    let log: Logger = Logging.logger("Components[\(identity)]")
    return log.measure("init") {
      Components(log: log, inApp: inApp, identity: identity)
    }
  }

  /**
   Create a new instance

   - parameter inApp: true if running in the app, false if running as audio unit
   */
  private init(log: Logger, inApp: Bool, identity: String) {
    self.log = log

    let consolidatedConfigProvider = ConsolidatedConfigProvider(
      inApp: inApp,
      fileURL: Self.configurationFileURL,
      identity: identity
    )

    self.inApp = inApp
    self.settings = Settings()
    self.consolidatedConfigProvider = consolidatedConfigProvider

    if inApp {
      self.askForReview = .init(settings: settings)
    } else {
      self.askForReview = nil
    }

    self.soundFonts = SoundFontsManager(consolidatedConfigProvider, settings: settings)
    self.favorites = FavoritesManager(consolidatedConfigProvider)
    self.tags = TagsManager(consolidatedConfigProvider)

    self.selectedSoundFontManager = .init()
    self.activePresetManager = .init(soundFonts: soundFonts, favorites: favorites,
                                     selectedSoundFontManager: selectedSoundFontManager,
                                     settings: settings)
    self.activeTagManager = .init(tags: tags, settings: settings)

    super.init()

    createAudioComponents(activePresetManager: activePresetManager, settings: settings)
  }

  public func createAudioComponents(activePresetManager: ActivePresetManager, settings: Settings) {
    if self.inApp {
      DispatchQueue.global(qos: .userInitiated).async {
        let midiInputPortUniqueId = Int32(settings[.midiInputPortUniqueId])
        let midi: MIDI = .init(clientName: "SoundFonts", uniqueId: midiInputPortUniqueId, midiProto: .legacy)
        let midiControllerActionStateManager: MIDIControllerActionStateManager = .init(settings: settings)
        let audioEngine: AudioEngine = .init(mode: .standalone,
                                             activePresetManager: activePresetManager,
                                             settings: settings,
                                             midi: midi,
                                             midiControllerActionStateManager: midiControllerActionStateManager)
        self.accessQueue.sync {
          self._audioEngine = audioEngine
        }
      }
    } else {
      self.log.measure("create AudioEngine") {
        self._audioEngine = AudioEngine(mode: .audioUnit,
                                        activePresetManager: activePresetManager,
                                        settings: settings,
                                        midi: nil,
                                        midiControllerActionStateManager: nil)
      }
    }
  }

  /**
   Install the main view controller

   - parameter mvc: the main view controller to use
   */
  public func setMainViewController(_ mvc: T) {
    mainViewController = mvc
    _alertManager = AlertManager(presenter: mvc)
    mvc.children.forEach { processChildController($0) }
    validate()
    establishConnections()
    self.consolidatedConfigProvider.load()
  }

  /**
   Invoke `establishConnections` on each tracked view controller.
   */
  public func establishConnections() {
    fontsTableViewController.establishConnections(self)
    presetsTableViewController.establishConnections(self)
    tagsTableViewController.establishConnections(self)
    soundFontsViewController.establishConnections(self)
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

  private func processChildren(_ vc: UIViewController) { vc.children.forEach { processChildController($0) } }

  private func processChildController(_ obj: UIViewController) {
    if let vc = obj as? SoundFontsControlsController {
      soundFontsControlsController = vc
    } else if let vc = obj as? SoundFontsViewController {
      soundFontsViewController = vc
    } else if let vc = obj as? KeyboardController {
      keyboardController = vc
    } else if let vc = obj as? GuideViewController {
      guideController = vc
    } else if let vc = obj as? FavoritesViewController {
      favoritesController = vc
    } else if let vc = obj as? InfoBarController {
      infoBarController = vc
    } else if let vc = obj as? FontsTableViewController {
      fontsTableViewController = vc
    } else if let vc = obj as? PresetsTableViewController {
      presetsTableViewController = vc
    } else if let vc = obj as? TagsTableViewController {
      tagsTableViewController = vc
    } else if let vc = obj as? EffectsController {
      effectsController = vc
    } else {
      assertionFailure("unknown child UIViewController")
    }
  }

  private func validate() {
    precondition(mainViewController != nil, "nil MainViewController")
    precondition(soundFontsControlsController != nil, "nil SoundFontsControlsController")
    precondition(soundFontsViewController != nil, "nil SoundFontsViewController")
    precondition(guideController != nil, "nil GuidesController")
    precondition(favoritesController != nil, "nil FavoritesViewController")
    precondition(infoBarController != nil, "nil InfoBarController")
    precondition(fontsTableViewController != nil, "nil FontsTableViewController")
    precondition(presetsTableViewController != nil, "nil PresetsTableViewController")
    precondition(tagsTableViewController != nil, "nil TagsTableViewController")
    precondition(effectsController != nil, "nil EffectsController")
  }

  private func oneTimeSet<Z>(_ oldValue: Z?) {
    if oldValue != nil {
      preconditionFailure("expected nil value")
    }
  }
}

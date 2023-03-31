// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import MorkAndMIDI

/// State change events that can happen with a ComponentContainer.
public enum ComponentContainerEvent: CustomStringConvertible {
  /// The sampler is ready for use.
  case synthManagerAvailable(SynthManager)

  public var description: String {
    switch self {
    case .synthManagerAvailable: return "<ComponentContainerEvent: synthAvailable>"
    }
  }
}

/// Collection of UIViewControllers and protocol facades which helps establish inter-controller relationships during the
/// application launch. Each view controller is responsible for establishing the connections in their
/// `establishConnections` method. The goal should be to have relations between a controller and protocols / facades, and
/// not between controllers themselves. This is enforced here through access restrictions to known controllers.
public protocol ComponentContainer: AnyObject {
  /// User settings for the app
  var settings: Settings { get }
  /// The Sampler that is used to generate sounds
  var synth: SynthManager? { get }
  /// The collection of installed sound font files
  var soundFonts: SoundFontsProvider { get }
  /// The collection of favorite presets
  var favorites: FavoritesProvider { get }
  /// The collection of user-defined tags for sound fonts
  var tags: TagsProvider { get }
  /// The manager that tracks and holds the active preset that is in use in the samplers
  var activePresetManager: ActivePresetManager { get }
  /// The manager that tracks and holds the selected sound font. It is not necessarily the sound font that has the
  /// active preset.s
  var selectedSoundFontManager: SelectedSoundFontManager { get }
  var activeTagManager: ActiveTagManager { get }
  /// The manager for the info bar that sits below the sound font and preset table views and above the keyboard.
  var infoBar: AnyInfoBar { get }
  /// The keyboard manager if inside the application; the AUv3 component has no keyboard and so this will be nil.
  var keyboard: AnyKeyboard? { get }
  /// The manager of the preset table view
  var fontsViewManager: FontsViewManager { get }
  /// The manager of the favorites collection view
  var favoritesViewManager: FavoritesViewManager { get }
  /// The provider of swipe actions for the sound fonts view
  var fontSwipeActionGenerator: FontActionManager { get }
  /// The entity for posting alerts to the user
  var alertManager: AlertManager { get }

  var midi: MIDI? { get }

  var askForReview: AskForReview? { get }

  var midiMonitor: MIDIMonitor? { get }

  func createAudioComponents()

  /**
   Subscribe to notifications when the collection changes. The types of changes are defined in FavoritesEvent enum.

   - parameter subscriber: the object doing the monitoring
   - parameter notifier: the closure to invoke when a change takes place
   - returns: token that can be used to unsubscribe
   */
  @discardableResult
  func subscribe<O: AnyObject>(_ subscriber: O,
                               notifier: @escaping (ComponentContainerEvent) -> Void) -> SubscriberToken
}

extension ComponentContainer {

  /// Returns true if running in the app, false when running in the AUv3 extension.
  public var isMainApp: Bool { return keyboard != nil }
}

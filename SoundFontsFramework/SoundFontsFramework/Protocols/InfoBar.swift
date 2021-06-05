// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import UIKit

/// The collection of event types that can be targeted in the `InfoBarManager.addTarget` method
public enum InfoBarEvent {
  /// Move the keyboard up in scale so that the new first key value is the key after the current highest key
  case shiftKeyboardUp
  /// Move the keyboard down in scale so that the new last key value is the key before the current lowest key
  case shiftKeyboardDown
  /// Add a new sound font file to the collection of known files
  case addSoundFont
  /// User performed a double-tap action on the info bar. Switch between favorites view and file/preset view
  case doubleTap
  /// Show the guide overlay
  case showGuide
  /// Show/hide the settings panel
  case showSettings
  /// Enter edit mode to change individual preset visibility settings
  case editVisibility
  /// Show/hide the effects panel
  case showEffects
  /// Show/hide the tags list
  case showTags

  case showMoreButtons

  case hideMoreButtons
}

/// Handles the actions and display of items in a hypothetical info bar above the keyboard
public protocol InfoBar: AnyObject {

  /**
     Link a button / gesture event to a target/selector combination

     - parameter event: the event to link to
     - parameter closure: the closure to invoke when the event appears
     */
  func addEventClosure(_ event: InfoBarEvent, _ closure: @escaping UIControl.Closure)

  /**
     Show status information on the bar. This will appear temporarily and then fade back to the patch name.

     - parameter value: the value to show
     */
  func setStatusText(_ value: String)

  /**
     Set the lowest and highest note labels of the keyboard

     - parameter from: the lowest note
     - parameter to: the highest note
     */
  func setVisibleKeyLabels(from: String, to: String)

  /// True if there are more buttons to be seen
  var moreButtonsVisible: Bool { get }

  /// Show the remaining buttons
  func showMoreButtons()

  /// Hide the remaining buttons
  func hideMoreButtons()

  /**
     Reset a button state for a given event. Some buttons show an 'active' state while another piece of UI is visible.
     This provides a programatic way to reset the button to the 'inactive' state.

     - parameter event: the event associated with the button to reset
     */
  func resetButtonState(_ event: InfoBarEvent)

  /**
     Update the enabled state of info buttons depending on appearance of presets view.

     - parameter visible: true if presets view is showin
     */
  func updateButtonsForPresetsViewState(visible: Bool)
}

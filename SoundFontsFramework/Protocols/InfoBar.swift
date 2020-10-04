// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import UIKit

/**
 The collection of event types that can be targeted in the `InfoBarManager.addTarget` method
 */
public enum InfoBarEvent {
    case shiftKeyboardUp
    case shiftKeyboardDown
    case addSoundFont
    case doubleTap
    case showGuide
    case showSettings
    case editVisibility
}

/**
 Handles the actions and display of items in a hypothetical info bar above the keyboard
 */
public protocol InfoBar: class {

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
    func setStatus(_ value: String)

    /**
     Show the patch name on the bar.
    
     - parameter value: the name to display
     - parameter isFavored: true if this is a Favorite item
     */
    func setPatchInfo(name: String, isFavored: Bool)

    /**
     Set the lowest and highest note labels of the keyboard
    
     - parameter from: the lowest note
     - parameter to: the highest note
     */
    func setVisibleKeyLabels(from: String, to: String)

    func hideButtons()
}

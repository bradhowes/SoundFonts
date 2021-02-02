// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public enum ComponentContainerEvent {
    case samplerAvailable(Sampler)
    case reverbAvailable(Reverb)
    case delayAvailable(Delay)
}

/**
 Collection of UIViewControllers and protocol facades which helps establish inter-controller relationships during the
 application launch. Each view controller is responsible for establishing the connections in their
 `establishConnections` method. The goal should be to have relations between a controller and protocols / facades, and
 not between controllers themselves. This is enforced here through access restrictions to known controllers.
 */
public protocol ComponentContainer {
    var sampler: Sampler { get }
    var soundFonts: SoundFonts { get }
    var favorites: Favorites { get }
    var tags: Tags { get }
    var activePatchManager: ActivePatchManager { get }
    var selectedSoundFontManager: SelectedSoundFontManager { get }
    var infoBar: InfoBar { get }
    var keyboard: Keyboard? { get }
    var patchesViewManager: PatchesViewManager { get }
    var favoritesViewManager: FavoritesViewManager { get }
    var fontEditorActionGenerator: FontEditorActionGenerator { get }
    var reverbEffect: Reverb? { get }
    var delayEffect: Delay? { get }

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

public extension ComponentContainer {
    var isMainApp: Bool { return keyboard != nil }
}

// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

enum PatchKind: CustomStringConvertible {
    case normal(patch: Patch)
    case favorite(favorite: Favorite)

    var description: String {
        switch self {
        case let .normal(patch: patch): return ".normal(\(patch)"
        case let .favorite(favorite: favorite): return ".favorite(\(favorite.patch))"
        }
    }
}

/**
 Maintains the active SoundFont patch being used for sound generation.
 */
protocol ActivePatchManager: class {

    /// Prototype for the notifying function
    typealias Notifier<O: AnyObject> = (_ old: Patch, _ new: Patch) -> Void

    /// The currently active patch
    var activePatch: Patch { get }

    func changePatch(kind: PatchKind)

    /**
     Install a closure to be called when a Patch change happens. The closure takes one argument, the Patch instance
     that is now active.
     
     - parameter closure: the closure to install
     - returns: unique identifier that can be used to remove the notifier via `removeNotifier`
     */
    @discardableResult
    func addPatchChangeNotifier<O: AnyObject>(_ observer: O, closure: @escaping Notifier<O>) -> NotifierToken
    
    /**
     Remove an existing notifier.
     
     - parameter key: the key associated with the notifier and returned by `addPatchChangeNotifier`
     */
    func removeNotifier(forKey key: UUID)
}

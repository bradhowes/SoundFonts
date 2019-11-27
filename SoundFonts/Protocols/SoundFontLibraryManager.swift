// SoundFontLibraryManager.swift
// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

enum SoundFontLibraryChangeKind {
    case added(soundFont: SoundFont)
    case changed(soundFont: SoundFont)
    case removed(soundFont: SoundFont)
    case restored
}

protocol SoundFontLibraryManager {

    /// Prototype for the notifying function
    typealias Notifier<O: AnyObject> = (_ kind: SoundFontLibraryChangeKind) -> Void

    /**
     Install a closure to be called when a SoundFont change happens. The closure takes two arguments: an enum
     indicating the kind of change that took place, and the SoundFont instance the change affected.

     - parameter closure: the closure to install
     - returns: unique identifier that can be used to remove the notifier via `removeNotifier`
     */
    @discardableResult
    func addSoundFontLibraryChangeNotifier<O: AnyObject>(_ observer: O, closure: @escaping Notifier<O>) -> NotifierToken

    /**
     Remove an existing notifier.

     - parameter key: the key associated with the notifier and returned by `addSoundFontLibraryChangeNotifier`
     */
    func removeNotifier(forKey key: UUID)

    /**
     Obtain a SoundFont using an index into the `keys` name array. If the index is out-of-bounds this will return the
     first sound font in alphabetical order.
     - parameter index: the key to use
     - returns: found SoundFont object
     */
    func getByIndex(_ index: Int) -> SoundFont

    /**
     Obtain a SoundFont by name. If not found, then return the very first one (alphabetically)
     - parameter key: the key to use
     - returns: found SoundFont object
     */
    func getByName(_ name: String) -> SoundFont

    /**
     Obtain the index in `keys` for the given sound font name. If not found, return 0
     - parameter name: the name to look for
     - returns: found index or zero
     */
    func indexForName(_ name: String) -> Int

    func add(soundFont: URL, completionHandler: ((Bool) -> Void)?)

    func remove(soundFont: SoundFont)

    func edit(soundFont: SoundFont)
}

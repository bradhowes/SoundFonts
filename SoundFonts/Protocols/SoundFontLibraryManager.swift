// SoundFontLibraryManager.swift
// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

enum SoundFontLibraryChangeKind {
    case added(SoundFont)
    case changed(SoundFont)
    case removed(SoundFont)
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

    var orderedSoundFonts: [SoundFont] { get }
    var isRestored: Bool { get }

    /**
     Obtain a SoundFont using an index into the `keys` name array. If the index is out-of-bounds this will return the
     first sound font in alphabetical order.
     - parameter index: the key to use
     - returns: found SoundFont object
     */
    func getBy(uuid: UUID) -> SoundFont?

    func add(url: URL) -> SoundFont?

    func remove(soundFont: SoundFont)

    func renamed(soundFont: SoundFont)

}

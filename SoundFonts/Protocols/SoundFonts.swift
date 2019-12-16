// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/**
 The different events which are emitted by a SoundFonts collection when the collection changes.
 */
enum SoundFontsEvent {

    /// New SoundFont added to the collection
    case added(new: Int, font: SoundFont)

    /// Existing SoundFont moved from one position in the collection to another due to name change
    case moved(old: Int, new: Int, font: SoundFont)

    /// Existing SoundFont instance removed from the collection
    case removed(old: Int, font: SoundFont)
}

/**
 Actions available on a collection of SoundFont instances. Supports subscribing to changes.
 */
protocol SoundFonts {

    /// Number of SoundFont instances in the collection
    var count: Int { get }

    /**
     Obtain the index in the collection of a SoundFont with the given Key.

     - parameter of: the key to look for
     - returns the index of the matching entry or nil if not found
     */
    func index(of: SoundFont.Key) -> Int?

    /**
     Obtain the SoundFont in the collection by its unique key

     - parameter key: the key to look for
     - returns the index of the matching entry or nil if not found
     */
    func getBy(key: SoundFont.Key) -> SoundFont?
    
    func getBy(index: Int) -> SoundFont

    func add(url: URL) -> (Int, SoundFont)?

    func remove(index: Int)

    func rename(index: Int, name: String)

    @discardableResult
    func subscribe<O:AnyObject>(_ subscriber: O, closure: @escaping (SoundFontsEvent)->Void) -> SubscriberToken
}

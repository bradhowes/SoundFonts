// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/**
 The different events which are emitted by a SoundFonts collection when the collection changes.
 */
public enum SoundFontsEvent {

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
public protocol SoundFonts {

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

    /**
     Obtain the SoundFont in the collection by its orderering index.

     - parameter index: the index to fetch
     - returns the SoundFont found at the index
     */
    func getBy(index: Int) -> SoundFont

    /**
     Add a new SoundFont.

     - parameter url: the URL of the file containing SoundFont (SF2) data

     - returns 2-tuple containing the index in the collection where the new SoundFont was inserted, and the SoundFont
     instance created from the raw data
     */
    func add(url: URL) -> (Int, SoundFont)?

    /**
     Remove the SoundFont at the given index

     - parameter index: the location to remove
     */
    func remove(index: Int)

    /**
     Change the name of a SoundFont

     - parameter index: location of the SoundFont to edit
     - parameter name: new name to use
     */
    func rename(index: Int, name: String)

    /**
     Force a reload of the SoundFont collection.
     */
    func reload()

    /**
     Subscribe to notifications when the collection changes. The types of changes are defined in SoundFontsEvent enum.

     - parameter subscriber: the object doing the monitoring
     - parameter notifier: the closure to invoke when a change takes place
     - returns: token that can be used to unsubscribe
     */
    @discardableResult
    func subscribe<O: AnyObject>(_ subscriber: O, notifier: @escaping (SoundFontsEvent) -> Void) -> SubscriberToken
}

// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

public enum TagsEvent {

    case added(new: Int, tag: LegacyTag)
    case moved(old: Int, new: Int, font: LegacyTag)
    case removed(old: Int, font: LegacyTag)
    case restored
}

public protocol Tags: class {

    var restored: Bool { get }
    var tagNames: [String] { get }

    func index(of: LegacyTag.Key) -> Int?
    func getBy(key: LegacyTag.Key) -> LegacyTag?
    func getBy(index: Int) -> LegacyTag

    func add(tag: Tag) -> Result<(Int, LegacySoundFont), SoundFontFileLoadFailure>

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
     Set the visibility of a preset.

     - parameter key: the unique key of the SoundFont to change
     - parameter index: the index of the preset in the SoundFont to change
     - parameter state: the new visibility state for the preset
     */
    func setVisibility(key: LegacySoundFont.Key, index: Int, state: Bool)

    /**
     Make all presets of a given SoundFont visible.

     - parameter key: the unique key of the SoundFont to change
     */
    func makeAllVisible(key: LegacySoundFont.Key)

    /**
     Attach effect configurations to a preset.

     - parameter key: the unique key of the SoundFont to change
     - parameter index: the index of the preset in the SoundFont to change
     - parameter delay: the configuration for the delay
     - parameter reverb: the configuration for the reverb
     */
    func setEffects(key: LegacySoundFont.Key, index: Int, delay: DelayConfig?, reverb: ReverbConfig?)

    /// Determine if there are any bundled fonts in the collection
    var hasAnyBundled: Bool { get }

    /// Determine if all bundled fonts are in the collection
    var hasAllBundled: Bool { get }

    /**
     Remove all built-in SoundFont entries.
     */
    func removeBundled()

    /**
     Restore built-in SoundFonts.
     */
    func restoreBundled()

    func exportToLocalDocumentsDirectory() -> (good: Int, total: Int)

    func importFromLocalDocumentsDirectory() -> (good: Int, total: Int)

    /**
     Subscribe to notifications when the collection changes. The types of changes are defined in SoundFontsEvent enum.

     - parameter subscriber: the object doing the monitoring
     - parameter notifier: the closure to invoke when a change takes place
     - returns: token that can be used to unsubscribe
     */
    @discardableResult
    func subscribe<O: AnyObject>(_ subscriber: O, notifier: @escaping (SoundFontsEvent) -> Void) -> SubscriberToken
}

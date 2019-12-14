// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

enum SoundFontsEvent {
    case added(new: Int, font: SoundFont)
    case moved(old: Int, new: Int, font: SoundFont)
    case removed(old: Int, font: SoundFont)
}

protocol SoundFonts {
    var count: Int { get }

    func index(of: UUID) -> Int?

    func getBy(uuid: UUID) -> SoundFont?
    func getBy(index: Int) -> SoundFont

    func add(url: URL) -> (Int, SoundFont)?
    func remove(index: Int) -> (Int, SoundFont)
    func rename(index: Int, name: String) -> (Int, Int, SoundFont)

    @discardableResult
    func subscribe<O:AnyObject>(_ subscriber: O, closure: @escaping (SoundFontsEvent)->Void) -> SubscriberToken
}

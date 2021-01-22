// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

/**
 A custom setting with a SoundFont patch and a keyboard configuration.
 */
public class LegacyFavorite: Codable {

    public typealias Key = UUID

    enum V1Keys: String, CodingKey {
        case key
        case soundFontAndPatch
        case name
        case keyboardLowestNote
        case gain
        case pan
    }

    enum V2Keys: String, CodingKey {
        case key
        case soundFontAndPatch
        case name
        case presetConfig
    }

    public let key: Key

    /// The patch to load
    public let soundFontAndPatch: SoundFontAndPatch

    /// The name of the favorite configuration
    public var name: String

    public var presetConfig: PresetConfig {
        didSet {
            PresetConfig.changedNotification.post(value: presetConfig)
        }
    }

    /**
     Create a new instance. The name of the favorite will start with the name of the patch.
    
     - parameter patch: the Patch to use
     - parameter keyboardLowestNote: the starting note of the keyboard
     */
    public init(name: String, soundFontAndPatch: SoundFontAndPatch, keyboardLowestNote: Note?) {
        self.key = Key()
        self.soundFontAndPatch = soundFontAndPatch
        self.name = name
        self.presetConfig = PresetConfig(keyboardLowestNote: keyboardLowestNote,
                                         keyboardLowestNoteEnabled: keyboardLowestNote != nil,
                                         gain: 0.0, pan: 0.0, presetTuning: 0.0, presetTuningEnabled: false)
    }

    public required init(from decoder: Decoder) throws {
        do {
            let values = try decoder.container(keyedBy: V1Keys.self)
            let key = try values.decode(Key.self, forKey: .key)
            let soundFontAndPatch = try values.decode(SoundFontAndPatch.self, forKey: .soundFontAndPatch)
            let name = try values.decode(String.self, forKey: .name)
            let lowestNote = try values.decodeIfPresent(Note.self, forKey: .keyboardLowestNote)
            let gain = try values.decode(Float.self, forKey: .gain)
            let pan = try values.decode(Float.self, forKey: .pan)
            self.key = key
            self.soundFontAndPatch = soundFontAndPatch
            self.name = name
            self.presetConfig = PresetConfig(keyboardLowestNote: lowestNote,
                                             keyboardLowestNoteEnabled: lowestNote != nil,
                                             gain: gain, pan: pan,
                                             presetTuning: 0.0, presetTuningEnabled: false)
        }
        catch {
            let err = error
            do {
                let values = try decoder.container(keyedBy: V2Keys.self)
                let key = try values.decode(Key.self, forKey: .key)
                let soundFontAndPatch = try values.decode(SoundFontAndPatch.self, forKey: .soundFontAndPatch)
                let name = try values.decode(String.self, forKey: .name)
                let presetConfig = try values.decode(PresetConfig.self, forKey: .presetConfig)
                self.key = key
                self.soundFontAndPatch = soundFontAndPatch
                self.name = name
                self.presetConfig = presetConfig
            } catch {
                throw err
            }
        }
    }
}

extension LegacyFavorite: Equatable {
    public static func == (lhs: LegacyFavorite, rhs: LegacyFavorite) -> Bool { lhs.key == rhs.key }
}

extension LegacyFavorite: CustomStringConvertible {
    public var description: String { "['\(name)' - \(soundFontAndPatch)]" }
}

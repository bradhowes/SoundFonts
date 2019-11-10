// SoundFonts.swift
// SynthInC
//
// Created by Brad Howes
// Copyright (c) 2016 Brad Howes. All rights reserved.

import UIKit
import GameKit

private let systemFontAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]
private extension String {
    var systemFontWidth: CGFloat { return (self as NSString).size(withAttributes: systemFontAttributes).width }
}

fileprivate extension String {
    static let soundFontName = "soundFontName"
    static let patchIndex = "patchIndex"
}

/**
 Representation of a sound font library. NOTE: all sound font files must have 'sf2' extension.
 */
public final class SoundFont: NSObject, NSCoding {

    /**
     Mapping of registered sound fonts. Add additional sound font entries here to make them available to the
     SoundFont code. NOTE: the value of this mapping is manipulated by the Python script `catalog.py` found in
     the `Extras` folder. In particular, it expects to find the -BEGIN- and -END- comments.
     */
    public static let library: [String:SoundFont] = [
// -BEGIN-
FreeFontGMVer32SoundFont.name: FreeFontGMVer32SoundFont,
GeneralUserGSMuseScoreversion1442SoundFont.name: GeneralUserGSMuseScoreversion1442SoundFont,
FluidR3GMSoundFont.name: FluidR3GMSoundFont,
UserBankSoundFont.name: UserBankSoundFont,
// -END-
    ]

    /**
     Array of registered sound font names sorted in alphabetical order. Generated from `library` entries.
     */
    public static let keys: [String] = library.keys.sorted()

    /**
     Maximium width of all library names.
     */
    public static let maxNameWidth: CGFloat = library.values.map { $0.nameWidth }.max() ?? 100.0
    public static let patchCount: Int = library.reduce(0) { $0 + $1.1.patches.count }

    /**
     Obtain a random patch from all registered sound fonts.
     - returns: radom Patch object
     */
    public static func randomPatch() -> Patch {
        let namePos = Int.random(in: 0..<keys.count)
        let soundFont = getByIndex(namePos)
        let patchPos = Int.random(in: 0..<soundFont.patches.count)
        return soundFont.patches[patchPos]
    }

    /**
     Obtain a SoundFont using an index into the `keys` name array. If the index is out-of-bounds this will return the
     first sound font in alphabetical order.
     - parameter index: the key to use
     - returns: found SoundFont object
     */
    public static func getByIndex(_ index: Int) -> SoundFont {
        guard index >= 0 && index < keys.count else { return SoundFont.library[SoundFont.keys[0]]! }
        let key = keys[index]
        return library[key]!
    }

    /**
     Obtain the index in `keys` for the given sound font name. If not found, return 0
     - parameter name: the name to look for
     - returns: found index or zero
     */
    public static func indexForName(_ name: String) -> Int { keys.firstIndex(of: name) ?? 0 }

    /// Extension for all SoundFont files in the application bundle
    public let soundFontExtension = "sf2"
    /// Presentation name of the sound font
    public let name: String
    /// Width of the sound font name
    public lazy var nameWidth = name.systemFontWidth
    /// The file name of the sound font (sans extension)
    public let fileName: String
    ///  The resolved URL for the sound font
    public let fileURL: URL
    /// The collection of Patches found in the sound font
    public let patches: [Patch]
    /// The max width of all of the patch names in the sound font
    public lazy var maxPatchNameWidth = { patches.map { $0.nameWidth }.max() ?? 100.0 }()
    /// The gain to apply to a patch in the sound font
    public let dbGain: Float32

    /**
     Initialize new SoundFont instance.
     
     - parameter name: the display name for the sound font
     - parameter fileName: the file name of the sound font in the application bundle
     - parameter patches: the array of Patch objects for the sound font
     - parameter dbGain: AudioUnit attenuation to apply to patches from this sound font [-90, +12]
     */
    init(_ name: String, fileName: String, _ patches: [Patch], _ dbGain: Float32 = 0.0 ) {
        self.name = name
        self.fileName = fileName
        self.fileURL = Bundle(for: SoundFont.self).url(forResource: fileName, withExtension: soundFontExtension)!
        self.patches = patches
        self.dbGain = min(max(dbGain, -90.0), 12.0)
        super.init()
        patches.forEach { $0.soundFont = self }
    }

    /**
     Intitialize from values found in an NSCoder decoder. For SoundFont, just get the name and stub the rest since we
     will be replaced by the real SoundFont instance in the `awakeAfter` method.
    
     - parameter aDecoder: the source of values for decoding
     */
    required public init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: .soundFontName) as? String else { return nil }
        self.name = name
        self.fileName = ""
        self.fileURL = URL(fileReferenceLiteralResourceName: "")
        self.patches = [Patch]()
        self.dbGain = 0.0
        super.init()
    }

    /**
     Replace ourselves with a real SoundFont instance
    
     - parameter aDecoder: the source of values for decoding (not used)
     - returns: real SoundFont instance
     */
    override public func awakeAfter(using aDecoder: NSCoder) -> Any? {
        return SoundFont.getByIndex(SoundFont.indexForName(self.name))
    }

    /**
     Encode the SoundFont name so that it can be located in the future.
    
     - parameter aCoder: the NSCoder encoder to hold the encoded values
     */
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: .soundFontName)
    }

    /**
     Locate a patch in the SoundFont using a display name.

     - parameter name: the display name to search for

     - returns: found Patch or nil
     */
    public func findPatch(_ name: String) -> Patch? {
        guard let found = findPatchIndex(name) else { return nil }
        return patches[found]
    }

    /**
     Obtain the index to a Patch with a given name.
     
     - parameter name: the display name to search for
     
     - returns: index of found object or nil if not found
     */
    public func findPatchIndex(_ name: String) -> Int? {
        return patches.firstIndex(where: { return $0.name == name })
    }
}

/**
 Representation of a patch in a sound font.
 */
public final class Patch: NSObject, NSCoding {

    /// Display name for the patch
    public let name: String
    /// Width of the name in the system font
    public lazy var nameWidth: CGFloat = name.systemFontWidth
    /// Bank number where the patch resides in the sound font
    public let bank: Int
    /// Program patch number where the patch resides in the sound font
    public let patch: Int
    /// The index of the Patch in the SoundFont array of patches
    public let index: Int
    /// Reference to the SoundFont parent (set by the SoundFont itself, so we guarantee that this will never be nil)
    fileprivate(set) public weak var soundFont: SoundFont! = nil

    /**
     There are two types of MIDI banks in the General MIDI standard: melody and percussion
     */
    public enum MidiBankType  {
        static public let kBankSize = 256
        
        case percussion
        case melody
        case custom(bank: Int)
        
        /// Obtain the most-significant byte of the bank for the program/voice
        public var bankMSB: Int {
            switch self {
            case .percussion: return kAUSampler_DefaultPercussionBankMSB
            case .melody:     return kAUSampler_DefaultMelodicBankMSB
            case .custom:     return kAUSampler_DefaultMelodicBankMSB
            }
        }

        /// Obtain the least-significant byte of the bank for the program/voice
        public var bankLSB: Int {
            switch self {
            case .percussion:       return kAUSampler_DefaultBankLSB
            case .melody:           return kAUSampler_DefaultBankLSB
            case .custom(let bank): return bank
            }
        }
    }

    /// Obtain the MIDI bank type for this InstrumentVoice
    public let midiBankType: MidiBankType
    public var bankMSB: Int { return midiBankType.bankMSB }
    public var bankLSB: Int { return midiBankType.bankLSB }
    
    /**
     Initialize Patch instance.
     
     - parameter name: the diplay name for the patch
     - parameter bank: the bank where the patch resides
     - parameter patch: the program ID of the patch in the sound font
     */
    init(_ name: String, _ bank: Int, _ patch: Int, _ index: Int) {
        self.name = name
        self.bank = bank
        self.patch = patch
        self.index = index

        if bank == 128 {
            self.midiBankType = .percussion
        }
        else if bank == 0 {
            self.midiBankType = .melody
        }
        else {
            self.midiBankType = .custom(bank: bank)
        }

        super.init()
    }
    
    /**
     Intitialize from values found in an NSCoder decoder. For Patch, just get the SoundFont name and patch index.

     - parameter aDecoder: the source of values for decoding
     */
    required public init?(coder aDecoder: NSCoder) {
        guard let soundFontName = aDecoder.decodeObject(forKey: .soundFontName) as? String else { return nil }
        self.name = ""
        self.bank = -1
        self.patch = -1
        self.midiBankType = .melody
        self.index = aDecoder.decodeInteger(forKey: .patchIndex)
        self.soundFont = SoundFont.getByIndex(SoundFont.indexForName(soundFontName))
    }

    /**
     Replace ourselves with a real Patch instance
     
     - parameter aDecoder: the source of values for decoding (not used)
     - returns: real Patch instance
     */
    override public func awakeAfter(using aDecoder: NSCoder) -> Any? {
        return soundFont.patches[index]
    }

    /**
     Encode the Patch so that it can be located in the future. Save the Patch's SoundFont name and its unique index.
     
     - parameter aCoder: the NSCoder encoder to hold the encoded values
     */

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(soundFont.name, forKey: .soundFontName)
        aCoder.encode(self.index, forKey: .patchIndex)
    }
}

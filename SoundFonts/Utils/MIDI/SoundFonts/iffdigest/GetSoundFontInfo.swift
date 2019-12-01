// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

public struct PatchInfo {
    public let name: String
    public let bank: Int
    public let patch: Int
}

public struct SoundFontInfo {
    public let name: String
    public let patches: [PatchInfo]
}

public func GetSoundFontInfo(data: Data) -> SoundFontInfo {
    var patches = [PatchInfo]()
    return data.withUnsafeBytes { (body) -> SoundFontInfo in
        let wrapper = SoundFontParse(body.baseAddress, data.count)
        let soundFontName = String(cString: SoundFontName(wrapper)).replacingOccurrences(of: "_", with: " ")
        for index in 0..<SoundFontPatchCount(wrapper) {
            let name = String(cString: SoundFontPatchName(wrapper, index))
            let bank = Int(SoundFontPatchBank(wrapper, index))
            let patch = Int(SoundFontPatchPatch(wrapper, index))
            // print("-- \(name) \(bank):\(patch)")
            if bank < 255 && patch < 255 && name != "EOP" {
                patches.append(PatchInfo(name: name, bank: bank, patch: patch))
            }
        }
        return SoundFontInfo(name: soundFontName, patches: patches)
    }
}

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
        let name = String(cString: SoundFontName(wrapper));
        for index in 0..<SoundFontPatchCount(wrapper) {
            let bank = Int(SoundFontPatchBank(wrapper, index))
            let patch = Int(SoundFontPatchPatch(wrapper, index))
            if bank < 255 && patch < 255 {
                patches.append(PatchInfo(name: String(cString: SoundFontPatchName(wrapper, index)),
                                         bank: bank, patch: patch))
            }
        }
        return SoundFontInfo(name: name, patches: patches)
    }
}

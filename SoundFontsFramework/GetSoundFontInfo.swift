// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import SoundFontInfoLib

public struct PatchInfo {
    public let name: String
    public let bank: Int
    public let patch: Int
}

public struct SoundFontInfo {
    public var name: String
    public let patches: [PatchInfo]
}

//swiftlint:disable identifier_name
public func GetSoundFontInfo(data: Data) -> SoundFontInfo {
//swiftlint:enable identifier_name

    var patches = [PatchInfo]()
    return data.withUnsafeBytes { (body) -> SoundFontInfo in
        let wrapper = SoundFontParse(body.baseAddress, data.count)
        let soundFontName = String(cString: SoundFontName(wrapper)).replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        for index in 0..<SoundFontPatchCount(wrapper) {
            let name = String(cString: SoundFontPatchName(wrapper, index))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let bank = Int(SoundFontPatchBank(wrapper, index))
            let patch = Int(SoundFontPatchPatch(wrapper, index))
            if bank < 255 && patch < 255 && name != "EOP" {
                patches.append(PatchInfo(name: name, bank: bank, patch: patch))
            }
        }
        return SoundFontInfo(name: soundFontName, patches: patches)
    }
}

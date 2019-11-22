//  Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

public struct PatchInfo {
    public let name: String
    public let bank: Int
    public let patch: Int
}

public func SoundFontPatchList(data: Data) -> [PatchInfo] {
    var patchInfos = [PatchInfo]()
    data.withUnsafeBytes { (body) -> Void in
        let wrapper = SoundFontParse(body.baseAddress, data.count)
        for index in 0..<PatchInfoListSize(wrapper) {
            let bank = Int(PatchInfoBank(wrapper, index))
            let patch = Int(PatchInfoPatch(wrapper, index))
            if bank < 255 && patch < 255 {
                patchInfos.append(PatchInfo(name: String(cString: PatchInfoName(wrapper, index)), bank: bank,
                                            patch: patch))
            }
        }
    }
    return patchInfos
}

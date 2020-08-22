// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import SoundFontInfoLib

//swiftlint:disable identifier_name
public func GetSoundFontInfo(data: Data) -> SoundFontInfo? {
//swiftlint:enable identifier_name
    return data.withUnsafeBytes { (body) -> SoundFontInfo? in
        return SoundFontInfo.parse(body.baseAddress, size: data.count)
    }
}

// Copyright © 2020 Brad Howes. All rights reserved.

import CoreMIDI

extension MIDIObjectRef {
    var name: String? {
        guard self != 0 else { return nil }
        var param: Unmanaged<CFString>?
        let err = MIDIObjectGetStringProperty(self, kMIDIPropertyDisplayName, &param)
        guard let tmp = param, err == noErr else { return nil }
        return tmp.takeRetainedValue() as String
    }
}

public class MIDIConnectivity: NSObject {

    public static let shared = MIDIConnectivity()

    private override init() {
        super.init()
    }

    public func getDestinationNames() -> [String] {
        let count = MIDIGetNumberOfDestinations()
        return (0..<count).compactMap { MIDIGetDestination($0).name }
    }

    public func getSourceNames() -> [String] {
        let count = MIDIGetNumberOfSources()
        return (0..<count).compactMap { MIDIGetSource($0).name }
    }
}

//  Copyright © 2020 Brad Howes. All rights reserved.

import AVFoundation

public extension AudioUnit {

    func getPropertyInfo(_ pid: AudioUnitPropertyID) throws -> (size: UInt32, writable: Bool) {
        var size: UInt32 = 0
        var writable: DarwinBoolean = false
        try AudioUnitGetPropertyInfo(self, pid, kAudioUnitScope_Global, 0, &size, &writable).check()
        return (size: size, writable: writable.boolValue)
    }

    func getPropertyValue<T>(_ pid: AudioUnitPropertyID) throws -> T {
        let (size, _) = try getPropertyInfo(pid)
        return try getPropertyValue(pid, size: size)
    }

    func getPropertyValue<T>(_ pid: AudioUnitPropertyID, size: UInt32) throws -> T {
        var size = size
        var data = UnsafeMutablePointer<T>.allocate(capacity: Int(size))
        defer { data.deallocate() }
        try AudioUnitGetProperty(self, pid, kAudioUnitScope_Global, 0, data, &size).check()
        return data.pointee
    }

    func setPropertyValue<T>(_ pid: AudioUnitPropertyID, value: T) throws {
        let (size, _) = try getPropertyInfo(pid)
        return try setPropertyValue(pid, size: size, value: value)
    }

    func setPropertyValue<T>(_ pid: AudioUnitPropertyID, size: UInt32, value: T) throws {
        var value = value
        try AudioUnitSetProperty(self, pid, kAudioUnitScope_Global, 0, &value, size).check()
    }
}

public extension OSStatus {

    func check() throws {
        if self != noErr {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(self), userInfo: nil)
        }
    }
}
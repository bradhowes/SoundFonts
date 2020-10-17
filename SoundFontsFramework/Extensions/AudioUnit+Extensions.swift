//  Copyright © 2020 Brad Howes. All rights reserved.

import AVFoundation
import os

private let log = Logging.logger("AudioUnit")

public extension AudioUnit {

    func getPropertyInfo(_ pid: AudioUnitPropertyID) throws -> (size: UInt32, writable: Bool) {
        os_log(.info, log: log, "getPropertyInfo %d", pid)
        var size: UInt32 = 0
        var writable: DarwinBoolean = false
        try AudioUnitGetPropertyInfo(self, pid, kAudioUnitScope_Global, 0, &size, &writable).check()
        os_log(.info, log: log, "size: %d writable: %d", size, writable.boolValue)
        return (size: size, writable: writable.boolValue)
    }

    func getPropertyValue<T>(_ pid: AudioUnitPropertyID) throws -> T {
        os_log(.info, log: log, "getPropertyValue %d", pid)
        let (size, _) = try getPropertyInfo(pid)
        return try getPropertyValue(pid, size: size)
    }

    func getPropertyValue<T>(_ pid: AudioUnitPropertyID, size: UInt32) throws -> T {
        var size = size
        let data = UnsafeMutablePointer<T>.allocate(capacity: Int(size))
        defer { data.deallocate() }
        try AudioUnitGetProperty(self, pid, kAudioUnitScope_Global, 0, data, &size).check()
        return data.pointee
    }

    func setPropertyValue<T>(_ pid: AudioUnitPropertyID, value: T) throws {
        let (size, _) = try getPropertyInfo(pid)
        try setPropertyValue(pid, size: size, value: value)
    }

    func setPropertyValue<T>(_ pid: AudioUnitPropertyID, size: UInt32, value: T) throws {
        var value = value
        try AudioUnitSetProperty(self, pid, kAudioUnitScope_Global, 0, &value, size).check()
    }
}

public extension OSStatus {

    func check() throws {
        if self != noErr {
            os_log(.error, log: log, "last call set error %d", Int(self))
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(self), userInfo: nil)
        }
    }
}

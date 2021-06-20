//  Copyright © 2020 Brad Howes. All rights reserved.

import AVFoundation
import os

private let log = Logging.logger("AudioUnit")

extension AudioUnit {

  /**
   Obtain a property description from an AudioUnit

   - parameter pid: the key of the property to get
   - returns: a 2-tuple containing the size of the property value and a flag if it can be updated
   - throws exception if the property is invalid
   */
  public func getPropertyInfo(_ pid: AudioUnitPropertyID) throws -> (size: UInt32, writable: Bool) {
    os_log(.info, log: log, "getPropertyInfo %d", pid)
    var size: UInt32 = 0
    var writable: DarwinBoolean = false
    try AudioUnitGetPropertyInfo(self, pid, kAudioUnitScope_Global, 0, &size, &writable).check()
    os_log(.info, log: log, "size: %d writable: %d", size, writable.boolValue)
    return (size: size, writable: writable.boolValue)
  }

  /**
   Obtain the current value of a property

   - parameter pid: the key of the property to get
   - returns: the current value
   - throws exception if the property is invalid or the size is wrong
   */
  public func getPropertyValue<T>(_ pid: AudioUnitPropertyID) throws -> T {
    os_log(.info, log: log, "getPropertyValue %d", pid)
    let (size, _) = try getPropertyInfo(pid)
    return try getPropertyValue(pid, size: size)
  }

  /**
   Obtain the current value of a property

   - parameter pid: the key of the property to get
   - parameter size: the size of the property value type
   - returns: the current value
   - throws exception if the property is invalid or the size is wrong
   */
  public func getPropertyValue<T>(_ pid: AudioUnitPropertyID, size: UInt32) throws -> T {
    var size = size
    let data = UnsafeMutablePointer<T>.allocate(capacity: Int(size))
    defer { data.deallocate() }
    try AudioUnitGetProperty(self, pid, kAudioUnitScope_Global, 0, data, &size).check()
    return data.pointee
  }

  /**
   Change a property value.

   - parameter pid: the key of the property to set
   - parameter value: the new value to use
   - throws exception if the property is invalid or the property is read-only
   */
  public func setPropertyValue<T>(_ pid: AudioUnitPropertyID, value: T) throws {
    let (size, _) = try getPropertyInfo(pid)
    try setPropertyValue(pid, size: size, value: value)
  }

  /**
   Change a property value.

   - parameter pid: the key of the property to set
   - parameter size: the size of the value type
   - parameter value: the new value to use
   - throws exception if the property is invalid or the property is read-only
   */
  public func setPropertyValue<T>(_ pid: AudioUnitPropertyID, size: UInt32, value: T) throws {
    var value = value
    try AudioUnitSetProperty(self, pid, kAudioUnitScope_Global, 0, &value, size).check()
  }
}

extension OSStatus {

  ///
  /**
   Check that the value of an OSStatus is `noErr` otherwise throw an NSError exception.
   - throws exception if not `noErr`
   */
  public func check() throws {
    if self != noErr {
      os_log(.error, log: log, "last call set error %d", Int(self))
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(self), userInfo: nil)
    }
  }
}

extension AUAudioUnitPreset {

  /**
   Initialize new instance with given values

   - parameter number: the unique number for this preset. Factory presets must be non-negative.
   - parameter name: the display name for the preset.
   */
  public convenience init(number: Int, name: String) {
    self.init()
    self.number = number
    self.name = name
  }
}

extension AUAudioUnitPreset {

  /// Obtain a custom description string of the instance
  override public var description: String { "<AuAudioUnitPreset name: \(name)/\(number)>" }
}

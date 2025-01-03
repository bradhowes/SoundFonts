// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import CoreGraphics

extension String: SettingSerializable {}
extension Int: SettingSerializable {}
extension Float: SettingSerializable {}
extension Double: SettingSerializable {}
extension Bool: SettingSerializable {}
extension Data: SettingSerializable {}
extension Date: SettingSerializable {}

extension UUID: SettingSerializable {

  @inlinable
  public static func get(key: String, defaultValue: UUID, source: Settings) -> UUID {
    guard
      let uuid = UUID(uuidString: source.get(key: key, defaultValue: defaultValue.uuidString))
    else {
      return defaultValue
    }
    return uuid
  }

  @inlinable
  public static func set(key: String, value: Tag.Key, source: Settings) {
    source.set(key: key, value: value.uuidString)
  }
}

extension Double {
  public var milliseconds: TimeInterval { self / 1000 }
  public var millisecond: TimeInterval { milliseconds }
  public var ms: TimeInterval { milliseconds }

  public var seconds: TimeInterval { self }
  public var second: TimeInterval { seconds }

  public var minutes: TimeInterval { seconds * 60 }
  public var minute: TimeInterval { minutes }

  public var hours: TimeInterval { minutes * 60 }
  public var hour: TimeInterval { hours }

  public var days: TimeInterval { hours * 24 }
  public var day: TimeInterval { days }
}

extension Comparable {

  @inlinable
  func clamped(to limits: ClosedRange<Self>) -> Self {
    min(max(self, limits.lowerBound), limits.upperBound)
  }
}

extension CGPoint: @retroactive CustomStringConvertible {
  public var description: String { "<CGPoint x: \(x), y: \(y)>"}
}

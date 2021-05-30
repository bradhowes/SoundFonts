import Foundation

extension DispatchTime {
  static func future(_ delta: DispatchTimeInterval) -> DispatchTime { DispatchTime.now() + delta }
}

import Foundation

public extension DispatchQueue {

  func asyncLater(interval: DispatchTimeInterval, qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [],
                  execute work: @escaping () -> Void) {
    asyncAfter(deadline: DispatchTime.future(interval), qos: qos, flags: flags, execute: work)
  }
}

public extension Thread {

  static func preconditionMainThread(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    precondition(isMainThread, message(), file: file, line: line)
  }
}

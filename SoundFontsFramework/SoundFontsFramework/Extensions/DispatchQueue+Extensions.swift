import Foundation

public extension DispatchQueue {

    func asyncLater(interval: DispatchTimeInterval, qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [],
                    execute work: @escaping () -> Void) {
        asyncAfter(deadline: DispatchTime.future(interval), qos: qos, flags: flags, execute: work)
    }
}

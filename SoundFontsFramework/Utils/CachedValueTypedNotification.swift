// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/**
 Derivation of TypedNotification that remembers the last `post` value and will use that for any `register` calls
 that happen *after* the `post` call.
 */
open class CachedValueTypedNotification<A>: TypedNotification<A> {

    /// The last value given in a `post` call.
    public private(set) var cachedValue: A?

    /**
     Post a notification containing the given value.

     - parameter value: the value to convey to registered observers
     */
    override open func post(value: A) {
        cachedValue = value
        super.post(value: value)
    }

    public func clear() { cachedValue = nil }

    /**
     Register a closure to invoke when `post` is called. Note that if `cachedValue` is not nil, the
     closure will be called immediately.

     - parameter block: the closure to invoke
     - returns: value that will unregister the block if it is no longer held
     */
    override open func registerOnAny(block: @escaping (A) -> Void) -> NotificationObserver {
        if let cachedValue = self.cachedValue {
            DispatchQueue.global(qos: .default).async { block(cachedValue) }
        }
        return super.registerOnAny(block: block)
    }

    /**
     Register a closure to invoke when `post` is called.

     - parameter block: the closure to invoke on the main thread
     - returns: value that will unregister the block if it is no longer held
     */
    override open func registerOnMain(block: @escaping (A) -> Void) -> NotificationObserver {
        if let cachedValue = self.cachedValue {
            DispatchQueue.main.async { block(cachedValue) }
        }
        return super.registerOnMain(block: block)
    }
}

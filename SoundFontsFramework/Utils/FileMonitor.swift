// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

/**
 Monitor a given URL for any changes that occurs to it. The URL must point to an *existing* file/directory.
 */
final public class FileMonitor {

    private let handle: DispatchSourceFileSystemObject

    /**
     Create a new monitor. Monitoring will stay active as long as the FileMonitor instance lives.

     - parameter url: the location to monitor
     - parameter block: the closure to invoke when the item changes
     - parameter location: closure receives the the URL of the item being monitored
     - returns: nil if the URL is invalid or does not point to an existing item on the device
     */
    public init?(url: URL, _ block: @escaping (_ location: URL)->Void) {
        let descriptor = open(url.path, O_EVTONLY)
        if descriptor == -1 { return nil }

        handle = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor, eventMask: .write, queue: .global(qos: .userInitiated))

        handle.setEventHandler { block(url) }
        handle.setCancelHandler { close(descriptor) }
        handle.resume()
    }

    deinit {
        self.handle.cancel()
    }
}

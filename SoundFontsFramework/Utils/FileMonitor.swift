// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

final public class FileMonitor {

    private let handle: DispatchSourceFileSystemObject

    init?(url: URL, monitor: @escaping ()->Void) {
        let descriptor = open(url.path, O_EVTONLY)
        handle = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor, eventMask: .write, queue: .global(qos: .userInitiated))

        handle.setEventHandler(handler: monitor)
        handle.setCancelHandler { close(descriptor) }
        handle.resume()
    }

    deinit {
        self.handle.cancel()
    }
}

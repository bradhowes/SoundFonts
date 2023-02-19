// Copyright © 2023 Brad Howes. All rights reserved.

import Foundation

public extension UInt8 {
  /// Obtain the upper-4 bits of the byte -- note that they are not shifted, just masked
  var nibbleHigh: UInt8 { self & 0xF0 }
  /// Obtain the lower-4 bits of the byte
  var nibbleLow: UInt8 { self & 0x0F }
}

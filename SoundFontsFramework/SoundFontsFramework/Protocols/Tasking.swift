// Copyright © 2022 Brad Howes. All rights reserved.

import Foundation

public protocol Tasking {}

extension Tasking {

  public static func onMain(_ closure: @escaping () -> Void) {
    DispatchQueue.main.async { closure() }
  }

  public static func onBackground(_ closure: @escaping () -> Void) {
    DispatchQueue.global(qos: .userInitiated).async { closure() }
  }
}

// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/// Protocol for UIViewControllers that require connections to other UIViewControllers at startup time.
public protocol ControllerConfiguration {

  /**
     Establish connections with other entities in the application.

     - parameter context: collection of known UIViewControllers and their protocol facades.
     */
  func establishConnections(_ router: ComponentContainer)
}

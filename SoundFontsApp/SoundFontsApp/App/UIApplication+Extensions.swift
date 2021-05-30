// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

extension UIApplication {

  /// Obtain the AppDelegate instance for the application
  var appDelegate: AppDelegate {
    guard let del = self.delegate as? AppDelegate else {
      fatalError("unexpected nil or type for appDelegate")
    }
    return del
  }
}

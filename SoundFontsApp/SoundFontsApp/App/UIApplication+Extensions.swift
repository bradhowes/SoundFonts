// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

extension UIApplication {

  /// Obtain the AppDelegate instance for the application
  var appDelegate: AppDelegate? { self.delegate as? AppDelegate }
}

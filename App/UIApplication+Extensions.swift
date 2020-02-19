// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

extension UIApplication {

    //swiftlint:disable force_cast
    /// Obtain the AppDelegate instance for the application
    var appDelegate: AppDelegate { delegate as! AppDelegate }
    //swiftlint:enable force_cast
}

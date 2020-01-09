// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

extension UIAlertController {
    public func show(animated: Bool = true, completion: (() -> Void)? = nil) {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        window?.visibleViewController?.present(self, animated: animated, completion: completion)
    }
}

extension UIWindow {

    public var visibleViewController: UIViewController? {
        guard let rootViewController = rootViewController else {
            return nil
        }
        return visibleViewController(for: rootViewController)
    }

    private func visibleViewController(for controller: UIViewController) -> UIViewController {
        var nextOnStackViewController: UIViewController?
        if let presented = controller.presentedViewController {
            nextOnStackViewController = presented
        } else if let navigationController = controller as? UINavigationController,
            let visible = navigationController.visibleViewController {
            nextOnStackViewController = visible
        } else if let tabBarController = controller as? UITabBarController,
            let visible = (tabBarController.selectedViewController ??
                tabBarController.presentedViewController) {
            nextOnStackViewController = visible
        }

        if let nextOnStackViewController = nextOnStackViewController {
            return visibleViewController(for: nextOnStackViewController)
        } else {
            return controller
        }
    }
}

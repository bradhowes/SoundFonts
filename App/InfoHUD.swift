// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import UIKit

final class InfoHUD: NSObject {
    static var windows = [UIWindow]()
    static let rv = UIApplication.shared.keyWindow?.subviews.first as UIView?

    static func clear() {
        self.cancelPreviousPerformRequests(withTarget: self)
        windows.removeAll(keepingCapacity: false)
    }

    static func show(text: String, duration: TimeInterval = 3.0) {
        let window = UIWindow()
        window.backgroundColor = UIColor.clear
        let mainView = UIView()
        mainView.layer.cornerRadius = 12
        mainView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)

        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = NSTextAlignment.center
        label.textColor = UIColor.systemRed
        let size = label.sizeThatFits(CGSize(width: UIScreen.main.bounds.width-82,
                                             height: CGFloat.greatestFiniteMagnitude))
        label.bounds = CGRect(origin: .zero, size: size)
        mainView.addSubview(label)

        let superFrame = CGRect(x: 0, y: 0, width: label.frame.width + 50, height: label.frame.height + 30)
        window.frame = superFrame
        mainView.frame = superFrame

        label.center = mainView.center
        window.center = rv!.center

        window.windowLevel = UIWindow.Level.alert
        window.isHidden = false
        window.addSubview(mainView)
        windows.append(window)

        self.perform(.hide, with: window, afterDelay: duration)
    }
}

fileprivate extension Selector {
    static let hide = #selector(InfoHUD.hide(_:))
}

@objc extension InfoHUD {
    static func hide(_ sender: UIWindow) {
        if let view = sender.subviews.first {
            UIView.animate(withDuration: 0.2, animations: {
                view.alpha = 0
            }, completion: { _ in
                if let index = windows.firstIndex(where: { $0 == sender }) {
                    windows.remove(at: index)
                }
            })
        }
    }
}

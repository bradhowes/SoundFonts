// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import UIKit

/**
 Manages a HUD view to show a short bit of text as an overlay on top of the existing application view.
 */
final class InfoHUD: NSObject {

    static private var windows = [UIWindow]()
    static private var rootView: UIView? { UIApplication.shared.windows.filter {$0.isKeyWindow}.first }
    static private var windowCenter: CGPoint? { rootView?.center }

    /**
     Remove any existing HUD view.
     */
    static func clear() {
        self.cancelPreviousPerformRequests(withTarget: self)
        windows.removeAll(keepingCapacity: false)
    }

    /**
     Show a HUD view with the given text. Automatically dispose of the view after `duration` seconds.

     - parameter text: the text to show in the view
     - parameter duration: the number of seconds to show the view for
     */
    static func show(text: String, duration: TimeInterval = 3.0) {
        guard let center = windowCenter else { return }

        let window = makeWindow()
        let mainView = makeMainView()
        let label = makeLabel(text: text)

        mainView.addSubview(label)

        let superFrame = CGRect(x: 0, y: 0, width: label.frame.width + 50, height: label.frame.height + 30)
        window.frame = superFrame
        mainView.frame = superFrame

        label.center = mainView.center
        window.center = center
        window.addSubview(mainView)
        windows.append(window)

        self.perform(.hide, with: window, afterDelay: duration)
    }

    static private func makeMainView() -> UIView {
        let mainView = UIView()
        mainView.layer.cornerRadius = 12
        mainView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        return mainView
    }

    static private func makeLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = NSTextAlignment.center
        label.textColor = UIColor.systemRed
        let size = label.sizeThatFits(CGSize(width: UIScreen.main.bounds.width - 82,
                                             height: CGFloat.greatestFiniteMagnitude))
        label.bounds = CGRect(origin: .zero, size: size)
        return label
    }

    static private func makeWindow() -> UIWindow {
        let window = UIWindow()
        window.backgroundColor = UIColor.clear
        window.windowLevel = UIWindow.Level.alert
        window.isHidden = false
        return window
    }
}

fileprivate extension Selector {
    static let hide = #selector(InfoHUD.hide(_:))
}

@objc extension InfoHUD {

    /**
     Hide the HUD view.

     - parameter sender: the object that is requesting the visibility change.
     */
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

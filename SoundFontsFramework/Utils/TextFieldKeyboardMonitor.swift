// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Monitors the iOS keyboard appearance and manipulates a given UIScrollView to keep the content in view when
 the keyboard appears. Contains a slot `viewToKeepVisible` which when set to a UIView will cause the
 monitor to scroll so that the view is visible.
 */
final public class TextFieldKeyboardMonitor {
    private let log = Logging.logger("TextFieldKeyboardMonitor")
    private let view: UIView
    private let scrollView: UIScrollView
    private var adjustment: CGFloat = 0.0
    private var keyboardFrame: CGRect = .zero

    public var viewToKeepVisible: UIView? { didSet { self.makeViewVisible() } }

    public init(view: UIView, scrollView: UIScrollView) {
        self.view = view
        self.scrollView = scrollView
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func adjustForKeyboard(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        self.keyboardFrame = keyboardFrame.cgRectValue

        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = .zero
            adjustment = 0.0
        }
        else {
            adjustment = self.keyboardFrame.height - view.safeAreaInsets.bottom
            os_log(.info, log: log, "adjustment %f", adjustment)
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: adjustment, right: 0)
        }

        scrollView.scrollIndicatorInsets = scrollView.contentInset
        makeViewVisible()
    }

    private func makeViewVisible() {
        guard let viewToKeepVisible = self.viewToKeepVisible else { return }
        let frame = viewToKeepVisible.convert(viewToKeepVisible.bounds, to: scrollView)
        os_log(.info, log: log, "makeViewVisible - frame: %{public}s", frame.debugDescription)
        scrollView.scrollRectToVisible(frame, animated: true)
        os_log(.info, log: log, "makeViewVisible - contentOffset: %{public}s",
               scrollView.contentOffset.debugDescription)
    }
}

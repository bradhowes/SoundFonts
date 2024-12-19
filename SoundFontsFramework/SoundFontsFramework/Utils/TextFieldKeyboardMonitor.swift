// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import os

/// Monitors the iOS keyboard appearance and manipulates a given UIScrollView to keep the content in view when
/// the keyboard appears. Contains a slot `viewToKeepVisible` which when set to a UIView will cause the
/// monitor to scroll so that the view is visible.
final class TextFieldKeyboardMonitor {
  private lazy var log: Logger = Logging.logger("TextFieldKeyboardMonitor")
  private let view: UIView
  private let scrollView: UIScrollView
  private var adjustment: CGFloat = 0.0
  private var keyboardFrame: CGRect = .zero
  private let numberKeyboardDoneProxy = UITapGestureRecognizer()

  /// The view to keep visible in the scroll view
  public var viewToKeepVisible: UIView? { didSet { self.makeViewVisible() } }

  /**
   Construct monitor for the given view and scroll view.

   - parameter view: the view to track and monitor
   - parameter scrollView: the view to adjust
   */
  init(view: UIView, scrollView: UIScrollView) {
    self.view = view
    self.scrollView = scrollView
    NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard),
                                           name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard),
                                           name: UIResponder.keyboardWillHideNotification, object: nil)
    scrollView.addGestureRecognizer(numberKeyboardDoneProxy)
    numberKeyboardDoneProxy.addClosure { _ in self.viewToKeepVisible?.endEditing(true) }
  }

  /**
   Notification handler called when there is a keyboard notification event. Adjust the scroll view if necessary to
   keep the monitored view visible.

   - parameter notification: the notification that fired
   */
  @objc private func adjustForKeyboard(_ notification: Notification) {
    guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
      return
    }

    self.keyboardFrame = keyboardFrame.cgRectValue

    if notification.name == UIResponder.keyboardWillHideNotification {
      scrollView.contentInset = .zero
      adjustment = 0.0
    } else {
      adjustment = self.keyboardFrame.height - view.safeAreaInsets.bottom
      log.debug("adjustment \(self.adjustment)")
      scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: adjustment, right: 0)
    }

    scrollView.scrollIndicatorInsets = scrollView.contentInset
    makeViewVisible()
  }

  private func makeViewVisible() {
    guard let viewToKeepVisible = self.viewToKeepVisible else { return }
    let frame = viewToKeepVisible.convert(viewToKeepVisible.bounds, to: scrollView)
    log.debug("makeViewVisible - frame: \(frame.debugDescription, privacy: .public)")
    scrollView.scrollRectToVisible(frame, animated: true)
    log.debug("makeViewVisible - contentOffset: \(self.scrollView.contentOffset.debugDescription, privacy: .public)")
  }
}

// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

/**
 Manager for tuning-related operations. Used by the FavoriteEditor and SettingsViewController.
 */
@objc
final class TuningComponent: NSObject {

  static private let shiftA4Lookup: [String] = [
    "A2",
    "B2♭",
    "B2",
    "C3",
    "D3♭",
    "D3",
    "E3♭",
    "E3",
    "F3",
    "G3♭",
    "G3",
    "A3♭",
    "A3",
    "B3♭",
    "B3",
    "C4",
    "D4♭",
    "D4",
    "E4♭",
    "E4",
    "F4",
    "G4♭",
    "G4",
    "A4♭",
    "A4",
    "A4♯",
    "B4",
    "C5",
    "C5♯",
    "D5",
    "D5♯",
    "E5",
    "F5",
    "F5♯",
    "G5",
    "G5♯",
    "A5",
    "A5♯",
    "B5",
    "C6",
    "C6♯",
    "D6",
    "D6♯",
    "E6",
    "F6",
    "F6♯",
    "G6",
    "G6♯",
    "A6"
  ]

  private let view: UIView
  private let scrollView: UIScrollView
  private let shiftA4Value: UILabel
  private let shiftA4Stepper: UIStepper
  private let standardTuningButton: UIButton
  private let scientificTuningButton: UIButton
  private let tuningCents: UITextField
  private let tuningFrequency: UITextField
  private let isActive: Bool

  private var tuningCentsValue: Float

  private lazy var numberParserFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 1
    formatter.maximumFractionDigits = 2
    return formatter
  }()

  private let textFieldKeyboardMonitor: TextFieldKeyboardMonitor

  var tuning: Float { tuningCentsValue }

  var viewToKeepVisible: UIView? {
    get { textFieldKeyboardMonitor.viewToKeepVisible }
    set { textFieldKeyboardMonitor.viewToKeepVisible = newValue }
  }

  init(
    tuning: Float,
    view: UIView,
    scrollView: UIScrollView,
    shiftA4Value: UILabel,
    shiftA4Stepper: UIStepper,
    standardTuningButton: UIButton,
    scientificTuningButton: UIButton,
    tuningCents: UITextField,
    tuningFrequency: UITextField,
    isActive: Bool
  ) {
    self.tuningCentsValue = tuning
    self.view = view
    self.scrollView = scrollView
    self.shiftA4Value = shiftA4Value
    self.shiftA4Stepper = shiftA4Stepper
    self.standardTuningButton = standardTuningButton
    self.scientificTuningButton = scientificTuningButton
    self.tuningCents = tuningCents
    self.tuningFrequency = tuningFrequency
    self.textFieldKeyboardMonitor = TextFieldKeyboardMonitor(view: view, scrollView: scrollView)
    self.isActive = isActive
    super.init()

    shiftA4Stepper.addClosure(for: .valueChanged, shiftA4Changed)
    standardTuningButton.addClosure(useStandardTuning)
    scientificTuningButton.addClosure(useScientificTuning)

    tuningCents.delegate = self
    tuningFrequency.delegate = self

    tuningCents.inputAssistantItem.leadingBarButtonGroups = []
    tuningFrequency.inputAssistantItem.trailingBarButtonGroups = []

    setTuningCents(tuning)

    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(
      self, selector: #selector(adjustForKeyboard),
      name: UIResponder.keyboardWillHideNotification, object: nil)
    notificationCenter.addObserver(
      self, selector: #selector(adjustForKeyboard),
      name: UIResponder.keyboardDidShowNotification, object: nil)
  }
}

extension TuningComponent {

  func updateState(cents: Float, transpose: Int) {
    shiftA4Stepper.value = Double(transpose)
    setTuningCents(cents)
  }
}

extension TuningComponent: UITextFieldDelegate {

  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    textFieldKeyboardMonitor.viewToKeepVisible = textField
    return true
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    DispatchQueue.main.async {
      textField.selectedTextRange = textField.textRange(from: textField.endOfDocument, to: textField.endOfDocument)
    }
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                 replacementString string: String) -> Bool {
    let invalid = NSCharacterSet(charactersIn: "0123456789.-").inverted
    let filtered = string.components(separatedBy: invalid).joined(separator: "")
    return string == filtered
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    if textField == tuningCents {
      parseTuningCents()
    } else {
      parseTuningFrequency()
    }
    textFieldKeyboardMonitor.viewToKeepVisible = nil
  }
}

private extension TuningComponent {

  func shiftA4Changed(_ stepper: Any) {
    if let stepper = stepper as? UIStepper {
      setTuningCents(Float(stepper.value) * 100)
    }
  }

  func toggledTuningEnabled(_ switch: Any) { setTuningCents(tuningCentsValue) }

  func useStandardTuning(_ button: Any) { setTuningFrequency(440.0) }

  func useScientificTuning(_ button: Any) { setTuningFrequency(432.0) }

  func setTuningFrequency(_ value: Float) { setTuningCents(frequencyToCents(value)) }

  func centsToFrequency(_ cents: Float) -> Float { pow(2.0, (cents / 1200.0)) * 440.0 }

  func frequencyToCents(_ frequency: Float) -> Float { log2(frequency / 440.0) * 1200.0 }

  func setTuningCents(_ value: Float) {
    tuningCentsValue = min(max(value, -2400.0), 2400.0)

    let transposeCents = (tuningCentsValue / 100).rounded() * 100.0
    if Float(transposeCents) == tuningCentsValue {
      if transposeCents == 0 {
        shiftA4Value.text = "None"
        shiftA4Stepper.value = 0.0
      } else {
        shiftA4Value.text = Self.shiftA4Lookup[(Int(transposeCents) + 2400) / 100]
      }
    } else {
      shiftA4Value.text = "—"
    }

    tuningCents.text = numberParserFormatter.string(from: NSNumber(value: tuningCentsValue))
    tuningFrequency.text = numberParserFormatter.string(from: NSNumber(value: centsToFrequency(tuningCentsValue)))
    if isActive {
      AudioEngine.tuningChangedNotification.post(value: tuningCentsValue)
    }
  }

  @objc func adjustForKeyboard(_ notification: Notification) {
    guard
      let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
    else {
      return
    }

    if notification.name == UIResponder.keyboardWillHideNotification {
      scrollView.contentInset = .zero
    } else {
      let localFrame = view.convert(keyboardFrame.cgRectValue, from: view.window)
      let shift = localFrame.height - view.safeAreaInsets.bottom
      scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: shift, right: 0)
    }

    scrollView.scrollIndicatorInsets = scrollView.contentInset
  }

  func parseTuningCents() {
    guard let text = tuningCents.text else {
      setTuningCents(tuningCentsValue)
      return
    }

    guard let value = numberParserFormatter.number(from: text) else {
      setTuningCents(tuningCentsValue)
      return
    }

    setTuningCents(value.floatValue)
  }

  func parseTuningFrequency() {
    guard let text = tuningFrequency.text else {
      setTuningCents(tuningCentsValue)
      return
    }

    guard let value = numberParserFormatter.number(from: text) else {
      setTuningCents(tuningCentsValue)
      return
    }

    setTuningFrequency(value.floatValue)
  }
}

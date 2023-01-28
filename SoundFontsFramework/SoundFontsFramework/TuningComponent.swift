// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

@objc
public final class TuningComponent: NSObject {

  static private let shiftSharpLookup: [Int: String] = [
    100: "A♯",
    200: "B",
    300: "C",
    400: "C♯",
    500: "D",
    600: "D♯",
    700: "E",
    800: "F",
    900: "F♯",
    1000: "G",
    1100: "G♯"
  ]

  static private let shiftFlatLookup: [Int: String] = [
    100: "B♭",
    200: "B",
    300: "C",
    400: "D♭",
    500: "D",
    600: "E♭",
    700: "E",
    800: "F",
    900: "G♭",
    1000: "G",
    1100: "A♭"
  ]

  private let view: UIView
  private let scrollView: UIScrollView
  private let transposeValue: UILabel
  private let transposeStepper: UIStepper
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

  public var tuning: Float { tuningCentsValue }

  public var viewToKeepVisible: UIView? {
    get { textFieldKeyboardMonitor.viewToKeepVisible }
    set { textFieldKeyboardMonitor.viewToKeepVisible = newValue }
  }

  public init(
    tuning: Float,
    view: UIView,
    scrollView: UIScrollView,
    transposeValue: UILabel,
    transposeStepper: UIStepper,
    standardTuningButton: UIButton,
    scientificTuningButton: UIButton,
    tuningCents: UITextField,
    tuningFrequency: UITextField,
    isActive: Bool
  ) {
    self.tuningCentsValue = tuning
    self.view = view
    self.scrollView = scrollView
    self.transposeValue = transposeValue
    self.transposeStepper = transposeStepper
    self.standardTuningButton = standardTuningButton
    self.scientificTuningButton = scientificTuningButton
    self.tuningCents = tuningCents
    self.tuningFrequency = tuningFrequency
    self.textFieldKeyboardMonitor = TextFieldKeyboardMonitor(view: view, scrollView: scrollView)
    self.isActive = isActive
    super.init()

    transposeStepper.addClosure(transposeChanged)
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

  public func updateState(cents: Float, transpose: Int) {
    transposeStepper.value = Double(transpose)
    setTuningCents(cents)
  }
}

extension TuningComponent {

  private func transposeChanged(_ stepper: Any) {
    if let stepper = stepper as? UIStepper {
      setTuningCents(Float(abs(stepper.value)) * 100)
    }
  }

  private func toggledTuningEnabled(_ switch: Any) { setTuningCents(tuningCentsValue) }

  private func useStandardTuning(_ button: Any) { setTuningFrequency(440.0) }

  private func useScientificTuning(_ button: Any) { setTuningFrequency(432.0) }

  private func setTuningFrequency(_ value: Float) { setTuningCents(frequencyToCents(value)) }

  private func centsToFrequency(_ cents: Float) -> Float { pow(2.0, (cents / 1200.0)) * 440.0 }

  private func frequencyToCents(_ frequency: Float) -> Float { log2(frequency / 440.0) * 1200.0 }

  private func setTuningCents(_ value: Float) {
    tuningCentsValue = min(max(value, -2400.0), 2400.0)

    let transposeCents = (tuningCentsValue / 100).rounded() * 100.0
    if Float(transposeCents) == tuningCentsValue {
      if transposeCents == 0 {
        transposeValue.text = "None"
        transposeStepper.value = 0.0
      } else if transposeStepper.value < 0 {
        transposeValue.text = Self.shiftFlatLookup[Int(transposeCents)]
      } else {
        transposeValue.text = Self.shiftSharpLookup[Int(transposeCents)]
      }
    } else {
      transposeValue.text = "—"
    }

    tuningCents.text = numberParserFormatter.string(from: NSNumber(value: tuningCentsValue))
    tuningFrequency.text = numberParserFormatter.string(from: NSNumber(value: centsToFrequency(tuningCentsValue)))
    if isActive {
      SynthManager.tuningChangedNotification.post(value: tuningCentsValue)
    }
  }
}

extension TuningComponent: UITextFieldDelegate {

  public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    textFieldKeyboardMonitor.viewToKeepVisible = textField
    return true
  }

  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }

  public func textFieldDidBeginEditing(_ textField: UITextField) {
    DispatchQueue.main.async {
      textField.selectedTextRange = textField.textRange(from: textField.endOfDocument, to: textField.endOfDocument)
    }
  }

  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                        replacementString string: String) -> Bool {
    let invalid = NSCharacterSet(charactersIn: "0123456789.-").inverted
    let filtered = string.components(separatedBy: invalid).joined(separator: "")
    return string == filtered
  }

  public func textFieldDidEndEditing(_ textField: UITextField) {
    if textField == tuningCents {
      parseTuningCents()
    } else {
      parseTuningFrequency()
    }
    textFieldKeyboardMonitor.viewToKeepVisible = nil
  }
}

extension TuningComponent {

  @objc private func adjustForKeyboard(_ notification: Notification) {
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
}

extension TuningComponent {

  private func parseTuningCents() {
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

  private func parseTuningFrequency() {
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

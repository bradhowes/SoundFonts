// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

@objc
public final class TuningComponent: NSObject {

    @objc dynamic public private(set) var tuning: Float

    private let view: UIView
    private let scrollView: UIScrollView
    private let tuningEnabledSwitch: UISwitch
    private let standardTuningButton: UIButton
    private let scientificTuningButton: UIButton
    private let tuningCents: UITextField
    private let tuningFrequency: UITextField
    private let numberKeyboardDoneProxy = UITapGestureRecognizer()

    private lazy var numberParserFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    public init(tuning: Float,
                view: UIView,
                scrollView: UIScrollView,
                tuningEnabledSwitch: UISwitch,
                standardTuningButton: UIButton,
                scientificTuningButton: UIButton,
                tuningCents: UITextField,
                tuningFrequency: UITextField) {
        self.tuning = tuning
        self.view = view
        self.scrollView = scrollView
        self.tuningEnabledSwitch = tuningEnabledSwitch
        self.standardTuningButton = standardTuningButton
        self.scientificTuningButton = scientificTuningButton
        self.tuningCents = tuningCents
        self.tuningFrequency = tuningFrequency
        super.init()

        standardTuningButton.addClosure(useStandardTuning)
        scientificTuningButton.addClosure(useScientificTuning)

        tuningCents.delegate = self
        tuningFrequency.delegate = self

        tuningCents.inputAssistantItem.leadingBarButtonGroups = []
        tuningFrequency.inputAssistantItem.trailingBarButtonGroups = []

        view.addGestureRecognizer(numberKeyboardDoneProxy)
        numberKeyboardDoneProxy.addClosure {_ in view.endEditing(true) }

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard),
                                       name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard),
                                       name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
}

extension TuningComponent {

    public func updateState(enabled: Bool, cents: Float) {
        tuningEnabledSwitch.setOn(enabled, animated: false)
        setTuningCents(cents)
    }
}

extension TuningComponent {

    private func updateEnabledState(_ enabled: Bool) {
        tuningEnabledSwitch.setOn(enabled, animated: false)
        standardTuningButton.isEnabled = enabled
        scientificTuningButton.isEnabled = enabled
        tuningCents.isEnabled = enabled
        tuningFrequency.isEnabled = enabled
    }

    private func useStandardTuning(_ button: Any) { setTuningFrequency(440.0) }

    private func useScientificTuning(_ button: Any) { setTuningFrequency(432.0) }

    private func centsToFrequency(_ cents: Float) -> Float { pow(2.0, (cents / 1200.0)) * 440.0 }

    private func frequencyToCents(_ frequency: Float) -> Float { log2(frequency / 440.0) * 1200.0 }

    private func setTuningCents(_ cents: Float) {
        let cents = min(max(cents, -2400.0), 2400.0)
        let frequency = centsToFrequency(cents)
        tuningCents.text = numberParserFormatter.string(from: NSNumber(value: cents))
        tuningFrequency.text = numberParserFormatter.string(from: NSNumber(value: frequency))
        tuning = cents
        Sampler.globalTuningNotification.post(value: cents)
    }

    private func setTuningFrequency(_ frequency: Float) {
        let cents = frequencyToCents(frequency)
        setTuningCents(cents)
    }
}

extension TuningComponent: UITextFieldDelegate {

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        DispatchQueue.main.async {
            textField.selectedTextRange = textField.textRange(from: textField.endOfDocument,
                                                              to: textField.endOfDocument)
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
            parseGlobalTuningCents()
        }
        else {
            parseGlobalTuningFrequency()
        }
    }
}

extension TuningComponent {

    @objc private func adjustForKeyboard(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        print(notification.name)
        print(keyboardFrame)

        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = .zero
        } else {
            let localFrame = view.convert(keyboardFrame.cgRectValue, from: view.window)
            print(localFrame)
            let shift = localFrame.height - view.safeAreaInsets.bottom
            print(shift)
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: shift, right: 0)
        }

        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }
}

extension TuningComponent {

    private func parseGlobalTuningCents() {
        guard let text = tuningCents.text else {
            setTuningCents(tuning)
            return
        }

        guard let value = numberParserFormatter.number(from: text) else {
            setTuningCents(tuning)
            return
        }

        setTuningCents(value.floatValue)
    }

    private func parseGlobalTuningFrequency() {
        guard let text = tuningFrequency.text else {
            setTuningCents(tuning)
            return
        }

        guard let value = numberParserFormatter.number(from: text) else {
            setTuningCents(tuning)
            return
        }

        setTuningFrequency(value.floatValue)
    }
}

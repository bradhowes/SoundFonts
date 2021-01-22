// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import MessageUI
import UIKit
import os

public enum KeyLabelOption: Int {
    case off
    case all
    case cOnly

    public static var savedSetting: KeyLabelOption {
        return Self(rawValue: Settings.shared.keyLabelOption) ?? .cOnly
    }
}

/**
 Manages window showing various runtime settings and options.
 */
public final class SettingsViewController: UIViewController {
    private let log = Logging.logger("SetVC")

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var upperBackground: UIView!
    @IBOutlet private weak var doneButton: UIBarButtonItem!

    @IBOutlet private weak var keyLabelsStackView: UIStackView!
    @IBOutlet private weak var solfegeStackView: UIStackView!
    @IBOutlet private weak var playSamplesStackView: UIStackView!
    @IBOutlet private weak var keyWidthStackView: UIStackView!
    @IBOutlet private weak var slideKeyboardStackView: UIStackView!
    @IBOutlet private weak var divider1: UIView!
    @IBOutlet private weak var midiChannelStackView: UIStackView!
    @IBOutlet private weak var bluetoothMIDIConnectStackView: UIStackView!
    @IBOutlet private weak var divider2: UIView!
    @IBOutlet private weak var copyFilesStackView: UIStackView!
    @IBOutlet private weak var removeSoundFontsStackView: UIStackView!
    @IBOutlet private weak var restoreSoundFontsStackView: UIStackView!
    @IBOutlet private weak var divider3: UIView!
    @IBOutlet private weak var exportSoundFontsStackView: UIStackView!
    @IBOutlet private weak var importSoundFontsStackView: UIStackView!
    @IBOutlet private weak var divider4: UIView!
    @IBOutlet private weak var versionReviewStackView: UIStackView!
    @IBOutlet private weak var contactDeveloperStackView: UIStackView!

    @IBOutlet private weak var keyLabelOption: UISegmentedControl!
    @IBOutlet private weak var showSolfegeNotes: UISwitch!
    @IBOutlet private weak var playSample: UISwitch!
    @IBOutlet private weak var keyWidthSlider: UISlider!
    @IBOutlet private weak var slideKeyboard: UISwitch!
    @IBOutlet private weak var midiChannel: UILabel!
    @IBOutlet private weak var midiChannelStepper: UIStepper!
    @IBOutlet private weak var bluetoothMIDIConnect: UIButton!
    @IBOutlet private weak var copyFiles: UISwitch!

    @IBOutlet weak var divider5: UIView!
    @IBOutlet weak var globalTuningTitle: UILabel!
    @IBOutlet weak var standardTuningLabel: UILabel!
    @IBOutlet weak var standardTuningButton: UIButton!
    @IBOutlet weak var scientificTuningLabel: UILabel!
    @IBOutlet weak var scientificTuningButton: UIButton!
    @IBOutlet weak var globalTuningCentsLabel: UILabel!
    @IBOutlet weak var globalTuningCents: UITextField!
    @IBOutlet weak var globalTuningFrequencyLabel: UILabel!
    @IBOutlet weak var globalTuningFrequency: UITextField!
    @IBOutlet private weak var useStandardTuning: UIButton!
    @IBOutlet private weak var useVerdiTuning: UIButton!

    @IBOutlet private weak var removeDefaultSoundFonts: UIButton!
    @IBOutlet private weak var restoreDefaultSoundFonts: UIButton!
    @IBOutlet private weak var review: UIButton!
    @IBOutlet private weak var contactButton: UIButton!

    private var revealKeyboardForKeyWidthChanges = false
    private let numberKeyboardDoneProxy = UITapGestureRecognizer()

    public var soundFonts: SoundFonts!
    public var isMainApp = true

    private lazy var numberParserFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()
        globalTuningCents.delegate = self
        globalTuningFrequency.delegate = self
        review.isEnabled = isMainApp
        keyLabelOption.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.lightGray], for: .normal)
        keyLabelOption.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
        keyWidthSlider.maximumValue = 96.0
        keyWidthSlider.minimumValue = 32.0
        keyWidthSlider.isContinuous = true

        // iOS bug? Workaround to get the tint to affect the stepper button labels
        midiChannelStepper.setDecrementImage(midiChannelStepper.decrementImage(for: .normal), for: .normal)
        midiChannelStepper.setIncrementImage(midiChannelStepper.incrementImage(for: .normal), for: .normal)

        globalTuningCents.inputAssistantItem.leadingBarButtonGroups = []
        globalTuningFrequency.inputAssistantItem.trailingBarButtonGroups = []

        preferredContentSize = contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        view.addGestureRecognizer(numberKeyboardDoneProxy)
        numberKeyboardDoneProxy.addClosure { [weak self] _ in
            self?.view.endEditing(true)
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        precondition(soundFonts != nil, "nil soundFonts")
        super.viewWillAppear(animated)

        revealKeyboardForKeyWidthChanges = true
        if let popoverPresentationVC = self.parent?.popoverPresentationController {
            revealKeyboardForKeyWidthChanges = popoverPresentationVC.arrowDirection == .unknown
        }

        playSample.isOn = Settings.shared.playSample
        showSolfegeNotes.isOn = Settings.shared.showSolfegeLabel
        keyLabelOption.selectedSegmentIndex = KeyLabelOption.savedSetting.rawValue
        updateButtonState()

        keyWidthSlider.value = Settings.shared.keyWidth
        slideKeyboard.isOn = Settings.shared.slideKeyboard

        midiChannelStepper.value = Double(Settings.instance.midiChannel)
        updateMidiChannel()

        slideKeyboard.isOn = Settings.shared.slideKeyboard

        let useVerdiTuning = Settings.shared.useVerdiTuning
        if useVerdiTuning {
            setVerdiTuningState(useVerdiTuning)
        }
        else {
            let globalTuning = Settings.shared.globalTuning
            setGlobalTuningCents(globalTuning)
        }

        copyFiles.isOn = Settings.shared.copyFilesWhenAdding

        endShowKeyboard()

        let isAUv3 = !isMainApp
        keyLabelsStackView.isHidden = isAUv3
        solfegeStackView.isHidden = isAUv3
        playSamplesStackView.isHidden = isAUv3
        keyWidthStackView.isHidden = isAUv3
        slideKeyboardStackView.isHidden = isAUv3
        divider1.isHidden = isAUv3
        midiChannelStackView.isHidden = isAUv3
        bluetoothMIDIConnectStackView.isHidden = isAUv3
        divider2.isHidden = isAUv3

        preferredContentSize = contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard),
                                       name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard),
                                       name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
}

extension SettingsViewController {

    @IBAction func setStandardTuningState(_ state: Bool) { setGlobalTuningFrequency(440.0) }

    @IBAction func setVerdiTuningState(_ state: Bool) { setGlobalTuningFrequency(432.0) }

    private func centsToFrequency(_ cents: Float) -> Float { pow(2.0, (cents / 1200.0)) * 440.0 }

    private func frequencyToCents(_ frequency: Float) -> Float { log2(frequency / 440.0) * 1200.0 }

    private func setGlobalTuningCents(_ cents: Float) {
        let cents = min(max(cents, -2400.0), 2400.0)
        let frequency = centsToFrequency(cents)
        globalTuningCents.text = numberParserFormatter.string(from: NSNumber(value: cents))
        globalTuningFrequency.text = numberParserFormatter.string(from: NSNumber(value: frequency))
        Settings.shared.globalTuning = cents
    }

    private func setGlobalTuningFrequency(_ frequency: Float) {
        let cents = frequencyToCents(frequency)
        setGlobalTuningCents(cents)
    }

    private func beginShowKeyboard() {
        copyFilesStackView.isHidden = true
        midiChannelStackView.isHidden = true
        slideKeyboardStackView.isHidden = true
        bluetoothMIDIConnectStackView.isHidden = true
        removeSoundFontsStackView.isHidden = true
        restoreSoundFontsStackView.isHidden = true
        exportSoundFontsStackView.isHidden = true
        importSoundFontsStackView.isHidden = true
        versionReviewStackView.isHidden = true
        contactDeveloperStackView.isHidden = true
        globalTuningTitle.isHidden = true
        standardTuningLabel.isHidden = true
        standardTuningButton.isHidden = true
        scientificTuningLabel.isHidden = true
        scientificTuningButton.isHidden = true
        globalTuningCentsLabel.isHidden = true
        globalTuningCents.isHidden = true
        globalTuningFrequencyLabel.isHidden = true
        globalTuningFrequency.isHidden = true
        useStandardTuning.isHidden = true
        useVerdiTuning.isHidden = true
        divider1.isHidden = true
        divider2.isHidden = true
        divider3.isHidden = true
        divider4.isHidden = true
        divider5.isHidden = true
        view.backgroundColor = contentView.backgroundColor?.withAlphaComponent(0.2)
        contentView.backgroundColor = contentView.backgroundColor?.withAlphaComponent(0.0)
    }

    private func endShowKeyboard() {
        let isAUv3 = !isMainApp
        copyFilesStackView.isHidden = false
        midiChannelStackView.isHidden = isAUv3
        slideKeyboardStackView.isHidden = isAUv3
        bluetoothMIDIConnectStackView.isHidden = isAUv3
        removeSoundFontsStackView.isHidden = false
        restoreSoundFontsStackView.isHidden = false
        exportSoundFontsStackView.isHidden = false
        importSoundFontsStackView.isHidden = false
        versionReviewStackView.isHidden = false
        contactDeveloperStackView.isHidden = false
        divider1.isHidden = isAUv3
        divider2.isHidden = isAUv3
        divider3.isHidden = false
        divider4.isHidden = false
        view.backgroundColor = contentView.backgroundColor?.withAlphaComponent(1.0)
        contentView.backgroundColor = contentView.backgroundColor?.withAlphaComponent(1.0)
    }

    @IBAction func keyWidthEditingDidBegin(_ sender: Any) {
        os_log(.info, log: log, "keyWidthEditingDidBegin")
        guard revealKeyboardForKeyWidthChanges else { return }
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0.0, options: [.allowUserInteraction],
                                                       animations: self.beginShowKeyboard)
    }

    @IBAction func keyWidthEditingDidEnd(_ sender: Any) {
        os_log(.info, log: log, "keyWidthEditingDidEnd")
        guard revealKeyboardForKeyWidthChanges else { return }
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0.0, options: [.allowUserInteraction],
                                                       animations: self.endShowKeyboard)
    }

    private func updateButtonState() {
        restoreDefaultSoundFonts.isEnabled = !soundFonts.hasAllBundled
        removeDefaultSoundFonts.isEnabled = soundFonts.hasAnyBundled
    }

    @IBAction private func close(_ sender: Any) { dismiss(animated: true) }

    @IBAction func visitAppStore(_ sender: Any) { NotificationCenter.default.post(Notification(name: .visitAppStore)) }

    @IBAction private func toggleShowSolfegeNotes(_ sender: Any) {
        Settings.shared.showSolfegeLabel = self.showSolfegeNotes.isOn
    }

    @IBAction private func togglePlaySample(_ sender: Any) {
        Settings.shared.playSample = self.playSample.isOn
    }

    @IBAction private func keyLabelOptionChanged(_ sender: Any) {
        Settings.shared.keyLabelOption = self.keyLabelOption.selectedSegmentIndex
    }

    @IBAction private func toggleSlideKeyboard(_ sender: Any) {
        Settings.shared.slideKeyboard = self.slideKeyboard.isOn
    }

    @IBAction func midiChannelStep(_ sender: UIStepper) {
        updateMidiChannel()
        Settings.instance.midiChannel = Int(sender.value)
    }

    @IBAction func connectBluetoothMIDIDevices(_ sender: Any) {
        os_log(.info, log: log, "connectBluetoothMIDIDevices")
        let vc = CABTMIDICentralViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction private func toggleCopyFiles(_ sender: Any) {
        if self.copyFiles.isOn == false {
            let ac = UIAlertController(title: "Disable Copying?", message: """
Direct file access can lead to unusable SF2 file references if the file moves or is not immedately available on the
device. Are you sure you want to disable copying?
""", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
                Settings.shared.copyFilesWhenAdding = false
            })
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                self.copyFiles.isOn = true
            })
            present(ac, animated: true)
        }
        else {
            Settings.shared.copyFilesWhenAdding = true
        }
    }

    @IBAction private func keyWidthChange(_ sender: Any) {
        let previousValue = Settings.shared.keyWidth.rounded()
        var newValue = keyWidthSlider.value.rounded()
        if abs(newValue - 64.0) < 4.0 { newValue = 64.0 }
        keyWidthSlider.value = newValue

        if newValue != previousValue {
            os_log(.info, log: log, "new key width: %f", newValue)
            Settings.shared.keyWidth = newValue
        }
    }

    @IBAction private func removeDefaultSoundFonts(_ sender: Any) {
        soundFonts.removeBundled()
        updateButtonState()
        postNotice(msg: "Removed entries to the built-in sound fonts.")
    }

    @IBAction private func restoreDefaultSoundFonts(_ sender: Any) {
        soundFonts.restoreBundled()
        updateButtonState()
        postNotice(msg: "Restored entries to the built-in sound fonts.")
    }

    @IBAction private func exportSoundFonts(_ sender: Any) {
        let (good, total) = soundFonts.exportToLocalDocumentsDirectory()
        switch total {
        case 0: postNotice(msg: "Nothing to export.")
        case 1: postNotice(msg: good == 1 ? "Exported \(good) file." :  "Failed to export file.")
        default: postNotice(msg: "Exported \(good) out of \(total) files.")
        }
    }

    @IBAction private func importSoundFonts(_ sender: Any) {
        let (good, total) = soundFonts.importFromLocalDocumentsDirectory()
        switch total {
        case 0: postNotice(msg: "Nothing to import.")
        case 1: postNotice(msg: good == 1 ? "Imported \(good) soundfont." : "Failed to import soundfont.")
        default: postNotice(msg: "Imported \(good) out of \(total) soundfonts.")
        }
    }

    private func updateMidiChannel() {
        let value = Int(midiChannelStepper.value)
        midiChannel.text = value == -1 ? "Any" : "\(value + 1)"
    }

    private func postNotice(msg: String) {
        let alertController = UIAlertController(title: "SoundFonts",
                                                message: msg,
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: "OK", style: .cancel) { _ in }
        alertController.addAction(cancel)

        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY,
                                                  width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        present(alertController, animated: true, completion: nil)
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {

    @IBAction private func sendEmail(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            let bundle = Bundle(for: Self.self)
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["bradhowes@mac.com"])
            mail.setSubject("Note about your SoundFonts app")
            mail.setMessageBody("<p>Regarding your SoundFonts app (\(bundle.versionString)):</p><p></p>", isHTML: true)
            present(mail, animated: true)
        } else {
            postNotice(msg: "Unable to send an email message from the app.")
        }
    }

    public func mailComposeController(_ controller: MFMailComposeViewController,
                                      didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

extension SettingsViewController: UITextFieldDelegate {

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

    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == globalTuningCents {
            parseGlobalTuningCents()
        }
        else {
            parseGlobalTuningFrequency()
        }
    }

    @IBAction private func adjustForKeyboard(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
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

extension SettingsViewController {

    private func parseGlobalTuningCents() {
        guard let text = globalTuningCents.text else {
            setGlobalTuningCents(Settings.shared.globalTuning)
            return
        }

        guard let value = numberParserFormatter.number(from: text) else {
            setGlobalTuningCents(Settings.shared.globalTuning)
            return
        }

        setGlobalTuningCents(value.floatValue)
    }

    private func parseGlobalTuningFrequency() {
        guard let text = globalTuningFrequency.text else {
            setGlobalTuningCents(Settings.shared.globalTuning)
            return
        }

        guard let value = numberParserFormatter.number(from: text) else {
            setGlobalTuningCents(Settings.shared.globalTuning)
            return
        }

        setGlobalTuningFrequency(value.floatValue)
    }
}

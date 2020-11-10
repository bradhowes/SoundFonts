// Copyright © 2020 Brad Howes. All rights reserved.

import MessageUI
import UIKit
import os

public enum KeyLabelOption: Int {
    case off
    case all
    case cOnly

    public static var savedSetting: KeyLabelOption {
        return Self(rawValue: settings.keyLabelOption) ?? .cOnly
    }
}

/**
 Manages window showing various runtime settings and options.
 */
public final class SettingsViewController: UIViewController {
    private let log = Logging.logger("SetVC")

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var upperBackground: UIView!
    @IBOutlet private weak var doneButton: UIBarButtonItem!

    @IBOutlet private weak var playSamplesStackView: UIStackView!
    @IBOutlet private weak var keyLabelsStackView: UIStackView!
    @IBOutlet private weak var keyWidthStackView: UIStackView!
    @IBOutlet private weak var solfegeStackView: UIStackView!

    @IBOutlet weak var midiChannelStackView: UIStackView!
    @IBOutlet private weak var slideKeyboardStackView: UIStackView!
    @IBOutlet private weak var copyFilesStackView: UIStackView!
    @IBOutlet private weak var removeSoundFontsStackView: UIStackView!
    @IBOutlet private weak var restoreSoundFontsStackView: UIStackView!
    @IBOutlet private weak var exportSoundFontsStackView: UIStackView!
    @IBOutlet private weak var importSoundFontsStackView: UIStackView!
    @IBOutlet private weak var versionReviewStackView: UIStackView!
    @IBOutlet private weak var contactDeveloperStackView: UIStackView!

    @IBOutlet private weak var playSample: UISwitch!
    @IBOutlet private weak var keyLabelOption: UISegmentedControl!
    @IBOutlet private weak var showSolfegeNotes: UISwitch!
    @IBOutlet private weak var keyWidthSlider: UISlider!
    @IBOutlet private weak var midiChannel: UILabel!
    @IBOutlet private weak var midiChannelStepper: UIStepper!
    @IBOutlet private weak var slideKeyboard: UISwitch!
    @IBOutlet private weak var copyFiles: UISwitch!

    @IBOutlet private weak var removeDefaultSoundFonts: UIButton!
    @IBOutlet private weak var restoreDefaultSoundFonts: UIButton!
    @IBOutlet private weak var review: UIButton!
    @IBOutlet private weak var contactButton: UIButton!

    private var revealKeyboardForKeyWidthChanges = false

    public var soundFonts: SoundFonts!
    public var isMainApp = true

    override public func viewWillAppear(_ animated: Bool) {
        precondition(soundFonts != nil, "nil soundFonts")
        super.viewWillAppear(animated)

        // TODO: remove when copyFiles support is done
        copyFilesStackView.isHidden = true

        revealKeyboardForKeyWidthChanges = false
        if let popoverPresentationVC = self.parent?.popoverPresentationController {
            revealKeyboardForKeyWidthChanges = popoverPresentationVC.arrowDirection == .unknown
        }

        playSample.isOn = settings[.playSample]
        showSolfegeNotes.isOn = settings[.showSolfegeLabel]

        keyLabelOption.selectedSegmentIndex = KeyLabelOption.savedSetting.rawValue
        keyLabelOption.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.lightGray], for: .normal)
        keyLabelOption.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)

        updateButtonState()

        keyWidthSlider.maximumValue = 96.0
        keyWidthSlider.minimumValue = 32.0
        keyWidthSlider.isContinuous = true
        keyWidthSlider.value = settings[.keyWidth]

        slideKeyboardStackView.isHidden = false
        slideKeyboard.isOn = settings.slideKeyboard

        // iOS bug? Workaround to get the tint to affect the stepper button labels
        midiChannelStepper.setDecrementImage(midiChannelStepper.decrementImage(for: .normal), for: .normal)
        midiChannelStepper.setIncrementImage(midiChannelStepper.incrementImage(for: .normal), for: .normal)
        midiChannelStepper.value = Double(settings.midiChannel)
        updateMidiChannel()

        slideKeyboard.isOn = settings[.slideKeyboard]
        copyFiles.isOn = settings[.copyFilesWhenAdding]

        let isAUv3 = !isMainApp
        solfegeStackView.isHidden = isAUv3
        keyLabelsStackView.isHidden = isAUv3
        keyWidthStackView.isHidden = isAUv3
        midiChannelStackView.isHidden = isAUv3
        slideKeyboardStackView.isHidden = isAUv3

        review.isEnabled = isMainApp

        endShowKeyboard()

        preferredContentSize = contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}

extension SettingsViewController {

    private func beginShowKeyboard() {
        copyFilesStackView.isHidden = true
        midiChannelStackView.isHidden = true
        slideKeyboardStackView.isHidden = true
        removeSoundFontsStackView.isHidden = true
        restoreSoundFontsStackView.isHidden = true
        exportSoundFontsStackView.isHidden = true
        importSoundFontsStackView.isHidden = true
        versionReviewStackView.isHidden = true
        contactDeveloperStackView.isHidden = true
        view.backgroundColor = contentView.backgroundColor?.withAlphaComponent(0.2)
        contentView.backgroundColor = contentView.backgroundColor?.withAlphaComponent(0.0)
    }

    private func endShowKeyboard() {
        // TODO: remove when copyFiles support is done
        // copyFilesStackView.isHidden = false
        midiChannelStackView.isHidden = false
        slideKeyboardStackView.isHidden = false
        removeSoundFontsStackView.isHidden = false
        restoreSoundFontsStackView.isHidden = false
        exportSoundFontsStackView.isHidden = false
        importSoundFontsStackView.isHidden = false
        versionReviewStackView.isHidden = false
        contactDeveloperStackView.isHidden = false
        view.backgroundColor = contentView.backgroundColor?.withAlphaComponent(1.0)
        contentView.backgroundColor = contentView.backgroundColor?.withAlphaComponent(1.0)
    }

    @IBAction func keyWidthEditingDidBegin(_ sender: Any) {
        os_log(.info, log: log, "keyWidthEditingDidBegin")
        guard revealKeyboardForKeyWidthChanges else { return }
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0.0, options: [.allowUserInteraction],
                                                       animations: self.beginShowKeyboard,
                                                       completion: { _ in self.beginShowKeyboard() })
    }

    @IBAction func keyWidthEditingDidEnd(_ sender: Any) {
        os_log(.info, log: log, "keyWidthEditingDidEnd")
        guard revealKeyboardForKeyWidthChanges else { return }
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0.0, options: [.allowUserInteraction],
                                                       animations: self.endShowKeyboard,
                                                       completion: { _ in self.endShowKeyboard() })
    }
    private func updateButtonState() {
        restoreDefaultSoundFonts.isEnabled = !soundFonts.hasAllBundled
        removeDefaultSoundFonts.isEnabled = soundFonts.hasAnyBundled
    }

    @IBAction private func close(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @IBAction func visitAppStore(_ sender: Any) {
        NotificationCenter.default.post(Notification(name: .visitAppStore))
    }

    @IBAction private func toggleShowSolfegeNotes(_ sender: Any) {
        settings[.showSolfegeLabel] = self.showSolfegeNotes.isOn
    }

    @IBAction private func togglePlaySample(_ sender: Any) {
        settings[.playSample] = self.playSample.isOn
    }

    @IBAction private func keyLabelOptionChanged(_ sender: Any) {
        settings.keyLabelOption = self.keyLabelOption.selectedSegmentIndex
    }

    @IBAction func midiChannelStep(_ sender: UIStepper) {
        updateMidiChannel()
        settings.midiChannel = Int(sender.value)
    }

    @IBAction private func toggleCopyFiles(_ sender: Any) {
        if self.copyFiles.isOn == false {
            let ac = UIAlertController(title: "Disable Copying?", message: """
Direct file access can lead to unusable SF2 file references if the file moves or is not immedately available on the device. Are you sure you want to disable copying?
""", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Yes", style: .default) { _ in settings.copyFilesWhenAdding = false })
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in self.copyFiles.isOn = true })
            present(ac, animated: true)
        }
        else {
            settings.copyFilesWhenAdding = true
        }
    }

    @IBAction private func keyWidthChange(_ sender: Any) {
        let prevValue = settings.keyWidth.rounded()
        var newValue = keyWidthSlider.value.rounded()
        if abs(newValue - 64.0) < 4.0 { newValue = 64.0 }
        keyWidthSlider.value = newValue

        if newValue != prevValue {
            os_log(.info, log: log, "new key width: %f", newValue)
            settings[.keyWidth] = newValue
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

    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

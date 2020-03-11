// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public extension SettingKeys {
    static let showSolfegeLabel = SettingKey<Bool>("showSolfegeLabel", defaultValue: true)
    static let playSample = SettingKey<Bool>("playSample", defaultValue: false)
    static let showKeyLabels = SettingKey<Bool>("showKeyLabels", defaultValue: false)
}

/**
 Manages window showing various runtime settings and options.
 */
class SettingsViewController: UIViewController {

    @IBOutlet private weak var restoreDefaultSoundFonts: UIButton!
    @IBOutlet private weak var removeDefaultSoundFonts: UIButton!
    @IBOutlet private weak var showSolfegeNotes: UISwitch!
    @IBOutlet private weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var playSample: UISwitch!
    @IBOutlet weak var showKeyLabels: UISwitch!

    var soundFonts: SoundFonts!

    override func viewWillAppear(_ animated: Bool) {
        precondition(soundFonts != nil, "nil soundFonts")
        super.viewWillAppear(animated)
        showSolfegeNotes.isOn = Settings[.showSolfegeLabel]
        playSample.isOn = Settings[.playSample]
        showKeyLabels.isOn = Settings[.showKeyLabels]
        updateButtonState()
    }

    private func updateButtonState() {
        restoreDefaultSoundFonts.isEnabled = !soundFonts.hasAllBundled
        removeDefaultSoundFonts.isEnabled = soundFonts.hasAnyBundled
    }

    @IBAction
    private func close(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @IBAction
    private func restoreDefaultSoundFonts(_ sender: Any) {
        soundFonts.restoreBundled()
        updateButtonState()
        postNotice(msg: "Restored entries to the built-in sound fonts.")
    }

    @IBAction
    private func removeDefaultSoundFonts(_ sender: Any) {
        soundFonts.removeBundled()
        updateButtonState()
        postNotice(msg: "Removed entries to the built-in sound fonts.")
    }

    @IBAction
    private func toggleShowSolfegeNotes(_ sender: Any) {
        Settings[.showSolfegeLabel] = self.showSolfegeNotes.isOn
    }

    @IBAction func togglePlaySample(_ sender: Any) {
        Settings[.playSample] = self.playSample.isOn
    }

    @IBAction func toggleShowKeyLabels(_ sender: Any) {
        Settings[.showKeyLabels] = self.showKeyLabels.isOn
        NotificationCenter.default.post(.showKeyLabelsChanged)
    }

    @IBAction func visitAppStore(_ sender: Any) {
        NotificationCenter.default.post(.visitAppStore)
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

        self.present(alertController, animated: true, completion: nil)
    }
}

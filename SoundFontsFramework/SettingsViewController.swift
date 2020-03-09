// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public extension SettingKeys {
    static let showSolfegeLabel = SettingKey<Bool>("showSolfegeLabel", defaultValue: true)
}

/**
 Manages window showing various runtime settings and options.
 */
class SettingsViewController: UIViewController {
    @IBOutlet private weak var restoreDefaultSoundFonts: UIButton!
    @IBOutlet private weak var removeDefaultSoundFonts: UIButton!
    @IBOutlet private weak var showSolfegeNotes: UISwitch!
    @IBOutlet private weak var doneButton: UIBarButtonItem!

    var soundFonts: SoundFonts!

    override func viewWillAppear(_ animated: Bool) {
        precondition(soundFonts != nil, "nil soundFonts")
        super.viewWillAppear(animated)
        showSolfegeNotes.isOn = Settings[.showSolfegeLabel]
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
    }

    @IBAction
    private func removeDefaultSoundFonts(_ sender: Any) {
        soundFonts.removeBundled()
        updateButtonState()
    }

    @IBAction
    private func toggleShowSolfegeNotes(_ sender: Any) {
        Settings[.showSolfegeLabel] = self.showSolfegeNotes.isOn
    }
}

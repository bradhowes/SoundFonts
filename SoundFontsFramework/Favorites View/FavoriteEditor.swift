// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Provides an editing facility for presets and favorites instances.
 */
final public class FavoriteEditor: UIViewController {

    public struct State {
        let indexPath: IndexPath
        let sourceView: UIView
        let sourceRect: CGRect
        let currentLowestNote: Note?
        let completionHandler: ((Bool) -> Void)?
        let soundFonts: SoundFonts
        let soundFontAndPatch: SoundFontAndPatch
    }

    public enum Config {
        case preset(state: State)
        case favorite(state: State, favorite: LegacyFavorite)

        var state: State {
            switch self {
            case .preset(let config): return config
            case .favorite(let config, _): return config
            }
        }

        var favorite: LegacyFavorite? {
            switch self {
            case .preset: return nil
            case .favorite(_, let favorite): return favorite
            }
        }

        var isFavorite: Bool {
            switch self {
            case .preset: return false
            case .favorite: return true
            }
        }
    }

    public enum Response {
        case preset(soundFontAndPatch: SoundFontAndPatch, config: PresetConfig)
        case favorite(config: PresetConfig)
    }

    private var config: Config!
    private var presetConfig = PresetConfig(name: "")
    private var position: IndexPath = IndexPath(row: -1, section: -1)
    private var currentLowestNote: Note?
    private var completionHandler: ((Bool) -> Void)?
    private var soundFonts: SoundFonts! = nil
    private var soundFontAndPatch: SoundFontAndPatch! = nil

    weak var delegate: FavoriteEditorDelegate?

    // override public var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    @IBOutlet private weak var cancelButton: UIBarButtonItem!
    @IBOutlet private weak var doneButton: UIBarButtonItem!

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var name: UITextField!
    @IBOutlet private weak var originalStack: UIStackView!
    @IBOutlet private weak var originalName: UILabel!
    @IBOutlet private weak var originalNameUse: UIButton!

    @IBOutlet private weak var forgetReverbSettingsButton: UIButton!
    @IBOutlet private weak var forgetDelaySettingsButton: UIButton!

    @IBOutlet private weak var lowestNoteCollection: UIStackView!
    @IBOutlet private weak var lowestNote: UIButton!
    @IBOutlet private weak var lowestNoteEnabled: UISwitch!
    @IBOutlet private weak var lowestNoteValue: UILabel!
    @IBOutlet private weak var lowestNoteStepper: UIStepper!

    @IBOutlet private weak var gainValue: UILabel!
    @IBOutlet private weak var gainSlider: UISlider!

    @IBOutlet private weak var panLeft: UILabel!
    @IBOutlet private weak var panSlider: UISlider!
    @IBOutlet private weak var panRight: UILabel!

    @IBOutlet private weak var soundFontName: UILabel!
    @IBOutlet private weak var bankIndex: UILabel!

    @IBOutlet private weak var presetTuningEnabled: UISwitch!
    @IBOutlet private weak var standardTuningButton: UIButton!
    @IBOutlet private weak var scientificTuningButton: UIButton!
    @IBOutlet private weak var presetTuningCents: UITextField!
    @IBOutlet private weak var presetTuningFrequency: UITextField!

    private var tuningComponent: TuningComponent!

    func configure(_ config: Config) {
        let state = config.state
        self.config = config
        self.position = state.indexPath
        self.currentLowestNote = state.currentLowestNote
        self.completionHandler = state.completionHandler
        self.soundFonts = state.soundFonts
        self.soundFontAndPatch = state.soundFontAndPatch
    }

    override public func viewDidLoad() {
        lowestNoteStepper.minimumValue = 0
        lowestNoteStepper.maximumValue = Double(Sampler.maxMidiValue)

        gainSlider.minimumValue = -90.0
        gainSlider.maximumValue = 12.0

        panSlider.minimumValue = -100.0
        panSlider.maximumValue = 100.0

        lowestNoteStepper.setDecrementImage(lowestNoteStepper.decrementImage(for: .normal), for: .normal)
        lowestNoteStepper.setIncrementImage(lowestNoteStepper.incrementImage(for: .normal), for: .normal)

        tuningComponent = TuningComponent(tuning: 0.0, view: view,
                                          scrollView: scrollView,
                                          tuningEnabledSwitch: presetTuningEnabled,
                                          standardTuningButton: standardTuningButton,
                                          scientificTuningButton: scientificTuningButton,
                                          tuningCents: presetTuningCents,
                                          tuningFrequency: presetTuningFrequency)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        precondition(config != nil && soundFonts != nil && soundFontAndPatch != nil)

        guard let soundFont = soundFonts.getBy(key: soundFontAndPatch.soundFontKey) else { fatalError() }
        let preset = soundFont.patches[soundFontAndPatch.patchIndex]
        let editingFavorite = config.favorite != nil

        presetConfig = config.favorite?.presetConfig ?? preset.presetConfig

        navigationItem.title = editingFavorite ? "Favorite" : "Preset"

        name.text = presetConfig.name
        name.delegate = self
        originalName.text = editingFavorite ? preset.presetConfig.name : preset.originalName

        if let currentLowestNote = presetConfig.keyboardLowestNote ?? self.currentLowestNote {
            lowestNoteCollection.isHidden = false
            lowestNoteValue.text = currentLowestNote.label
            lowestNoteStepper.value = Double(currentLowestNote.midiNoteValue)
            lowestNoteEnabled.isOn = self.presetConfig.keyboardLowestNoteEnabled
        }
        else {
            lowestNoteCollection.isHidden = true
        }

        tuningComponent.updateState(enabled: presetConfig.presetTuningEnabled, cents: presetConfig.presetTuning)

        let gain = presetConfig.gain
        gainSlider.value = gain
        volumeChanged(gainSlider)

        let pan = presetConfig.pan
        panSlider.value = pan
        panChanged(panSlider)

        soundFontName.text = soundFont.displayName
        bankIndex.text = "Bank: \(preset.bank) Index: \(preset.program)"
    }
}

// MARK: - UITextFieldDelegate

extension FavoriteEditor: UITextFieldDelegate {

    /**
     Configure name field so that pressing RETURN will exit the editor.

     - parameter textField: the name UITextField to work with
     - returns: false
     */
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        donePressed(doneButton)
        return false
    }
}

// MARK: - Private

extension FavoriteEditor {

    /**
     Event handler for the `Done` button. Updates the Favorite instance with new values from the editing view.
     
     - parameter sender: the `Done` button
     */
    @IBAction private func donePressed(_ sender: UIBarButtonItem) {
        guard let soundFont = soundFonts.getBy(key: soundFontAndPatch.soundFontKey) else { fatalError() }
        let preset = soundFont.patches[soundFontAndPatch.patchIndex]
        var presetConfig = config.favorite?.presetConfig ?? preset.presetConfig

        let newName = (self.name.text ?? "").trimmingCharacters(in: .whitespaces)
        if !newName.isEmpty {
            presetConfig.name = newName
        }

        let lowestNoteValue = Int(lowestNoteStepper.value)
        let lowestNote = Note(midiNoteValue: lowestNoteValue)
        presetConfig.keyboardLowestNote = lowestNote
        presetConfig.keyboardLowestNoteEnabled = lowestNoteEnabled.isOn

        presetConfig.gain = gainSlider.value
        presetConfig.pan = panSlider.value

        presetConfig.presetTuningEnabled = presetTuningEnabled.isOn
        presetConfig.presetTuning = tuningComponent.tuning

        let response: Response = self.config.isFavorite ?
            .favorite(config: presetConfig) : .preset(soundFontAndPatch: soundFontAndPatch, config: presetConfig)

        AskForReview.maybe()
        delegate?.dismissed(position, reason: .done(response: response))
        completionHandler?(true)
    }

    /**
     Event handler for the `Cancel` button. Does nothing but asks for the delegate to dismiss the view.
     
     - parameter sender: the `Cancel` button.
     */
    @IBAction private func cancelPressed(_ sender: UIBarButtonItem) {
        AskForReview.maybe()
        delegate?.dismissed(position, reason: .cancel)
        completionHandler?(false)
    }

    @IBAction private func useOriginalName(_ sender: UIButton) {
        name.text = originalName.text
    }

    /**
     Event handler for the lowest key stepper.
     
     - parameter sender: UIStepper control
     */
    @IBAction private func changeLowestKey(_ sender: UIStepper) {
        lowestNoteValue.text = Note(midiNoteValue: Int(sender.value)).label
    }

    /**
     Event handler for the volume slider
    
     - parameter sender: UISlider
     */
    @IBAction private func volumeChanged(_ sender: UISlider) {
        gainValue.text = "\(formatFloat(sender.value)) dB"
        presetConfig.gain = sender.value
        PresetConfig.changedNotification.post(value: presetConfig)
    }

    /**
     Event handler for the pan slider
     
     - parameter sender: UISlider
     */
    @IBAction private func panChanged(_ sender: UISlider) {
        let right = Int(round((sender.value + 100.0) / 200.0 * 100.0))
        let left = Int(100 - right)
        panLeft.text = "\(left)"
        panRight.text = "\(right)"
        presetConfig.pan = sender.value
        PresetConfig.changedNotification.post(value: presetConfig)
    }

    @IBAction private func useCurrentLowestNote(_ sender: Any) {
        guard let currentLowestNote = self.currentLowestNote else { return }
        lowestNoteValue.text = currentLowestNote.label
        lowestNoteStepper.value = Double(currentLowestNote.midiNoteValue)
    }

    /**
     Format a Float value so that it shows only two digits after the decimal point.

     - parameter value: the value to format
     - returns: formatted value
     */
    private func formatFloat(_ value: Float) -> String {
        String(format: "%+.1f", locale: Locale.current, arguments: [value])
    }
}

extension FavoriteEditor: UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate {

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        donePressed(doneButton)
    }

    /**
     Treat touches outside of the popover as a signal to dismiss via Dones button

     - parameter popoverPresentationController: the controller being monitored
     */
    public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        donePressed(doneButton)
    }
}

// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/// Provides an editing facility for presets and favorites instances.
final public class FavoriteEditor: UIViewController {

  public struct State {
    let indexPath: IndexPath
    let sourceView: UIView
    let sourceRect: CGRect
    let currentLowestNote: Note?
    let completionHandler: ((Bool) -> Void)?
    let soundFonts: SoundFonts
    let soundFontAndPreset: SoundFontAndPreset
  }

  public enum Config {
    case preset(state: State)
    case favorite(state: State, favorite: Favorite)

    var state: State {
      switch self {
      case .preset(let config): return config
      case .favorite(let config, _): return config
      }
    }

    var favorite: Favorite? {
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
    case preset(soundFontAndPreset: SoundFontAndPreset, config: PresetConfig)
    case favorite(config: PresetConfig)
  }

  private var config: Config!
  private var presetConfig = PresetConfig(name: "")
  private var position: IndexPath = IndexPath(row: -1, section: -1)
  private var currentLowestNote: Note?
  private var completionHandler: ((Bool) -> Void)?
  private var soundFonts: SoundFonts! = nil
  private var soundFontAndPreset: SoundFontAndPreset! = nil

  weak var delegate: FavoriteEditorDelegate?

  // override public var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

  @IBOutlet private weak var cancelButton: UIBarButtonItem!
  @IBOutlet private weak var doneButton: UIBarButtonItem!

  @IBOutlet private weak var scrollView: UIScrollView!
  @IBOutlet private weak var name: UITextField!
  @IBOutlet private weak var originalStack: UIStackView!
  @IBOutlet private weak var originalName: UILabel!
  @IBOutlet private weak var originalNameUse: UIButton!

  @IBOutlet private weak var gainResetButton: UIButton!
  @IBOutlet private weak var panResetButton: UIButton!

  @IBOutlet private weak var lowestNoteCollection: UIStackView!
  @IBOutlet private weak var lowestNote: UIButton!
  @IBOutlet private weak var lowestNoteEnabled: UISwitch!
  @IBOutlet private weak var lowestNoteValue: UILabel!
  @IBOutlet private weak var lowestNoteStepper: UIStepper!

  @IBOutlet private weak var pitchBendRange: UILabel!
  @IBOutlet private weak var pitchBendStepper: UIStepper!
  @IBOutlet private weak var gainValue: UILabel!
  @IBOutlet private weak var gainSlider: UISlider!

  @IBOutlet private weak var panLeft: UILabel!
  @IBOutlet private weak var panSlider: UISlider!
  @IBOutlet private weak var panRight: UILabel!

  @IBOutlet private weak var soundFontName: UILabel!
  @IBOutlet private weak var bankIndex: UILabel!
  @IBOutlet private weak var keyLabel: UILabel!

  @IBOutlet private weak var presetTuningEnabled: UISwitch!
  @IBOutlet private weak var standardTuningButton: UIButton!
  @IBOutlet private weak var scientificTuningButton: UIButton!
  @IBOutlet private weak var presetTuningCents: UITextField!
  @IBOutlet private weak var presetTuningFrequency: UITextField!

  @IBOutlet private weak var notesTextView: UITextView!

  private var tuningComponent: TuningComponent?

  func configure(_ config: Config) {
    let state = config.state
    self.config = config
    self.position = state.indexPath
    self.currentLowestNote = state.currentLowestNote
    self.completionHandler = state.completionHandler
    self.soundFonts = state.soundFonts
    self.soundFontAndPreset = state.soundFontAndPreset
  }

  override public func viewDidLoad() {
    name.delegate = self
    notesTextView.delegate = self

    lowestNoteStepper.minimumValue = 0
    lowestNoteStepper.maximumValue = Double(Sampler.maxMidiValue)

    gainSlider.minimumValue = -90.0  // db
    gainSlider.maximumValue = 12  // db

    panSlider.minimumValue = -100.0
    panSlider.maximumValue = 100.0

    lowestNoteStepper.setDecrementImage(
      lowestNoteStepper.decrementImage(for: .normal), for: .normal)
    lowestNoteStepper.setIncrementImage(
      lowestNoteStepper.incrementImage(for: .normal), for: .normal)

    pitchBendStepper.minimumValue = 1
    pitchBendStepper.maximumValue = 24
    pitchBendStepper.setDecrementImage(pitchBendStepper.decrementImage(for: .normal), for: .normal)
    pitchBendStepper.setIncrementImage(pitchBendStepper.incrementImage(for: .normal), for: .normal)
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    precondition(config != nil && soundFonts != nil && soundFontAndPreset != nil)

    guard let soundFont = soundFonts.getBy(key: soundFontAndPreset.soundFontKey) else {
      fatalError()
    }
    let preset = soundFont.presets[soundFontAndPreset.patchIndex]
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
    } else {
      lowestNoteCollection.isHidden = true
    }

    let tuningComponent = TuningComponent(
      tuning: 0.0, view: view,
      scrollView: scrollView,
      tuningEnabledSwitch: presetTuningEnabled,
      standardTuningButton: standardTuningButton,
      scientificTuningButton: scientificTuningButton,
      tuningCents: presetTuningCents,
      tuningFrequency: presetTuningFrequency)
    self.tuningComponent = tuningComponent
    tuningComponent.updateState(
      enabled: presetConfig.presetTuningEnabled, cents: presetConfig.presetTuning)

    setPitchBendRange(presetConfig.pitchBendRange ?? Settings.shared.pitchBendRange)
    setGainValue(presetConfig.gain)
    setPanValue(presetConfig.pan)

    soundFontName.text = soundFont.displayName
    bankIndex.text = "Bank: \(preset.bank) Index: \(preset.program)"
    keyLabel.text = config.favorite?.key.uuidString ?? config.state.soundFontAndPreset.soundFontKey.uuidString

    notesTextView.text = presetConfig.notes
  }
}

// MARK: - UITextFieldDelegate

extension FavoriteEditor: UITextFieldDelegate {

  public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    tuningComponent?.viewToKeepVisible = textField
    return true
  }
  /**
   Configure name field so that pressing RETURN will exit the editor.

   - parameter textField: the name UITextField to work with
   - returns: false
   */
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    save()
    return false
  }

  public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
    tuningComponent?.viewToKeepVisible = nil
    return true
  }
}

extension FavoriteEditor: UITextViewDelegate {

  public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    tuningComponent?.viewToKeepVisible = textView
    return true
  }

  public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
    tuningComponent?.viewToKeepVisible = nil
    return true
  }
}

// MARK: - Private

extension FavoriteEditor {

  /**
   Event handler for the `Done` button. Updates the Favorite instance with new values from the editing view.

   - parameter sender: the `Done` button
   */
  @IBAction private func donePressed(_ sender: UIBarButtonItem) { save() }

  /**
   Event handler for the `Cancel` button. Does nothing but asks for the delegate to dismiss the view.

   - parameter sender: the `Cancel` button.
   */
  @IBAction private func cancelPressed(_ sender: UIBarButtonItem) { discard() }

  @IBAction private func useOriginalName(_ sender: UIButton) { name.text = originalName.text }

  /**
   Event handler for the lowest key stepper.

   - parameter sender: UIStepper control
   */
  @IBAction private func changeLowestKey(_ sender: UIStepper) {
    lowestNoteValue.text = Note(midiNoteValue: Int(sender.value)).label
  }

  @IBAction func pitchBendStep(_ sender: UIStepper) { updatePitchBendRange() }

  @IBAction func resetPitchBend(_ sender: UIButton) {
    presetConfig.pitchBendRange = nil
    setPitchBendRange(Settings.shared.pitchBendRange)
  }

  /**
   Event handler for the gain slider

   - parameter sender: UISlider
   */
  @IBAction private func volumeChanged(_ sender: UISlider) { setGainValue(sender.value) }

  @IBAction private func resetGain(_ sender: UIButton) { setGainValue(0.0) }

  /**
   Event handler for the pan slider

   - parameter sender: UISlider
   */
  @IBAction private func panChanged(_ sender: UISlider) {
    setPanValue(sender.value)
  }

  @IBAction private func resetPan(_ sender: UIButton) {
    setPanValue(0.0)
  }

  @IBAction private func useCurrentLowestNote(_ sender: Any) {
    guard let currentLowestNote = self.currentLowestNote else { return }
    lowestNoteValue.text = currentLowestNote.label
    lowestNoteStepper.value = Double(currentLowestNote.midiNoteValue)
  }

  private func save() {
    guard
      let soundFont = soundFonts.getBy(key: soundFontAndPreset.soundFontKey),
      let tuningComponent = self.tuningComponent
    else {
      fatalError()
    }

    let preset = soundFont.presets[soundFontAndPreset.patchIndex]
    var presetConfig = config.favorite?.presetConfig ?? preset.presetConfig

    let newName = (self.name.text ?? "").trimmingCharacters(in: .whitespaces)
    if !newName.isEmpty {
      presetConfig.name = newName
    }

    let lowestNoteValue = Int(lowestNoteStepper.value)
    let lowestNote = Note(midiNoteValue: lowestNoteValue)
    presetConfig.keyboardLowestNote = lowestNote
    presetConfig.keyboardLowestNoteEnabled = lowestNoteEnabled.isOn

    presetConfig.pitchBendRange = self.presetConfig.pitchBendRange
    presetConfig.gain = self.presetConfig.gain
    presetConfig.pan = self.presetConfig.pan

    presetConfig.presetTuningEnabled = presetTuningEnabled.isOn
    presetConfig.presetTuning = tuningComponent.tuning
    presetConfig.notes = notesTextView.text

    let response: Response =
      self.config.isFavorite
      ? .favorite(config: presetConfig)
      : .preset(soundFontAndPreset: soundFontAndPreset, config: presetConfig)

    dismissed(reason: .done(response: response))
  }

  private func discard() { dismissed(reason: .cancel) }

  private func dismissed(reason: FavoriteEditorDismissedReason) {
    AskForReview.maybe()
    delegate?.dismissed(position, reason: reason)
    completionHandler?(false)
    self.tuningComponent = nil
  }

  private func updatePitchBendRange() {
    let value = Int(pitchBendStepper.value)
    pitchBendRange.text = "\(value)"
    presetConfig.pitchBendRange = value
    PresetConfig.changedNotification.post(value: presetConfig)
  }

  private func setPitchBendRange(_ value: Int) {
    pitchBendRange.text = "\(value)"
    pitchBendStepper.value = Double(value)
  }

  private func setGainValue(_ value: Float) {
    gainValue.text = "\(formatFloat(value)) dB"
    gainSlider.value = value
    presetConfig.gain = value
    PresetConfig.changedNotification.post(value: presetConfig)
  }

  private func setPanValue(_ value: Float) {
    let right = Int(round((value + 100.0) / 200.0 * 100.0))
    let left = Int(100 - right)
    panLeft.text = "\(left)"
    panRight.text = "\(right)"
    panSlider.value = value
    presetConfig.pan = value
    PresetConfig.changedNotification.post(value: presetConfig)
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

extension FavoriteEditor: UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate
{
  /**
   Notification that the presentation controller has been dismissed.

   - parameter presentationController: the controller that was dismissed
   */
  public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    discard()
  }

  /**
   Treat touches outside of the popover as a signal to dismiss via Done button

   - parameter popoverPresentationController: the controller being monitored
   */
  public func popoverPresentationControllerDidDismissPopover(
    _ popoverPresentationController: UIPopoverPresentationController) {
    discard()
  }
}

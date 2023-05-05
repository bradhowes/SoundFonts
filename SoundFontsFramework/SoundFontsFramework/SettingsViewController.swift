// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import MorkAndMIDI
import MessageUI
import UIKit
import os

enum KeyLabelOption: Int {
  case off
  case all
  case cOnly
}

/**
 Manages view showing various runtime settings and options that the user can modify.
 */
final class SettingsViewController: UIViewController {
  private lazy var log = Logging.logger("SettingsViewController")

  @IBOutlet private weak var scrollView: UIScrollView!
  @IBOutlet private weak var contentView: UIView!
  @IBOutlet private weak var upperBackground: UIView!
  @IBOutlet private weak var doneButton: UIBarButtonItem!

  @IBOutlet private weak var keyLabelsStackView: UIStackView!
  @IBOutlet private weak var solfegeStackView: UIStackView!
  @IBOutlet private weak var keyWidthStackView: UIStackView!
  @IBOutlet private weak var playSamplesStackView: UIStackView!
  @IBOutlet private weak var slideKeyboardStackView: UIStackView!

  @IBOutlet private weak var divider1: UIView!

  @IBOutlet private weak var midiChannelStackView: UIStackView!
  @IBOutlet private weak var midiConnectionsStackView: UIStackView!
  @IBOutlet private weak var midiAutoConnectStackView: UIStackView!
  @IBOutlet private weak var midiControllersStackView: UIStackView!
  @IBOutlet private weak var bluetoothMIDIConnectStackView: UIStackView!
  @IBOutlet private weak var backgroundMIDIProcessingModeStackView: UIStackView!
  @IBOutlet private weak var pitchBendStackView: UIStackView!

  @IBOutlet private weak var divider2: UIView!

  @IBOutlet private weak var tuningStackView: UIStackView!

  @IBOutlet private weak var copyFilesStackView: UIStackView!
  @IBOutlet private weak var removeSoundFontsStackView: UIStackView!
  @IBOutlet private weak var restoreSoundFontsStackView: UIStackView!

  @IBOutlet private weak var divider3: UIView!

  @IBOutlet private weak var exportSoundFontsStackView: UIStackView!
  @IBOutlet private weak var importSoundFontsStackView: UIStackView!
  @IBOutlet private weak var useSF2LibEngineStackView: UIStackView!

  @IBOutlet private weak var divider4: UIView!

  @IBOutlet private weak var showChangeHistoryStackView: UIStackView!
  @IBOutlet private weak var showTutorialStackView: UIStackView!
  @IBOutlet private weak var versionReviewStackView: UIStackView!
  @IBOutlet private weak var contactDeveloperStackView: UIStackView!

  @IBOutlet private weak var keyLabelOption: UISegmentedControl!
  @IBOutlet private weak var showSolfegeNotes: UISwitch!
  @IBOutlet private weak var playSample: UISwitch!
  @IBOutlet private weak var keyWidthSlider: UISlider!
  @IBOutlet private weak var slideKeyboard: UISwitch!
  @IBOutlet private weak var midiChannel: UILabel!
  @IBOutlet private weak var midiConnections: UIButton!
  @IBOutlet private weak var midiChannelStepper: UIStepper!
  @IBOutlet private weak var midiDeviceAutoConnectEnabled: UISwitch!
  @IBOutlet private weak var midiControllers: UIButton!

  @IBOutlet private weak var pitchBendRange: UILabel!
  @IBOutlet private weak var pitchBendStepper: UIStepper!
  @IBOutlet private weak var bluetoothMIDIConnect: UIButton!
  @IBOutlet private weak var backgroundMIDIProcessingMode: UISwitch!
  @IBOutlet private weak var copyFiles: UISwitch!

  @IBOutlet private weak var divider5: UIView!
  @IBOutlet private weak var shiftA4Value: UILabel!
  @IBOutlet private weak var shiftA4Stepper: UIStepper!
  @IBOutlet private weak var standardTuningButton: UIButton!
  @IBOutlet private weak var scientificTuningButton: UIButton!
  @IBOutlet private weak var globalTuningCents: UITextField!
  @IBOutlet private weak var globalTuningFrequency: UITextField!

  @IBOutlet private weak var removeDefaultSoundFonts: UIButton!
  @IBOutlet private weak var restoreDefaultSoundFonts: UIButton!
  @IBOutlet private weak var review: UIButton!
  @IBOutlet private weak var showChangeslButton: UIButton!
  @IBOutlet private weak var showTutorialButton: UIButton!
  @IBOutlet private weak var contactButton: UIButton!
  @IBOutlet private weak var useSF2LibEngine: UISwitch!

  private var revealKeyboardForKeyWidthChanges = false
  private let numberKeyboardDoneProxy = UITapGestureRecognizer()

  private weak var settings: Settings!
  private weak var soundFonts: SoundFontsProvider!
  private weak var infoBar: AnyInfoBar!
  private weak var midi: MIDI?
  private weak var midiConnectionMonitor: MIDIConnectionMonitor?
  private weak var midiRouter: MIDIEventRouter?
  private var isMainApp = true
  private var monitorToken: NotificationObserver?
  private var midiConnectionsObserver: NSKeyValueObservation!
  private var tuningComponent: TuningComponent?
  private var tuningObserver: NSKeyValueObservation!
  private lazy var hideForKeyWidthChange: [UIView] = [
    playSamplesStackView,
    copyFilesStackView,
    midiChannelStackView,
    midiConnectionsStackView,
    midiAutoConnectStackView,
    midiControllersStackView,
    slideKeyboardStackView,
    bluetoothMIDIConnectStackView,
    backgroundMIDIProcessingModeStackView,
    removeSoundFontsStackView,
    restoreSoundFontsStackView,
    exportSoundFontsStackView,
    importSoundFontsStackView,
    versionReviewStackView,
    showChangeHistoryStackView,
    showTutorialStackView,
    contactDeveloperStackView,
    pitchBendStackView,
    tuningStackView,
    useSF2LibEngineStackView,
    divider1,
    divider2,
    divider3,
    divider4,
    divider5
  ]

  // swiftlint:disable function_parameter_count
  func configure(isMainApp: Bool, soundFonts: SoundFontsProvider, settings: Settings,
                 midi: MIDI?, midiConnectionMonitor: MIDIConnectionMonitor?, infoBar: AnyInfoBar) {
    self.isMainApp = isMainApp
    self.soundFonts = soundFonts
    self.settings = settings
    self.midi = midi
    self.midiConnectionMonitor = midiConnectionMonitor
    self.infoBar = infoBar
  }
  // swiftlint:enable function_parameter_count

  override func viewDidLoad() {
    super.viewDidLoad()

    review.isEnabled = isMainApp
    keyLabelOption.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.lightGray], for: .normal)
    keyLabelOption.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)

    keyWidthSlider.maximumValue = 96.0
    keyWidthSlider.minimumValue = 32.0
    keyWidthSlider.isContinuous = true

    // iOS bug? Workaround to get the tint to affect the stepper button labels
    midiChannelStepper.setDecrementImage(midiChannelStepper.decrementImage(for: .normal), for: .normal)
    midiChannelStepper.setIncrementImage(midiChannelStepper.incrementImage(for: .normal), for: .normal)

    pitchBendStepper.setDecrementImage(pitchBendStepper.decrementImage(for: .normal), for: .normal)
    pitchBendStepper.setIncrementImage(pitchBendStepper.incrementImage(for: .normal), for: .normal)

    globalTuningCents.inputAssistantItem.leadingBarButtonGroups = []
    globalTuningFrequency.inputAssistantItem.trailingBarButtonGroups = []

#if NAME_SUFFIX
    useSF2LibEngineStackView.isHidden = true
#else
    useSF2LibEngineStackView.isHidden = false
#endif
  }

  override func viewWillAppear(_ animated: Bool) {
    precondition(soundFonts != nil, "nil soundFonts")
    precondition(settings != nil, "nil settings")

    super.viewWillAppear(animated)

    shiftA4Stepper.value = Double(settings.globalTranspose)

    makeTuningComponent()

    pitchBendStepper.value = Double(settings.pitchBendRange)
    updatePitchBendRange()

    if isMainApp {
      setupForMainApp()
    } else {
      setupForAU()
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    os_log(.debug, log: log, "viewDidDisapper BEGIN")
    super.viewDidDisappear(animated)
    guard let tuningComponent = self.tuningComponent else { fatalError("unexpected nil tuningComponent") }

    settings.globalTuning = tuningComponent.tuning
    settings.globalTranspose = Int(shiftA4Stepper.value)

    infoBar.updateTuningIndicator()

    self.tuningComponent = nil
    self.midiConnectionsObserver = nil
    monitorToken?.forget()
    monitorToken = nil

    os_log(.debug, log: log, "viewDidDisapper BEND")
  }

  @IBAction func useSF2EngineLibChanged(_ sender: UISwitch) {
    settings.useSF2Engine = sender.isOn
  }
}

private extension SettingsViewController {

  @IBAction func showChanges(_ sender: Any) {
    dismiss(animated: true)
    NotificationCenter.default.post(name: .showChanges, object: nil)
  }

  @IBAction func showTutorial(_ sender: Any) {
    dismiss(animated: true)
    NotificationCenter.default.post(name: .showTutorial, object: nil)
  }

  @IBAction func keyWidthEditingDidBegin(_ sender: Any) {
    os_log(.debug, log: log, "keyWidthEditingDidBegin")
    guard revealKeyboardForKeyWidthChanges else { return }
    UIViewPropertyAnimator.runningPropertyAnimator(
      withDuration: 0.3, delay: 0.0, options: [.allowUserInteraction],
      animations: self.beginShowKeyboard)
  }

  @IBAction func keyWidthEditingDidEnd(_ sender: Any) {
    os_log(.debug, log: log, "keyWidthEditingDidEnd")
    guard revealKeyboardForKeyWidthChanges else { return }
    UIViewPropertyAnimator.runningPropertyAnimator(
      withDuration: 0.3, delay: 0.0, options: [.allowUserInteraction],
      animations: self.endShowKeyboard)
  }

  @IBAction func close(_ sender: Any) {
    dismiss(animated: true)
  }

  @IBAction func visitAppStore(_ sender: Any) {
    NotificationCenter.default.post(Notification(name: .visitAppStore))
  }

  @IBAction func toggleShowSolfegeNotes(_ sender: Any) {
    settings.showSolfegeLabel = self.showSolfegeNotes.isOn
  }

  @IBAction func togglePlaySample(_ sender: Any) {
    settings.playSample = self.playSample.isOn
  }

  @IBAction func keyLabelOptionChanged(_ sender: Any) {
    settings.keyLabelOption = self.keyLabelOption.selectedSegmentIndex
  }

  @IBAction func toggleSlideKeyboard(_ sender: Any) {
    settings.slideKeyboard = self.slideKeyboard.isOn
  }

  @IBAction func midiChannelStep(_ sender: UIStepper) {
    updateMidiChannel()
  }

  @IBAction func toggleAutoConnectNewMIDIDeviceEnabled(_ sender: UISwitch) {
    settings.autoConnectNewMIDIDeviceEnabled = sender.isOn
  }

  @IBAction func toggleBackgroundMIDIProcessingEnabled(_ sender: Any) {
    if backgroundMIDIProcessingMode.isOn {
      showBackgroundMIDIProcessingNotice()
    } else {
      settings.backgroundMIDIProcessingEnabled = false
    }
  }

  @IBAction func pitchBendStep(_ sender: UIStepper) {
    updatePitchBendRange()
  }

  @IBAction func connectBluetoothMIDIDevices(_ sender: Any) {
    os_log(.debug, log: log, "connectBluetoothMIDIDevices")
    let vc = CABTMIDICentralViewController()
    self.navigationController?.pushViewController(vc, animated: true)
  }

  @IBAction func toggleCopyFiles(_ sender: Any) {
    if self.copyFiles.isOn == false {
      let ac = UIAlertController(
        title: "Disable Copying?",
        message: """
          Direct file access can lead to unusable SF2 file references if the file moves or is not immediately available on the
          device. Are you sure you want to disable copying?
          """, preferredStyle: .alert)
      ac.addAction(
        UIAlertAction(title: "Yes", style: .default) { _ in
          self.settings.copyFilesWhenAdding = false
        })
      ac.addAction(
        UIAlertAction(title: "Cancel", style: .cancel) { [weak self]_ in
          self?.copyFiles.isOn = true
        })
      present(ac, animated: true)
    } else {
      settings.copyFilesWhenAdding = true
    }
  }

  @IBAction func keyWidthChange(_ sender: Any) {
    let previousValue = settings.keyWidth.rounded()
    var newValue = keyWidthSlider.value.rounded()
    if abs(newValue - 64.0) < 4.0 { newValue = 64.0 }
    keyWidthSlider.value = newValue

    if newValue != previousValue {
      os_log(.debug, log: log, "new key width: %f", newValue)
      settings.keyWidth = newValue
    }
  }

  @IBAction func removeDefaultSoundFonts(_ sender: Any) {
    soundFonts.removeBundled()
    updateButtonState()
    postNotice(msg: "Removed entries to the built-in sound fonts.")
  }

  @IBAction func restoreDefaultSoundFonts(_ sender: Any) {
    soundFonts.restoreBundled()
    updateButtonState()
    postNotice(msg: "Restored entries to the built-in sound fonts.")
  }

  @IBAction func exportSoundFonts(_ sender: Any) {
    let (good, total) = soundFonts.exportToLocalDocumentsDirectory()
    switch total {
    case 0: postNotice(msg: "Nothing to export.")
    case 1: postNotice(msg: good == 1 ? "Exported \(good) file." : "Failed to export file.")
    default: postNotice(msg: "Exported \(good) out of \(total) files.")
    }
  }

  @IBAction func importSoundFonts(_ sender: Any) {
    let (good, total) = soundFonts.importFromLocalDocumentsDirectory()
    switch total {
    case 0: postNotice(msg: "Nothing to import.")
    case 1:
      postNotice(msg: good == 1 ? "Imported \(good) soundfont." : "Failed to import soundfont.")
    default: postNotice(msg: "Imported \(good) out of \(total) soundfonts.")
    }
  }

  @IBAction func sendEmail(_ sender: Any) {
    if MFMailComposeViewController.canSendMail() {
      let bundle = Bundle(for: Self.self)
      let mail = MFMailComposeViewController()
      mail.mailComposeDelegate = self
      mail.setToRecipients(["bradhowes@mac.com"])
      mail.setSubject("Note about your SoundFonts app")
      mail.setMessageBody(
        "<p>Regarding your SoundFonts app (\(bundle.versionString)):</p><p></p>", isHTML: true)
      present(mail, animated: true)
    } else {
      postNotice(msg: "Unable to send an email message from the app.")
    }
  }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {

  func mailComposeController(
    _ controller: MFMailComposeViewController,
    didFinishWith result: MFMailComposeResult, error: Error?
  ) {
    controller.dismiss(animated: true)
  }
}

extension SettingsViewController: SegueHandler {

  /// Segues that we support.
  enum SegueIdentifier: String {
    case midiConnectionsTableView
    case midiControllersTableView
    case midiActionsTableView
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segueIdentifier(for: segue) {
    case .midiConnectionsTableView:
      guard
        let midi = self.midi,
        let midiMonitor = self.midiConnectionMonitor,
        let destination = segue.destination as? MIDIConnectionsTableViewController
      else {
        fatalError("expected MIDIDevicesTableViewController for segue destination")
      }
      destination.configure(midi: midi, midiMonitor: midiMonitor, activeChannel: settings.midiChannel)

    case .midiControllersTableView:
      guard
        let midiEventRouter = self.midi?.receiver as? MIDIEventRouter,
        let destination = segue.destination as? MIDIControllersTableViewController
      else {
        fatalError("expected MIDIDevicesTableViewController for segue destination")
      }
      destination.configure(midiEventRouter: midiEventRouter)

    case .midiActionsTableView:
      guard
        let midiEventRouter = self.midi?.receiver as? MIDIEventRouter,
        let destination = segue.destination as? MIDIActionsTableViewController
      else {
        fatalError("expected MIDIActionsTableViewController for segue destination")
      }
      destination.configure(midiEventRouter: midiEventRouter)
    }
  }
}

private extension SettingsViewController {

  func setupForMainApp() {
    revealKeyboardForKeyWidthChanges = true
    if let popoverPresentationVC = self.parent?.popoverPresentationController {
      revealKeyboardForKeyWidthChanges = popoverPresentationVC.arrowDirection == .unknown
    }

    playSample.isOn = settings.playSample
    showSolfegeNotes.isOn = settings.showSolfegeLabel
    keyLabelOption.selectedSegmentIndex = settings.keyLabelOption
    updateButtonState()

    keyWidthSlider.value = settings.keyWidth
    slideKeyboard.isOn = settings.slideKeyboard

    updateMIDIConnectionsButton()
    midiConnectionsObserver = midi?.observe(\.activeConnections) { [weak self] _, _ in
      DispatchQueue.main.async { [weak self] in self?.updateMIDIConnectionsButton() }
    }

    monitorToken = midiConnectionMonitor?.addConnectionActivityMonitor { data in
      let ourChannel = self.settings.midiChannel
      let accepted = ourChannel == -1 || ourChannel == data.channel
      MIDIConnectionsTableViewController.midiSeenLayerChange(self.midiConnections.layer, accepted)
    }

    midiChannelStepper.value = Double(settings.midiChannel)
    updateMidiChannel()
    backgroundMIDIProcessingMode.isOn = settings.backgroundMIDIProcessingEnabled
    midiDeviceAutoConnectEnabled.isOn = settings.autoConnectNewMIDIDeviceEnabled

    slideKeyboard.isOn = settings.slideKeyboard

    copyFiles.isOn = settings.copyFilesWhenAdding

    endShowKeyboard()

    useSF2LibEngine.isOn = settings.useSF2Engine
  }

  func setupForAU() {
    keyLabelsStackView.isHidden = true
    solfegeStackView.isHidden = true
    keyWidthStackView.isHidden = true
    playSamplesStackView.isHidden = true
    slideKeyboardStackView.isHidden = true

    midiChannelStackView.isHidden = true
    midiConnectionsStackView.isHidden = true
    midiAutoConnectStackView.isHidden = true
    bluetoothMIDIConnectStackView.isHidden = true
    backgroundMIDIProcessingModeStackView.isHidden = true

    divider2.isHidden = true
    divider3.isHidden = true
    divider4.isHidden = true

    copyFilesStackView.isHidden = true
    removeSoundFontsStackView.isHidden = true
    restoreSoundFontsStackView.isHidden = true

    exportSoundFontsStackView.isHidden = true
    importSoundFontsStackView.isHidden = true
    showTutorialStackView.isHidden = true
    showChangeHistoryStackView.isHidden = true

    // Cannot write review from AUv3
    review.isEnabled = false
  }

  func makeTuningComponent() {
    let tuningComponent = TuningComponent(
      tuning: settings.globalTuning,
      view: view, scrollView: scrollView,
      shiftA4Value: shiftA4Value,
      shiftA4Stepper: shiftA4Stepper,
      standardTuningButton: standardTuningButton,
      scientificTuningButton: scientificTuningButton,
      tuningCents: globalTuningCents,
      tuningFrequency: globalTuningFrequency,
      isActive: true
    )

    self.tuningComponent = tuningComponent
  }

  func beginShowKeyboard() {
    for view in hideForKeyWidthChange {
      view.isHidden = true
    }
    view.backgroundColor = contentView.backgroundColor?.withAlphaComponent(0.2)
    contentView.backgroundColor = contentView.backgroundColor?.withAlphaComponent(0.0)
  }

  func endShowKeyboard() {
    let isAUv3 = !isMainApp
    for view in hideForKeyWidthChange {
      view.isHidden = false
    }

    midiChannelStackView.isHidden = isAUv3
    midiConnectionsStackView.isHidden = isAUv3
    midiAutoConnectStackView.isHidden = isAUv3

    slideKeyboardStackView.isHidden = isAUv3
    bluetoothMIDIConnectStackView.isHidden = isAUv3
    divider1.isHidden = isAUv3
    divider5.isHidden = isAUv3

    view.backgroundColor = contentView.backgroundColor?.withAlphaComponent(1.0)
    contentView.backgroundColor = contentView.backgroundColor?.withAlphaComponent(1.0)
  }

  private func updateMidiChannel() {
    let value = Int(midiChannelStepper.value)
    os_log(.debug, log: log, "new MIDI channel %d", value)
    midiChannel.text = value == -1 ? "Any" : "\(value + 1)"
    settings.midiChannel = value
  }

  private func updatePitchBendRange() {
    let value = UInt8(pitchBendStepper.value)
    os_log(.debug, log: log, "new pitch-bend range %d", value)
    pitchBendRange.text = "\(value)"
    settings.pitchBendRange = Int(value)
    AudioEngine.pitchBendRangeChangedNotification.post(value: value)
  }

  private func postNotice(msg: String) {
    let alertController = UIAlertController(
      title: "SoundFonts",
      message: msg,
      preferredStyle: .alert)
    let cancel = UIAlertAction(title: "OK", style: .cancel) { _ in }
    alertController.addAction(cancel)

    if let popoverController = alertController.popoverPresentationController {
      popoverController.sourceView = self.view
      popoverController.sourceRect = CGRect(
        x: self.view.bounds.midX, y: self.view.bounds.midY,
        width: 0, height: 0)
      popoverController.permittedArrowDirections = []
    }

    present(alertController, animated: true, completion: nil)
  }

  private func updateButtonState() {
    restoreDefaultSoundFonts.isEnabled = !soundFonts.hasAllBundled
    removeDefaultSoundFonts.isEnabled = soundFonts.hasAnyBundled
  }

  private func updateMIDIConnectionsButton() {
    guard let midi = self.midi else { return }
    let count = midi.activeConnections.count
    let suffix = count == 1 ? "connection" : "connections"
    midiConnections.setTitle("\(count) \(suffix)", for: .normal)
  }

  private func showBackgroundMIDIProcessingNotice() {
    let ac = UIAlertController(
      title: "Enable Background MIDI Processing",
      message: """
          Background MIDI processing allows the synthesizer to generate sounds even when the app is not active. However,
          doing so will increase power consumption and increase the rate of battery drain.
          Are you sure you want to enable it?
          """, preferredStyle: .alert)
    ac.addAction(
      UIAlertAction(title: "Yes", style: .default) { _ in
        self.settings.backgroundMIDIProcessingEnabled = true
      })
    ac.addAction(
      UIAlertAction(title: "Cancel", style: .cancel) { _ in
        self.backgroundMIDIProcessingMode.isOn = false
      })
    present(ac, animated: true)
  }
}

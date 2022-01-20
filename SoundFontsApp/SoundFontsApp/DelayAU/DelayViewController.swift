// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

public final class DelayViewController: AUViewController, Tasking {
  private lazy var log = Logging.logger("DelayViewController")
  private var audioUnit: DelayAU?
  private var parameterObserverToken: AUParameterObserverToken?

  @IBOutlet weak var time: Knob!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var feedback: Knob!
  @IBOutlet weak var feedbackLabel: UILabel!
  @IBOutlet weak var cutoff: Knob!
  @IBOutlet weak var cutoffLabel: UILabel!
  @IBOutlet weak var wetDryMix: Knob!
  @IBOutlet weak var wetDryMixLabel: UILabel!

  public override func viewDidLoad() {
    os_log(.debug, log: log, "viewDidLoad")
    super.viewDidLoad()
    if audioUnit != nil && parameterObserverToken == nil { connectAU() }

    time.minimumValue = 0
    time.maximumValue = 2

    feedback.minimumValue = -100.0
    feedback.maximumValue = 100.0

    cutoff.minimumValue = log10(10.0)
    cutoff.maximumValue = log10(20_000.0)

    wetDryMix.minimumValue = 0
    wetDryMix.maximumValue = 100
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if audioUnit != nil && parameterObserverToken == nil { connectAU() }
  }

  @IBAction func changeTime(_ sender: Any) { setTime(value: time.value) }
  @IBAction func changeFeedback(_ sender: Any) { setFeedback(value: feedback.value) }
  @IBAction func changeCutoff(_ sender: Any) { setCutoff(value: pow(10.0, cutoff.value)) }
  @IBAction func changeWebDryMix(_ sender: Any) { setWetDryMix(value: wetDryMix.value) }
}

extension DelayViewController: AUAudioUnitFactory {

  public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
    let audioUnit = try DelayAU(componentDescription: componentDescription)
    os_log(.debug, log: log, "created DelayAU")
    self.audioUnit = audioUnit
    return audioUnit
  }
}

extension DelayViewController {

  private func connectAU() {

    guard let audioUnit = audioUnit else { fatalError("nil audioUnit") }
    guard let parameterTree = audioUnit.parameterTree else { fatalError("nil parameterTree") }

    guard let time = parameterTree.parameter(withAddress: .time) else {
      fatalError("Undefined time parameter")
    }
    guard let feedback = parameterTree.parameter(withAddress: .feedback) else {
      fatalError("Undefined feedback parameter")
    }
    guard let cutoff = parameterTree.parameter(withAddress: .cutoff) else {
      fatalError("Undefined cutoff parameter")
    }
    guard let wetDryMix = parameterTree.parameter(withAddress: .wetDryMix) else {
      fatalError("Undefined wetDryMix parameter")
    }

    setTime(value: time.value)
    setFeedback(value: feedback.value)
    setCutoff(value: cutoff.value)
    setWetDryMix(value: wetDryMix.value)

    parameterObserverToken = parameterTree.token(byAddingParameterObserver: { [weak self] address, value in
      guard let self = self else { return }
      os_log(.error, log: self.log, "parameterObserver - address: %ld value: %f")
      switch AudioUnitParameters.Address(rawValue: address) {
      case .time: Self.onMain { self.setTime(value: value) }
      case .feedback: Self.onMain { self.setFeedback(value: value) }
      case .cutoff: Self.onMain { self.setCutoff(value: value) }
      case .wetDryMix: Self.onMain { self.setWetDryMix(value: value) }
      default: break
      }
    })
  }

  private func setParameter(_ address: AudioUnitParameters.Address, _ value: AUValue) {
    guard let audioUnit = audioUnit else { return }
    guard let parameterTree = audioUnit.parameterTree else { return }
    guard let parameter = parameterTree.parameter(withAddress: address.rawValue) else { return }
    parameter.setValue(value, originator: parameterObserverToken)
  }

  private func setTime(value: AUValue) {
    time.value = min(max(value, 0.0), 2.0)
    timeLabel.showStatus(String(format: "%.2f", value) + "s")
    setParameter(.time, value)
  }

  private func setFeedback(value: AUValue) {
    feedback.value = min(max(value, -100.0), 100.0)
    feedbackLabel.showStatus(String(format: "%.0f", value) + "%")
    setParameter(.feedback, value)
  }

  private func setCutoff(value: AUValue) {
    cutoff.value = log10(min(max(value, 10.0), 20_000.0))
    if value < 1000.0 {
      cutoffLabel.showStatus(String(format: "%.1f", value) + " Hz")
    } else {
      cutoffLabel.showStatus(String(format: "%.2f", value / 1000.0) + " kHz")
    }
    setParameter(.cutoff, value)
  }

  private func setWetDryMix(value: AUValue) {
    wetDryMix.value = min(max(value, 0.0), 100.0)
    wetDryMixLabel.showStatus(String(format: "%.0f", value) + "%")
    setParameter(.wetDryMix, value)
  }
}

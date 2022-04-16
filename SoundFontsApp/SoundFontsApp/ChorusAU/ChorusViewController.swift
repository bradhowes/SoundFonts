// Copyright © 2022 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

public final class ChorusViewController: AUViewController, Tasking {
  private lazy var log = Logging.logger("ChorusViewController")
  private var audioUnit: ChorusAU?
  private var parameterObserverToken: AUParameterObserverToken?

  @IBOutlet weak var rate: Knob!
  @IBOutlet weak var rateLabel: UILabel!
  @IBOutlet weak var depth: Knob!
  @IBOutlet weak var depthLabel: UILabel!
  @IBOutlet weak var delay: Knob!
  @IBOutlet weak var delayLabel: UILabel!
  @IBOutlet weak var wetDryMix: Knob!
  @IBOutlet weak var wetDryMixLabel: UILabel!

  public override func viewDidLoad() {
    os_log(.debug, log: log, "viewDidLoad")
    super.viewDidLoad()
    if audioUnit != nil && parameterObserverToken == nil { connectAU() }

    rate.minimumValue = 0.01
    rate.maximumValue = 20

    delay.minimumValue = 0.0
    delay.maximumValue = 50.0

    depth.minimumValue = 0.0
    depth.maximumValue = 100.0

    wetDryMix.minimumValue = 0.0
    wetDryMix.maximumValue = 100.0
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if audioUnit != nil && parameterObserverToken == nil { connectAU() }
  }

  @IBAction func changeRate(_ sender: Any) { setRate(value: rate.value) }
  @IBAction func changeDelay(_ sender: Any) { setDelay(value: delay.value) }
  @IBAction func changeDepth(_ sender: Any) { setDepth(value: depth.value) }
  @IBAction func changeWebDryMix(_ sender: Any) { setWetDryMix(value: wetDryMix.value) }
}

extension ChorusViewController: AUAudioUnitFactory {

  public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
    let audioUnit = try ChorusAU(componentDescription: componentDescription)
    os_log(.debug, log: log, "created ChorusAU")
    self.audioUnit = audioUnit
    return audioUnit
  }
}

extension ChorusViewController {

  private func connectAU() {

    guard let audioUnit = audioUnit else { fatalError("nil audioUnit") }
    guard let parameterTree = audioUnit.parameterTree else { fatalError("nil parameterTree") }
    guard let rate = parameterTree.parameter(withAddress: .rate) else { fatalError("Undefined rate parameter") }
    guard let delay = parameterTree.parameter(withAddress: .delay) else { fatalError("Undefined delay parameter") }
    guard let depth = parameterTree.parameter(withAddress: .depth) else { fatalError("Undefined depth parameter") }
    guard let wetDryMix = parameterTree.parameter(withAddress: .wetDryMix) else {
      fatalError("Undefined wetDryMix parameter")
    }

    setRate(value: rate.value)
    setDelay(value: delay.value)
    setDepth(value: depth.value)
    setWetDryMix(value: wetDryMix.value)

    parameterObserverToken = parameterTree.token(byAddingParameterObserver: { [weak self] address, value in
      guard let self = self else { return }
      os_log(.error, log: self.log, "parameterObserver - address: %ld value: %f")
      switch AudioUnitParameters.Address(rawValue: address) {
      case .rate: Self.onMain { self.setRate(value: value) }
      case .delay: Self.onMain { self.setDelay(value: value) }
      case .depth: Self.onMain { self.setDepth(value: value) }
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

  private func setRate(value: AUValue) {
    rate.value = min(max(value, 0.0), 2.0)
    rateLabel.showStatus(String(format: "%.2f", value) + " Hz")
    setParameter(.rate, value)
  }

  private func setDelay(value: AUValue) {
    delay.value = min(max(value, -100.0), 100.0)
    delayLabel.showStatus(String(format: "%.0f", value) + "ms")
    setParameter(.delay, value)
  }

  private func setDepth(value: AUValue) {
    depth.value = min(max(value, 0.0), 100.0)
    depthLabel.showStatus(String(format: "%.0f", value) + "%")
    setParameter(.depth, value)
  }

  private func setWetDryMix(value: AUValue) {
    wetDryMix.value = min(max(value, 0.0), 100.0)
    wetDryMixLabel.showStatus(String(format: "%.0f", value) + "%")
    setParameter(.wetDryMix, value)
  }
}

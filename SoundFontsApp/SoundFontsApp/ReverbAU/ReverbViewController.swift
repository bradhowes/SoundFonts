// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

public final class ReverbViewController: AUViewController {
  private let log = Logging.logger("ReverbViewController")
  private var audioUnit: ReverbAU?
  private var parameterObserverToken: AUParameterObserverToken?

  @IBOutlet private weak var wetDryMix: Knob!
  @IBOutlet private weak var wetDryMixLabel: UILabel!
  @IBOutlet private weak var room: UIPickerView!

  public override func viewDidLoad() {
    os_log(.info, log: log, "viewDidLoad")
    super.viewDidLoad()

    wetDryMix.minimumValue = 0
    wetDryMix.maximumValue = 100

    room.dataSource = self
    room.delegate = self
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if audioUnit != nil && parameterObserverToken == nil { connectAU() }
  }

  @IBAction func changeWetDryMix(_ sender: Any) { setWetDryMix(value: wetDryMix.value) }
}

extension ReverbViewController: AUAudioUnitFactory {

  public func createAudioUnit(with componentDescription: AudioComponentDescription) throws
    -> AUAudioUnit
  {
    let audioUnit = try ReverbAU(componentDescription: componentDescription)
    os_log(.info, log: log, "created ReverbAU")
    self.audioUnit = audioUnit
    return audioUnit
  }
}

extension ReverbViewController: UIPickerViewDataSource {
  public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
  public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
  {
    ReverbEffect.roomNames.count
  }
}

extension ReverbViewController: UIPickerViewDelegate {

  public func pickerView(
    _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int
  ) {
    os_log(.info, log: log, "new reverb room: %d", ReverbEffect.roomPresets[row].rawValue)
    setParameter(.roomPreset, AUValue(row))
  }

  public func pickerView(
    _ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int,
    reusing view: UIView?
  ) -> UIView {
    var pickerLabel: UILabel? = (view as? UILabel)
    if pickerLabel == nil {
      pickerLabel = UILabel()
      pickerLabel?.font = UIFont(name: "Eurostile", size: 17.0)
      pickerLabel?.textAlignment = .center
    }

    let attributes = [NSAttributedString.Key.foregroundColor: UIColor.systemTeal]
    pickerLabel?.attributedText = NSAttributedString(
      string: ReverbEffect.roomNames[row], attributes: attributes)

    return pickerLabel!
  }
}

extension ReverbViewController {

  private func connectAU() {

    guard let audioUnit = audioUnit else { fatalError("nil audioUnit") }
    guard let parameterTree = audioUnit.parameterTree else { fatalError("nil parameterTree") }

    guard let roomPreset = parameterTree.parameter(withAddress: .roomPreset) else {
      fatalError("Undefined roomPreset parameter")
    }
    guard let wetDryMix = parameterTree.parameter(withAddress: .wetDryMix) else {
      fatalError("Undefined wetDryMix parameter")
    }

    setActiveRoom(value: roomPreset.value)
    setWetDryMix(value: wetDryMix.value)

    parameterObserverToken = parameterTree.token(byAddingParameterObserver: {
      [weak self] address, value in
      guard let self = self else { return }
      switch AudioUnitParameters.Address(rawValue: address) {
      case .roomPreset: DispatchQueue.main.async { self.setActiveRoom(value: value) }
      case .wetDryMix: DispatchQueue.main.async { self.setWetDryMix(value: value) }
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

  private func setActiveRoom(value: AUValue) {
    let index = min(max(Int(value), 0), ReverbEffect.roomPresets.count - 1)
    room.selectRow(index, inComponent: 0, animated: true)
    setParameter(.roomPreset, AUValue(index))
  }

  private func setWetDryMix(value: AUValue) {
    wetDryMix.value = min(max(value, 0.0), 100.0)
    setParameter(.wetDryMix, value)
    wetDryMixLabel.showStatus(String(format: "%.0f", value) + "%")
  }
}

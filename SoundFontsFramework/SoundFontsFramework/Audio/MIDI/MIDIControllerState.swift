// Copyright © 2020 Brad Howes. All rights reserved.

import os

final public class MIDIControllerState {

  let identifier: UInt8
  let name: String
  var lastValue: UInt8?
  var allowed: Bool
  var action: MIDIControllerAction?

  public init(identifier: UInt8, allowed: Bool, action: MIDIControllerAction?) {
    self.identifier = identifier
    self.name = MIDICC(rawValue: identifier)?.name ?? ""
    self.lastValue = nil
    self.allowed = allowed
    if identifier == 112 {
      self.action = .nextPrevFavorite
    } else if identifier == 74 {
      self.action = .selectFavorite
    } else {
      self.action = action
    }
  }
}

public enum MIDICC: UInt8 {
  case bankSelect = 0
  case modulationWheel = 1
  case breathController = 2
  case footPedal = 4
  case portamentoTime = 5
  case volume = 7
  case balance = 8
  case pan = 10
  case expression = 11
  case effectController1 = 12
  case effectController2 = 13
  case damperPedal = 64
  case portamentoSwitch = 65
  case sostenutoPedal = 66
  case softPedal = 67
  case legatoSwitch = 68
  case hold2 = 69
  case soundController1 = 70
  case soundController2 = 71
  case soundController3 = 72
  case soundController4 = 73
  case soundController5 = 74
  case soundController6 = 75
  case soundController7 = 76
  case soundController8 = 77
  case soundController9 = 78
  case soundController10 = 79
  case portamentoAmount = 84
  case effect1 = 91
  case effect2 = 92
  case effect3 = 93
  case effect4 = 94
  case effect5 = 95
  case allSoundOff = 120
  case resetAllControllers = 121
  case localOnOff = 122
  case allNotesOff = 123
  case omniModeOff = 124
  case omniModeOn = 125
  case monoMode = 126
  case polyMode = 127

  var name: String {
    switch self {
    case .bankSelect: return "Bank Select"
    case .modulationWheel: return "Modulation Wheel"
    case .breathController: return "Breath Controller"
    case .footPedal: return "Foot Pedal"
    case .portamentoTime: return "Portamento Time"
    case .volume: return "Volume"
    case .balance: return "Balance"
    case .pan: return "Pan"
    case .expression: return "Expression"
    case .effectController1: return "Effect Controller 1"
    case .effectController2: return "Effect Controller 2"
    case .damperPedal: return "Damper Pedal"
    case .portamentoSwitch: return "Portamento Switch"
    case .sostenutoPedal: return "Sostenuto Pedal"
    case .softPedal: return "Soft Pedal"
    case .legatoSwitch: return "Legato Switch"
    case .hold2: return "Hold 2"
    case .soundController1: return "Sound Controller 1"
    case .soundController2: return "Sound Controller 2"
    case .soundController3: return "Sound Controller 3"
    case .soundController4: return "Sound Controller 4"
    case .soundController5: return "Sound Controller 5"
    case .soundController6: return "Sound Controller 6"
    case .soundController7: return "Sound Controller 7"
    case .soundController8: return "Sound Controller 8"
    case .soundController9: return "Sound Controller 9"
    case .soundController10: return "Sound Controller 10"
    case .portamentoAmount: return "Portamento Amount"
    case .effect1: return "Effect 1 Depth"
    case .effect2: return "Effect 2 Depth"
    case .effect3: return "Effect 3 Depth"
    case .effect4: return "Effect 4 Depth"
    case .effect5: return "Effect 5 Depth"
    case .allSoundOff: return "All Sound Off"
    case .resetAllControllers: return "Reset All Controllers"
    case .localOnOff: return "Local On/Off"
    case .allNotesOff: return "All Notes Off"
    case .omniModeOff: return "Omni Mode Off"
    case .omniModeOn: return "Omni Mode On"
    case .monoMode: return "Mono Mode"
    case .polyMode: return "Poly Mode"
    }
  }
}

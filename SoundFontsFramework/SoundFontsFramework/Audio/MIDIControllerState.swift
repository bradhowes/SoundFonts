// Copyright © 2020 Brad Howes. All rights reserved.

import os

struct MIDIControllerState {
  let identifier: UInt8
  let name: String
  var lastValue: Int
  var allowed: Bool

  init(identifier: UInt8, allowed: Bool) {
    self.identifier = identifier
    self.name = MIDICC(rawValue: identifier)?.name ?? ""
    self.lastValue = -1
    self.allowed = allowed
  }
}

enum MIDICC: UInt8 {
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
    }
  }
}

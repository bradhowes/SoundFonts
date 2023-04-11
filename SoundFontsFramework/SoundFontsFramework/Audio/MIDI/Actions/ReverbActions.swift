// Copyright © 2023 Brad Howes. All rights reserved.

import AVFoundation

final class  ReverbEffectActions {
  private let effect: ReverbEffect
  private var notificationObserver: NotificationObserver?

  init(effect: ReverbEffect) {
    self.effect = effect
    notificationObserver = MIDIEventRouter.monitorActionActivity { self.handleAction(payload: $0) }
  }

  private func handleAction(payload: MIDIEventRouter.ActionActivityPayload) {
    switch payload.action {
    case .reverbToggle: toggleEnabled(value: payload.value)
    case .reverbMix: setWetDryMix(value: payload.value, kind: payload.kind)
    case .reverbRoom: setRoom(value: payload.value, kind: payload.kind)
    default:
      break
    }
  }

  private func toggleEnabled(value: UInt8) {
    if value > 64 {
      effect.active = effect.active.setEnabled(!effect.active.enabled)
    }
  }

  private func setWetDryMix(value: UInt8, kind: MIDIControllerActionKind) {
    switch kind {
    case .absolute:
      effect.active = effect.active.setWetDryMix(AUValue(value) / 127.0 * 100.0)
    case .relative:
      effect.active = effect.active.setWetDryMix(clamp(value: AUValue(value) - 64.0 + effect.active.wetDryMix,
                                                       minimum: 0,
                                                       maximum: 100))
    case .onOff:
      break
    }
  }

  private func setRoom(value: UInt8, kind: MIDIControllerActionKind) {
    switch kind {
    case .absolute:
      let preset: Int = Int((AUValue(value) / 127.0 * AUValue(ReverbEffect.roomNames.count - 1)).rounded())
      effect.active = effect.active.setPreset(preset)
    case .relative:
      let preset: Int = clamp(value: effect.active.preset + (Int(value) - 64),
                              minimum: 0,
                              maximum: ReverbEffect.roomNames.count - 1)
      effect.active = effect.active.setPreset(preset)
    case .onOff:
      break
    }
  }
}

private func clamp<T: Comparable>(value: T, minimum: T, maximum: T) -> T {
  min(max(value, minimum), maximum)
}

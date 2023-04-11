// Copyright © 2023 Brad Howes. All rights reserved.

import AVFoundation

final class  DelayEffectActions {

  let minimumCutoffValue: AUValue = log10f(10.0)
  let maximumCutoffValue: AUValue = log10f(20_000.0)

  private let effect: DelayEffect
  private var notificationObserver: NotificationObserver?

  init(effect: DelayEffect) {
    self.effect = effect
    notificationObserver = MIDIEventRouter.monitorActionActivity { self.handleAction(payload: $0) }
  }

  private func handleAction(payload: MIDIEventRouter.ActionActivityPayload) {
    switch payload.action {
    case .delayToggle: toggleEnabled(value: payload.value)
    case .delayMix: setWetDryMix(value: payload.value, kind: payload.kind)
    case .delayTime: setTime(value: payload.value, kind: payload.kind)
    case .delayFeedback: setFeedback(value: payload.value, kind: payload.kind)
    case .delayCutoff: setCutoff(value: payload.value, kind: payload.kind)
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

  private func setTime(value: UInt8, kind: MIDIControllerActionKind) {
    switch kind {
    case .absolute: effect.active = effect.active.setTime(AUValue(value) / 127.0 * 2.0)
    case .relative:
      let value = clamp(value: effect.active.time + (AUValue(value) - 64.0) * 0.1,
                        minimum: 0,
                        maximum: 2.0)
      effect.active = effect.active.setTime(value)
    case .onOff:
      break
    }
  }

  private func setFeedback(value: UInt8, kind: MIDIControllerActionKind) {
    switch kind {
    case .absolute: effect.active = effect.active.setFeedback(AUValue(value) / 127.0 * 200.0 - 100.0)
    case .relative:
      let value = clamp(value: effect.active.feedback + (AUValue(value) - 64.0),
                        minimum: -100.0,
                        maximum: 100.0)
      effect.active = effect.active.setFeedback(value)
    case .onOff:
      break
    }
  }

  private func setCutoff(value: UInt8, kind: MIDIControllerActionKind) {
    switch kind {
    case .absolute:
      let logValue: AUValue = AUValue(value) / 127.0 * (maximumCutoffValue - minimumCutoffValue) + minimumCutoffValue
      effect.active = effect.active.setCutoff(cutoffValue(logValue))
    case .relative:
      let logValue = clamp(value: log10f(effect.active.cutoff) + (AUValue(value) - 64.0),
                           minimum: minimumCutoffValue,
                           maximum: maximumCutoffValue)
      effect.active = effect.active.setCutoff(cutoffValue(logValue))
    case .onOff:
      break
    }
  }

  private func cutoffValue(_ logValue: AUValue) -> AUValue { pow(10.0, logValue) }
}

private func clamp<T: Comparable>(value: T, minimum: T, maximum: T) -> T {
  min(max(value, minimum), maximum)
}

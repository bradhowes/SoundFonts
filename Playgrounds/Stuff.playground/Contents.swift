import AVFoundation
import Foundation

let taps = 7
let scale: AUValue = 0.8

func lfoRateCalculator(base: AUValue, scale: AUValue, index: Int) -> AUValue {
  return base * scale * AUValue(index)
}

let rates = (0..<taps).map { lfoRateCalculator(base: 100, scale: scale, index: $0) }
rates

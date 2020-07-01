import UIKit

func centsToDuration(_ cents: Int) -> Float {
    pow(2.0, Float(cents) / 1200.0)
}

func durationToCents(_ duration: Float) -> Int {
    Int((1200 * log2(duration)).rounded())
}

durationToCents(0.01)
centsToDuration(-7973)

func frequencyToCents(_ frequency: Float) -> Int {
    Int((1200 * log2(frequency / 8.176)).rounded())
}

func centsToFrequency(_ cents: Int) -> Float {
    pow(2.0, Float(cents) / 1200.0) * 8.176
}

frequencyToCents(20)
centsToFrequency(6900)

func percentToTenths(_ pct: Float) -> Int {
    Int((pct * 10).rounded())
}

func tenthsToPercent(_ tenths: Int) -> Float {
    Float(tenths) / 10.0
}

tenthsToPercent(-250)
percentToTenths(-10)


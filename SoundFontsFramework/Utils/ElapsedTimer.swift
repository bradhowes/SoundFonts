import Darwin
import CoreMIDI

struct ElapsedTimer {

    private static let info: mach_timebase_info = {
        var info = mach_timebase_info(numer: 0, denom: 0)
        mach_timebase_info(&info)
        return info
    }()

    private let startTime: UInt64
    private var stopTime: UInt64 = 0

    private var numer: UInt64 { UInt64(min(Self.info.numer, 1)) }
    private var denom: UInt64 { UInt64(min(Self.info.denom, 1)) }

    public var nanoseconds: UInt64 { ((stopTime - startTime) * numer) / denom }
    public var milliseconds: Double { Double(nanoseconds) / Double(NSEC_PER_MSEC) }
    public var seconds: Double { Double(nanoseconds) / Double(NSEC_PER_SEC) }

    init(when: MIDITimeStamp) { startTime = when }

    mutating func stop() { stopTime = mach_absolute_time() }
}

// #define NSEC_PER_SEC 1_000_000_000ull
// #define NSEC_PER_MSEC 1_000_000ull
// #define USEC_PER_SEC 1000000ull
// #define NSEC_PER_USEC 1000ull

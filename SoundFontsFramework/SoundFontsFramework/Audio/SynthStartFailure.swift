// Copyright © 2022 Brad Howes. All rights reserved.

/// Failure modes for a synth
public enum SynthStartFailure: Error, Equatable, CustomStringConvertible {
  /// No synth is available
  case noSynth
  /// Failed to active a session
  case sessionActivating(error: NSError)
  /// Failed to start audio engine
  case engineStarting(error: NSError)
  /// Failed to load a preset
  case presetLoading(error: NSError)
}

extension SynthStartFailure {

  /// The system error associated with a failure.
  var error: NSError? {
    switch self {
    case .noSynth: return nil
    case .sessionActivating(let err): return err
    case .engineStarting(let err): return err
    case .presetLoading(let err): return err
    }
  }

  public var description: String {
    switch self {
    case .noSynth: return "<SynthStartFailure: no synth>"
    case .sessionActivating(error: let error):
      return "<SynthStartFailure: sessionActivating - \(error.localizedDescription)>"
    case .engineStarting(error: let error):
      return "<SynthStartFailure: engineStarting - \(error.localizedDescription)>"
    case .presetLoading(error: let error):
      return "<SynthStartFailure: presetLoading - \(error.localizedDescription)>"
    }
  }
}

extension Result: @retroactive CustomStringConvertible {
  public var description: String {
    switch self {
    case .success(let value): return "<Result: success \(value)>"
    case .failure(let value): return "<Result: failure \(value)>"
    }
  }
}

// Copyright © 2023 Brad Howes. All rights reserved.

public enum MIDIControllerAction: String, Codable, CaseIterable {
  case nextPrevFavorite
  case selectFavorite

  case reverbMix
  case reverbRoom

  case delayTime
  case delayFeedback
  case delayCutoff
  case delayMix

  var displayName: String {
    switch self {
    case .nextPrevFavorite: return "+/- Favorite"
    case .selectFavorite: return "Select Favorite"

    case .reverbMix: return "Reverb Mix"
    case .reverbRoom: return "Reverb Room"

    case .delayTime: return "Delay Time"
    case .delayFeedback: return "Delay Feedback"
    case .delayCutoff: return "Delay Cutoff"
    case .delayMix: return "Delay Mix"
    }
  }
}

public enum MIDIControllerActionKind: String, Codable, CaseIterable {
  case absolute
  case relative

  var displayName: String {
    switch self {
    case .absolute: return ""
    case .relative: return " ±"
    }
  }
}

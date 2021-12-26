import Foundation

extension Optional where Wrapped: CustomStringConvertible {

  /// Obtain the description attribute of the wrapped value or "nil" if none
  public var descriptionOrNil: String {
    switch self {
    case .some(let value): return value.description
    case .none: return "nil"
    }
  }
}

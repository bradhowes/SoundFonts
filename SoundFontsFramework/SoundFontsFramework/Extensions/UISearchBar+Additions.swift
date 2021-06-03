// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

public func whiteSpaceOnlyIsNil(_ value: String?) -> String? {
  let text = (value ?? "").trimmingCharacters(in: .whitespaces)
  return text.isEmpty ? nil : text
}

extension UISearchBar {
  /// Obtain the current string value in the search bar, nil if the string is empty.
  public var searchTerm: String? { whiteSpaceOnlyIsNil(self.text) }
}

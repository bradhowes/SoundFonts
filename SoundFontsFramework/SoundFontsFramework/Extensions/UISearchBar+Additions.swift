// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

extension UISearchBar {

    /// Obtain the current string value in the search bar, nil if the string is empty.
    public var searchTerm: String? {
        let text = (self.text ?? "").trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : text
    }
}

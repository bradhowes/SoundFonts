// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

extension UISearchBar {

    /// Obtain a filtered version of the search bar contents
    public var searchTerm: String? {
        let text = (self.text ?? "").trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : text
    }
}

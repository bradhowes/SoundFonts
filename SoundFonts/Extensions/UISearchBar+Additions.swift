//
//  SearchBar.swift
//  SoundFonts
//
//  Created by Brad Howes on 12/30/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import UIKit

extension UISearchBar {
    
    /// Obtain a filtered version of the search bar contents
    var searchTerm: String? {
        let text = (self.text ?? "").trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : text
    }
}

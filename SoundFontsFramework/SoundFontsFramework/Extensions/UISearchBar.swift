// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

extension UISearchBar {

  /// Obtain the current string value in the search bar, nil if the string is empty.
  public var searchTerm: String? { self.text?.trimmedWhiteSpacesOrNil }
  public var nonNilSearchTerm: String { return self.text?.trimmedWhiteSpaces ?? "" }

  /**
   Begin a search by making the search field appear and contain the given search term

   - parameter term: the search term to use
   */
  public func beginSearch(with term: String) {
    self.text = term
    self.inputAssistantItem.leadingBarButtonGroups = []
    self.inputAssistantItem.trailingBarButtonGroups = []
    self.becomeFirstResponder()
  }

  func endSearch() {
    if isFirstResponder && canResignFirstResponder {
      resignFirstResponder()
      self.text = nil
    }
  }
}

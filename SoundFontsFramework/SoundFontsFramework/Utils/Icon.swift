// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

private class BundleTag {}

/// Collection of value formatters that use localized strings.
public enum Icon: CaseIterable {
  case edit
  case hide
  case effectOn
  case effectOff
  case favorite
  case unfavorite
  case remove

  private var resourceName: String {
    switch self {
    case .edit: return "Edit"
    case .hide: return "Hide"
    case .effectOn: return "EffectOn"
    case .effectOff: return "EffectOff"
    case .favorite: return "Fave"
    case .unfavorite: return "Trash"
    case .remove: return "Trash"
    }
  }

  var accessibilityLabel: String {
    switch self {
    case .edit:
      return NSLocalizedString(
        "swipeEdit", bundle: Bundle(for: BundleTag.self), value: "Edit item",
        comment: "Accessibility label for swipe action to edit an item")
    case .hide:
      return NSLocalizedString(
        "swipeHide", bundle: Bundle(for: BundleTag.self), value: "Hide preset",
        comment: "Accessibility label for swipe action to hide a preset")
    case .effectOn:
      return NSLocalizedString(
        "effectOn", bundle: Bundle(for: BundleTag.self), value: "Disable effect",
        comment: "Accessibility label for button to turn an effect off")
    case .effectOff:
      return NSLocalizedString(
        "effectOff", bundle: Bundle(for: BundleTag.self), value: "Enable effect",
        comment: "Accessibility label for button to turn an effect on")
    case .favorite:
      return NSLocalizedString(
        "swipeFavorite", bundle: Bundle(for: BundleTag.self), value: "Make new favorite",
        comment: "Accessibility label for swipe action to make a new favorite from a preset")
    case .unfavorite:
      return NSLocalizedString(
        "swipeUnfavorite", bundle: Bundle(for: BundleTag.self), value: "Remove favorite",
        comment: "Accessibility label for swipe action to remove a favorite")
    case .remove:
      return NSLocalizedString(
        "swipeDelete", bundle: Bundle(for: BundleTag.self), value: "Remove sound font",
        comment: "Accessibility label for swipe action to remove a sound font")
    }
  }

  var accessibilityHint: String {
    switch self {
    case .edit:
      return NSLocalizedString(
        "swipeEdit", bundle: Bundle(for: BundleTag.self), value: "Edits item",
        comment: "Accessibility hint for swipe action to edit an item")
    case .hide:
      return NSLocalizedString(
        "swipeHide", bundle: Bundle(for: BundleTag.self), value: "Hides preset",
        comment: "Accessibility hint for swipe action to hide a preset")
    case .effectOn:
      return NSLocalizedString(
        "effectOn", bundle: Bundle(for: BundleTag.self), value: "Disables effect",
        comment: "Accessibility hint for button to turn an effect off")
    case .effectOff:
      return NSLocalizedString(
        "effectOff", bundle: Bundle(for: BundleTag.self), value: "Enables effect",
        comment: "Accessibility hint for button to turn an effect on")
    case .favorite:
      return NSLocalizedString(
        "swipeFavorite", bundle: Bundle(for: BundleTag.self), value: "Makes a new favorite",
        comment: "Accessibility hint for swipe action to make a new favorite from a preset")
    case .unfavorite:
      return NSLocalizedString(
        "swipeUnfavorite", bundle: Bundle(for: BundleTag.self), value: "Removes the favorite",
        comment: "Accessibility hint for swipe action to remove a favorite")
    case .remove:
      return NSLocalizedString(
        "swipeDelete", bundle: Bundle(for: BundleTag.self), value: "Removes sound font",
        comment: "Accessibility hint for swipe action to remove a sound font")
    }
  }

  var image: UIImage {
    UIImage(named: resourceName, in: Bundle(for: BundleTag.self), compatibleWith: .none)!
  }
}

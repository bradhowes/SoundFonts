// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os

/// The event notifications that can come from an ActiveTagManager subscription.
public enum ActiveTagEvent: CustomStringConvertible {

  /**
   Change event

   - Parameter old: the previous active tag
   - Parameter new: the new active tag
   */
  case change(old: Tag?, new: Tag)

  public var description: String {
    switch self {
    case let .change(old, new):
      return "<ActiveTagEvent: change old: \(old.descriptionOrNil) new: \(new.description)>"
    }
  }
}

/**
 Tracks and manages the active tag.
 */
public final class ActiveTagManager: SubscriptionManager<ActiveTagEvent> {
  private lazy var log = Logging.logger("ActiveTagManager")
  private let tags: TagsProvider
  private let settings: Settings

  /// The currently active tag.
  public private(set) var activeTag: Tag = Tag.allTag {
    didSet {
      settings.activeTagKey = activeTag.key
    }
  }

  /**
   Construct new manager

   - parameter tags: the tags collection to use for values
   - parameter settings: the Settings store to use for the `activeTagKey` value
   */
  public init(tags: TagsProvider, settings: Settings) {
    self.tags = tags
    self.settings = settings
    super.init()
    tags.subscribe(self, notifier: tagsRestoredNotificationInBackground)
  }

  /**
   Set a new active Tag.

   - parameter index: the index of the Tag in the `Tags` collection to make active.
   */
  func setActiveTag(index: Int) {
    let newTag = tags.getBy(index: index)
    if activeTag != newTag {
      let oldTag = activeTag
      activeTag = newTag
      notify(.change(old: oldTag, new: newTag))
    }
  }

  /**
   Set a new active Tag.

   - parameter key: the unique key of the Tag in the `Tags` collection to make active.
   */
  func setActiveTag(key: Tag.Key) {
    let newTag = tags.getBy(key: key) ?? Tag.allTag
    if activeTag != newTag {
      let oldTag = activeTag
      activeTag = newTag
      notify(.change(old: oldTag, new: newTag))
    }
  }
}

extension ActiveTagManager {

  private func tagsRestoredNotificationInBackground(_ event: TagsEvent) {
    self.restoreActive()
  }

  private func restoreActive() {
    guard tags.isRestored else { return }
    let tagKey = settings.activeTagKey
    activeTag = tags.getBy(key: tagKey) ?? Tag.allTag
    notify(.change(old: nil, new: activeTag))
  }
}

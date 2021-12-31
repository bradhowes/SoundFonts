// Copyright © 2021 Brad Howes. All rights reserved.

import SoundFontInfoLib
import UIKit
import os

/// Manager for the tag collection.
final class TagsManager: SubscriptionManager<TagsEvent> {
  private lazy var log = Logging.logger("TagsManager")

  private var observer: ConfigFileObserver!

  private var collection: TagCollection {
    precondition(observer.restored)
    return observer.tags
  }

  /**
   Construct new manager

   - parameter consolidatedConfigFile: the configuration file that holds the tags to manage
   */
  init(_ consolidatedConfigFile: ConsolidatedConfigFile) {
    super.init()
    observer = ConfigFileObserver(configFile: consolidatedConfigFile, closure: collectionRestored)
  }
}

extension TagsManager: Tags {

  /// Indicator that the collection of tags has been restored
  var restored: Bool { observer.restored }

  /// True if the collection is empty
  var isEmpty: Bool { collection.isEmpty }

  /// The number of tags in the collection
  var count: Int { collection.count }

  func names(of keys: Set<Tag.Key>) -> [String] { collection.names(of: keys) }

  func index(of key: Tag.Key) -> Int? { collection.index(of: key) }

  func getBy(index: Int) -> Tag { collection.getBy(index: index) }

  func getBy(key: Tag.Key) -> Tag? { collection.getBy(key: key) }

  func append(_ tag: Tag) -> Int {
    defer { collectionChanged() }
    let index = collection.append(tag)
    notify(.added(new: index, tag: tag))
    return index
  }

  func insert(_ tag: Tag, at index: Int) {
    defer { collectionChanged() }
    collection.insert(tag, at: index)
    notify(.added(new: index, tag: tag))
  }

  func remove(at index: Int) -> Tag {
    defer { collectionChanged() }
    let tag = collection.remove(at: index)
    notify(.removed(old: index, tag: tag))
    return tag
  }

  func rename(_ index: Int, name: String) {
    defer { collectionChanged() }
    collection.rename(index, name: name)
    notify(.changed(index: index, tag: collection.getBy(index: index)))
  }

  func keySet(of indices: Set<Int>) -> Set<Tag.Key> {
    Set(indices.map { collection.getBy(index: $0).key })
  }

  func validate() {
    var invalidTags = [Tag.Key]()
    for index in 0..<self.count {
      let tag = self.getBy(index: index)
      if (tag.name == "All" && tag.key != Tag.allTag.key) || (tag.name == "Built-in" && tag.key != Tag.builtInTag.key) {
        invalidTags.append(tag.key)
      }
    }

    for key in invalidTags {
      if let index = self.index(of: key) {
        _ = self.remove(at: index)
      }
    }

    if self.getBy(key: Tag.builtInTag.key) == nil {
      insert(Tag.builtInTag, at: 0)
    }

    if self.getBy(key: Tag.allTag.key) == nil {
      insert(Tag.allTag, at: 0)
    }
  }
}

extension TagsManager {

  /// Default collection that is used when first running the app
  static var defaultCollection: TagCollection { TagCollection(tags: []) }

  private func collectionChanged() {
    os_log(.info, log: log, "collectionChanged - %{public}@", collection.description)
    observer.markChanged()
  }

  private func collectionRestored() {
    os_log(.info, log: self.log, "restored")
    DispatchQueue.main.async { self.notify(.restored) }
  }
}

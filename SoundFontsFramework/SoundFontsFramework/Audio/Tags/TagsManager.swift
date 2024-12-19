// Copyright © 2021 Brad Howes. All rights reserved.

import SoundFontInfoLib
import UIKit
import os

/// Manager of the Tag collection.
final class TagsManager: SubscriptionManager<TagsEvent> {
  private lazy var log: Logger = Logging.logger("TagsManager")

  private var observer: ConsolidatedConfigObserver!
  private var collection: TagCollection? { observer.tags }

  /**
   Construct new manager

   - parameter consolidatedConfigFile: the configuration file that holds the tags to manage
   */
  init(_ consolidatedConfigProvider: ConsolidatedConfigProvider) {
    super.init()
    observer = ConsolidatedConfigObserver(configProvider: consolidatedConfigProvider) { [weak self] in
      guard let self else { return }
      self.notifyCollectionRestored()
    }
  }
}

extension TagsManager: TagsProvider {

  /// Indicator that the collection of tags has been restored
  var isRestored: Bool { observer.isRestored }

  /// True if the collection is empty
  var isEmpty: Bool { collection?.isEmpty ?? true }

  /// The number of tags in the collection
  var count: Int { collection?.count ?? 0 }

  func names(of keys: Set<Tag.Key>) -> [String] { collection?.names(of: keys) ?? [] }

  func index(of key: Tag.Key) -> Int? { collection?.index(of: key) }

  func getBy(index: Int) -> Tag { collection!.getBy(index: index) }

  func getBy(key: Tag.Key) -> Tag? { collection?.getBy(key: key) }

  func append(_ tag: Tag) -> Int {
    guard let collection else { fatalError("logic error -- nil collection") }
    defer { markCollectionChanged() }
    let index = collection.append(tag)
    notify(.added(new: index, tag: tag))
    return index
  }

  func insert(_ tag: Tag, at index: Int) {
    guard let collection else { fatalError("logic error -- nil collection") }
    defer { markCollectionChanged() }
    collection.insert(tag, at: index)
    notify(.added(new: index, tag: tag))
  }

  func remove(at index: Int) -> Tag {
    guard let collection else { fatalError("logic error -- nil collection") }
    defer { markCollectionChanged() }
    let tag = collection.remove(at: index)
    notify(.removed(old: index, tag: tag))
    return tag
  }

  func rename(_ index: Int, name: String) {
    guard let collection else { fatalError("logic error -- nil collection") }
    defer { markCollectionChanged() }
    collection.rename(index, name: name)
    notify(.changed(index: index, tag: collection.getBy(index: index)))
  }

  func keySet(of indices: Set<Int>) -> Set<Tag.Key> {
    guard let collection else { fatalError("logic error -- nil collection") }
    return Set(indices.map { collection.getBy(index: $0).key })
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

  private func markCollectionChanged() {
    guard let collection else { fatalError("logic error -- nil collection") }
    log.debug("markCollectionChanged - \(collection.description, privacy: .public)")
    observer.markAsChanged()
  }

  private func notifyCollectionRestored() {
    log.debug("notifyCollectionRestored")
    notify(.restored)
  }
}

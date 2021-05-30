// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

extension RandomAccessCollection {

  public typealias OrderPredicate = (Iterator.Element, Iterator.Element) -> Bool

  /**
     Binary search operation for quick determination where to insert a new value into a collection that will preserve
     the ordering of the existing elements.

     - parameter value: the value to insert
     - parameter predicate: a closure/function that determines ordering of two elements
     - returns: index into the collection
     */
  public func insertionIndex(of value: Iterator.Element, predicate: OrderPredicate) -> Index {
    var low = startIndex
    var high = endIndex
    while low != high {
      let mid = index(low, offsetBy: distance(from: low, to: high) / 2)
      if predicate(self[mid], value) {
        low = index(after: mid)
      } else {
        high = mid
      }
    }
    return low
  }
}

extension RandomAccessCollection where Iterator.Element: AnyObject {

  /**
     Obtain the index in a collection for a given object.

     - parameter value: the object to look for
     - returns: index of the give value or `endIndex` if not found
     */
  public func search(for value: Iterator.Element, predicate: OrderPredicate) -> Index {
    let pos = insertionIndex(of: value, predicate: predicate)
    return pos < endIndex && self[pos] === value ? pos : endIndex
  }

  /**
     Binary search operation which simply determines if a given value is in the collection.

     - parameter value: the value to look for
     - parameter predicate: a closure/function that determines ordering of two elements
     - returns: true if element is in the collections
     */
  public func contains(value: Iterator.Element, predicate: OrderPredicate) -> Bool {
    let pos = insertionIndex(of: value, predicate: predicate)
    return pos < endIndex && self[pos] === value
  }
}

extension RandomAccessCollection where Iterator.Element: Equatable {

  /**
     Obtain the index in a collection for a given value.

     - parameter value: the value to look for
     - returns: index of the give value or `endIndex` if not found
     */
  public func search(for value: Iterator.Element, predicate: OrderPredicate) -> Index {
    let pos = insertionIndex(of: value, predicate: predicate)
    return pos < endIndex && self[pos] == value ? pos : endIndex
  }

  /**
     Binary search operation which simply determines if a given value is in the collection.

     - parameter value: the value to look for
     - parameter predicate: a closure/function that determines ordering of two elements
     - returns: true if element is in the collections
     */
  public func contains(value: Iterator.Element, predicate: OrderPredicate) -> Bool {
    let pos = insertionIndex(of: value, predicate: predicate)
    return pos < endIndex && self[pos] == value
  }
}

extension Collection where Iterator.Element: Comparable {

  /**
     Obtain the min and max values in a collection.

     - returns: 2-tuple with the minimum and maximum values or nil if collection is empty
     */
  public func minMax() -> (min: Iterator.Element, max: Iterator.Element)? {
    guard let value = first else { return nil }
    var min = value
    var max = value
    var pos = index(after: startIndex)
    while pos < endIndex {
      let value = self[pos]
      if value < min { min = value }
      if value > max { max = value }
      pos = index(after: pos)
    }
    return (min: min, max: max)
  }
}

import PlaygroundSupport
import Foundation
import UIKit

var dict: [String: Any] = [:]
dict["foo"] = false
dict
if let a = dict["foo"] {
  print(a)
}

// PlaygroundPage.current.needsIndefiniteExecution = true

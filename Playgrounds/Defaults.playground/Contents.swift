import PlaygroundSupport
import Foundation
import UIKit

enum ConfigFileError: Error {
  case unexpectedType
  case invalidContent
}

class ConfigFile: UIDocument {

  let name: String

  var contents: String = "" {
    didSet { print(contents) }
  }

  @objc dynamic public private(set) var restored: Bool = false {
    didSet {
      self.updateChangeCount(.done)
      self.save(to: fileURL, for: .forOverwriting)
    }
  }

  init(name: String) {
    self.name = name
    super.init(fileURL: URL(fileURLWithPath: "ConfigFile.txt"))
  }

  func load(newCompletionHandler: @escaping (Bool) -> Void) {
    self.open { ok in
      if !ok {
        self.contents = "\(self.name) new"
        self.updateChangeCount(.done)
        self.save(to: self.fileURL, for: .forOverwriting, completionHandler: newCompletionHandler)
      }
    }
  }

  override public func contents(forType typeName: String) throws -> Any {
    print("\(#function)")
    guard let data = contents.data(using: .utf8) else { throw ConfigFileError.unexpectedType }
    return data
  }

  override public func load(fromContents contents: Any, ofType typeName: String?) throws {
    print("\(#function)")
    guard let data = contents as? Data else { throw ConfigFileError.unexpectedType }
    guard let contents = String(data: data, encoding: .utf8) else { throw ConfigFileError.invalidContent }
    self.contents = contents
  }

  func save(completionHandler: @escaping (Bool) -> Void) {
    print("\(#function)")
    self.updateChangeCount(.done)
    self.save(to: fileURL, for: .forOverwriting, completionHandler: completionHandler)
  }

//  override public func revert(toContentsOf url: URL, completionHandler: ((Bool) -> Void)? = nil) {
//    completionHandler?(false)
//  }
}

let a = ConfigFile(name: "a")
a.load { print("a.load: \($0)") }

let b = ConfigFile(name: "b")
b.load { print("b.load: \($0)") }

PlaygroundPage.current.needsIndefiniteExecution = true

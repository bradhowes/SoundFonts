import UIKit
import os

public struct ChangesCompiler {
  private static let log = Logging.logger("ChangesCompiler")

  public static func compile() -> [String] {
    os_log(.debug, log: log, "compile changes")

    var entries = [String]()
    let bundle = Bundle(for: TutorialViewController.self)
    guard
      let changeLogUrl = bundle.url(forResource: "Changes", withExtension: "md", subdirectory: nil)
    else {
      os_log(.error, log: log, "no Changes.md resource found")
      return entries
    }

    guard let data = try? String(contentsOfFile: changeLogUrl.path, encoding: .utf8) else {
      os_log(.error, log: log, "failed to read from Changes.md")
      return entries
    }

    for line in data.components(separatedBy: .newlines) {
      if line.hasPrefix("# ") {
        let version = String(line[line.index(line.startIndex, offsetBy: 2)...])
          .trimmingCharacters(in: .whitespaces)
        os_log(.debug, log: log, "found version line - '%{public}s'", version)
        entries.append("#" + version)
      } else if line.hasPrefix("* ") {
        let entry = String(line[line.index(line.startIndex, offsetBy: 2)...])
          .trimmingCharacters(in: .whitespaces)
        os_log(.debug, log: log, "entry: '%{public}s'", entry)
        entries.append(entry)
      } else if line.hasPrefix(" ") && !entries.isEmpty {
        entries[entries.count - 1] = entries.last! + " " + line.trimmingCharacters(in: .whitespaces)
      } else {
        os_log(.debug, log: log, "skipping: '%{public}s'", line)
      }
    }

    os_log(.debug, log: log, "done - %d", entries.count)
    return entries
  }

  static let bullet = "•"
  static let versionFont = UIFont.preferredFont(forTextStyle: .headline)
  static let font = UIFont.preferredFont(forTextStyle: .title3)

  public static func views(_ entries: [String]) -> [UIView] {
    return entries.map { entry in
      if entry.starts(with: "#") {
        return versionView(String(entry.dropFirst(1)))
      }
      let stack = UIStackView(arrangedSubviews: [bulletView(), entryView(entry)])
      stack.axis = .horizontal
      stack.spacing = 8
      stack.alignment = .firstBaseline
      stack.distribution = .fill
      stack.translatesAutoresizingMaskIntoConstraints = false
      return stack
    }
  }

  static func versionView(_ version: String) -> UIView {
    let versionView = UILabel()
    versionView.text = version
    versionView.textColor = .systemOrange
    versionView.font = versionFont
    return versionView
  }

  static func bulletView() -> UIView {
    let bulletView = UILabel()
    bulletView.text = bullet
    bulletView.textColor = .systemOrange
    bulletView.font = font
    bulletView.textAlignment = .natural
    bulletView.setContentHuggingPriority(.required, for: .horizontal)
    bulletView.translatesAutoresizingMaskIntoConstraints = false
    bulletView.setContentHuggingPriority(.required, for: .horizontal)
    bulletView.setContentCompressionResistancePriority(.required, for: .horizontal)
    return bulletView
  }

  static func entryView(_ content: String) -> UIView {
    let entryView = UILabel()
    entryView.text = content
    entryView.textColor = .systemTeal
    entryView.font = font
    entryView.numberOfLines = 0
    entryView.textAlignment = .left
    // entryView.setContentCompressionResistancePriority(.required, for: .horizontal)
    entryView.translatesAutoresizingMaskIntoConstraints = false
    return entryView
  }
}

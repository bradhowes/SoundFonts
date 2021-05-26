import UIKit
import os

public struct ChangesCompiler {
    private static let log = Logging.logger("ChangesCompiler")

    public static func compile(since: String, maxItems: Int = 6) -> [String] {
        os_log(.info, log: log, "compile changes since: %{public}s", since)

        var entries = [String]()
        let bundle = Bundle(for: TutorialViewController.self)
        guard let changeLogUrl = bundle.url(forResource: "Changes", withExtension: "md", subdirectory: nil) else {
            os_log(.error, log: log, "no Changes.md resource found")
            return entries
        }

        guard let data = try? String(contentsOfFile: changeLogUrl.path, encoding: .utf8) else {
            os_log(.error, log: log, "failed to read from Changes.md")
            return entries
        }

        let sinceVersion = since.versionComponents
        for line in data.components(separatedBy: .newlines) {
            if line.hasPrefix("# ") {
                let version = String(line[line.index(line.startIndex, offsetBy: 2)...])
                    .trimmingCharacters(in: .whitespaces)
                os_log(.info, log: log, "found version line - '%{public}s'", version)
                if version.versionComponents <= sinceVersion {
                    os_log(.info, log: log, "version <= since")
                    break
                }
            }
            else if line.hasPrefix("* ") {
                let entry = String(line[line.index(line.startIndex, offsetBy: 2)...])
                    .trimmingCharacters(in: .whitespaces)
                os_log(.info, log: log, "entry: '%{public}s'", entry)
                entries.append(entry)
                if entries.count >= maxItems {
                    os_log(.info, log: log, "max items reached")
                    break
                }
            }
            else {
                os_log(.info, log: log, "skipping: '%{public}s'", line)
            }
        }

        os_log(.info, log: log, "done - %d", entries.count)
        return entries
    }

    static let bullet = "•"
    static let font = UIFont.preferredFont(forTextStyle: .title3)

    public static func views(_ entries: [String]) -> [UIView] {
        return entries.map { entry in
            let stack = UIStackView(arrangedSubviews: [bulletView(), entryView(entry)])
            stack.axis = .horizontal
            stack.spacing = 8
            stack.alignment = .firstBaseline
            stack.distribution = .fill
            stack.translatesAutoresizingMaskIntoConstraints = false
            return stack
        }
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

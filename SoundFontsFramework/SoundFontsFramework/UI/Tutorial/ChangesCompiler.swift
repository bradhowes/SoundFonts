import UIKit

public struct ChangesCompiler {

    public static func compile(since: String) -> [String] {
        var entries = [String]()
        let bundle = Bundle(for: TutorialViewController.self)
        guard let changeLogUrl = bundle.url(forResource: "Changes", withExtension: "md", subdirectory: nil) else {
            return entries
        }

        guard let data = try? String(contentsOfFile: changeLogUrl.path, encoding: .utf8) else {
            return entries
        }

        var version = ""
        for line in data.components(separatedBy: .newlines) {
            if line.hasPrefix("# ") {
                version = String(line[line.index(line.startIndex, offsetBy: 2)...])
                    .trimmingCharacters(in: .whitespaces)
                if version <= since {
                    break
                }
            }
            else if line.hasPrefix("* ") {
                let entry = String(line[line.index(line.startIndex, offsetBy: 2)...])
                    .trimmingCharacters(in: .whitespaces)
                entries.append(entry)
            }
            else {
                print("*** skipping line \(line)")
            }
        }

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
        return bulletView
    }

    static func entryView(_ content: String) -> UIView {
        let entryView = UILabel()
        entryView.text = content
        entryView.textColor = .systemTeal
        entryView.font = font
        entryView.numberOfLines = 0
        entryView.textAlignment = .left
        entryView.setContentCompressionResistancePriority(.required, for: .horizontal)
        entryView.translatesAutoresizingMaskIntoConstraints = false
        return entryView
    }
}

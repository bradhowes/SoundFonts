import UIKit

final class ChangesPageViewController: TutorialPageViewController {

    @IBOutlet private weak var changesView: UIStackView!

    var changes: [String]?

    override public func viewDidLoad() {
        super.viewDidLoad()
        guard let changes = changes, !changes.isEmpty else { fatalError("unexpected nil/empty changes") }
        setChanges(ChangesCompiler.views(changes))
        self.changes = nil
    }

    func setChanges(_ views: [UIView]) {
        for entry in views {
            changesView.addArrangedSubview(entry)
        }

        // NOTE: the storyboard has a placeholder item in it for layout purposes.
        changesView.arrangedSubviews.first?.isHidden = true
    }
}

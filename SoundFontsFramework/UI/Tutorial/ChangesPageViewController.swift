import UIKit

final class ChangesPageViewController: TutorialPageViewController {

    @IBOutlet private weak var changesView: UIStackView!

    var changes: [String]?

    override public func viewDidLoad() {
        super.viewDidLoad()
        guard let changes = changes, !changes.isEmpty else { fatalError("unexpected nil/empty changes") }
        setChanges(ChangesCompiler.views(changes))
        Settings.instance.showedChanges = Bundle.main.releaseVersionNumber
        self.changes = nil
    }

    func setChanges(_ views: [UIView]) {
        for entry in views {
            changesView.addArrangedSubview(entry)
        }

        changesView.arrangedSubviews.first?.isHidden = true
    }
}

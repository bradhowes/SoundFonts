// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Specialization of UITableViewCell that will display a SoundFont entry or a Patch entry.
 */
public final class TableCell: UITableViewCell, ReusableView, NibLoadableView {
    private lazy var log = Logging.logger("TableCell")

    /// Unicode character to show when a cell refers to a Patch that is in a Favorite
    private static let goldStarPrefix = "✪"

    public static func favoriteTag(_ isFavorite: Bool) -> String { return isFavorite ? goldStarPrefix + " " : "" }

    private var activeIndicatorAnimator: UIViewPropertyAnimator?

    @IBInspectable public var normalFontColor: UIColor = .lightGray
    @IBInspectable public var selectedFontColor: UIColor = .white
    @IBInspectable public var activeFontColor: UIColor = .systemTeal
    @IBInspectable public var favoriteFontColor: UIColor = .systemOrange

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var activeIndicator: UIView!
    @IBOutlet weak var tagEditor: UITextField!

    private var bookmark: Bookmark?
    private var timer: Timer?
    var activeAlert: UIAlertController?

    override public func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = true
        selectedBackgroundView = UIView()
        multipleSelectionBackgroundView = UIView()
    }

    public func updateForFont(name: String, kind: SoundFontKind, isSelected: Bool, isActive: Bool) {
        var name = name
        if case let .reference(bookmark) = kind {
            self.bookmark = bookmark
            name += "°"
            updateButton()
            startMonitor()
        }
        update(name: name, isSelected: isSelected, isActive: isActive, isFavorite: false, isEditing: false)
    }

    public func updateForPatch(name: String, isActive: Bool, isFavorite: Bool, isEditing: Bool) {
        update(name: Self.favoriteTag(isFavorite) + name, isSelected: isActive, isActive: isActive,
               isFavorite: isFavorite, isEditing: isEditing)
    }

    public func updateForTag(name: String, isActive: Bool) {
        update(name: name, isSelected: isActive, isActive: isActive, isFavorite: false, isEditing: false)
    }

    override public func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if let view = reorderControlImageView {
            view.tint(color: .white)
        }
    }

    private func update(name: String, isSelected: Bool, isActive: Bool, isFavorite: Bool, isEditing: Bool) {

        self.name.text = name
        self.name.textColor = fontColorWhen(isSelected: isSelected, isActive: isActive, isFavorite: isFavorite)
        if isEditing {
            activeIndicator.isHidden = true
        }
        else if isActive == activeIndicator.isHidden {
            showActiveIndicator(isActive)
        }
    }

    private func stopAnimation() {
        activeIndicatorAnimator?.stopAnimation(false)
        activeIndicatorAnimator?.finishAnimation(at: .end)
        activeIndicatorAnimator = nil
    }

    override public func prepareForReuse() {
        super.prepareForReuse()

        stopAnimation()
        stopMonitor()
        accessoryView = nil
        activeAlert = nil

        name.isHidden = false
        tagEditor.isHidden = true
        tagEditor.isEnabled = false
    }

    private func stopMonitor() {
        timer?.invalidate()
    }

    private func startMonitor() {
        stopMonitor()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in self.updateButton() }
    }

    private func showActiveIndicator(_ isActive: Bool) {
        stopAnimation()
        guard isActive else {
            activeIndicator.isHidden = true
            return
        }

        activeIndicator.alpha = 0.0
        activeIndicator.isHidden = false
        let activeIndicatorAnimator = UIViewPropertyAnimator(duration: 0.4, curve: .easeIn) {
            self.activeIndicator.alpha = 1.0
        }
        activeIndicatorAnimator.addCompletion { _ in self.activeIndicator.alpha = 1.0 }
        activeIndicatorAnimator.startAnimation()
        self.activeIndicatorAnimator = activeIndicatorAnimator
    }

    private func fontColorWhen(isSelected: Bool, isActive: Bool, isFavorite: Bool) -> UIColor? {
        if isActive { return activeFontColor }
        if isFavorite { return favoriteFontColor }
        if isSelected { return selectedFontColor }
        return normalFontColor
    }

    private func updateButton() {
        accessoryView = infoButton
        if accessoryView == nil && activeAlert != nil {
            activeAlert?.dismiss(animated: true)
            activeAlert = nil
        }
    }

    private var infoButton: UIButton? {
        guard let bookmark = self.bookmark else { return nil }
        if bookmark.isAvailable { return nil }
        if !bookmark.isUbiquitous { return missingFileButton }
        return downloadableFileButton
    }

    private var downloadableFileButton: UIButton {
        let image = UIImage(named: "Download", in: Bundle(for: Self.self), compatibleWith: nil)
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(downloadMissingFile), for: .touchUpInside)
        return button
    }

    @objc private func downloadMissingFile() {
        guard let bookmark = self.bookmark else { return }
        let alert = UIAlertController(title: "Downloading", message: "Downloading the SF2 file for '\(bookmark.name)'",
                                      preferredStyle: .alert)
        activeAlert = alert
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in self.activeAlert = nil })
        viewController?.present(alert, animated: true)
    }

    private var missingFileButton: UIButton {
        let image = UIImage(named: "Error", in: Bundle(for: Self.self), compatibleWith: nil)
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(showMissingFileAlert), for: .touchUpInside)
        return button
    }

    @objc private func showMissingFileAlert() {
        guard let bookmark = self.bookmark else { return }
        let alert = UIAlertController(title: "File Missing",
                                      message: "Unable to access the SF2 file for '\(bookmark.name)'",
                                      preferredStyle: .alert)
        activeAlert = alert
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in self.activeAlert = nil })
        viewController?.present(alert, animated: true)
    }

    private var viewController: UIViewController? {
        var responder: UIResponder? = superview
        while responder != nil {
            if let controller = responder as? UIViewController { return controller }
            responder = responder?.next
        }

        return nil
    }

    @IBAction func editingChanged(_ sender: Any) {
    }

    @IBAction func editingDidEnd(_ sender: Any) {
    }
}

extension UITableViewCell {
    fileprivate var reorderControlImageView: UIImageView? {
        let reorderControl = self.subviews.first { view -> Bool in
            view.classForCoder.description() == "UITableViewCellReorderControl"
        }
        return reorderControl?.subviews.first { view -> Bool in view is UIImageView } as? UIImageView
    }
}

extension UIImageView {
    fileprivate func tint(color: UIColor) {
        self.image = self.image?.withRenderingMode(.alwaysTemplate)
        self.tintColor = color
    }
}

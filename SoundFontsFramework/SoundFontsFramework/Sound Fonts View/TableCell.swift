// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/// Specialization of UITableViewCell that will display a SoundFont name, a Preset name, or a Tag name.
/// Probably better would be to separate these into distinct classes, but this works for now.
public final class TableCell: UITableViewCell, ReusableView, NibLoadableView {
  private lazy var log = Logging.logger("TableCell")

  /// Unicode character to show when a cell refers to a preset that is in a Favorite
  private static let goldStarPrefix = "✪"

  public static func favoriteTag(_ isFavorite: Bool) -> String {
    return isFavorite ? goldStarPrefix + " " : ""
  }

  private var activeIndicatorAnimator: UIViewPropertyAnimator?
  private let normalFontColor: UIColor = .lightGray
  private let selectedFontColor: UIColor = .white
  private let activeFontColor: UIColor = .systemTeal
  private let favoriteFontColor: UIColor = .systemOrange

  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var activeIndicator: UIView!
  /// Text field used to edit tag names (not used for SoundFont or Preset names)
  @IBOutlet weak var tagEditor: UITextField!

  private var bookmark: Bookmark?
  private var timer: Timer?

  /// Set if there is a problem accessing a file associated with this cell.
  var activeAlert: UIAlertController?

  override public func awakeFromNib() {
    super.awakeFromNib()
    translatesAutoresizingMaskIntoConstraints = true
    selectedBackgroundView = UIView()
    multipleSelectionBackgroundView = UIView()
  }

  /**
     Update cell contents for a sound font.

     - parameter name: the name of the sound font to show
     - parameter kind: the type of sound font the cell represents
     - parameter isSelected: true if the cell holds the selected sound font
     - parameter isActive: true if the cell holds the sound font of the active preset
     */
  public func updateForFont(name: String, kind: SoundFontKind, isSelected: Bool, isActive: Bool) {
    var name = name
    if case let .reference(bookmark) = kind {
      self.bookmark = bookmark
      name += "°"
      updateButton()
      startMonitor()
    }
    os_log(.debug, log: log, "updateForFont - '%{public}s' A: %d S: %d", name, isActive, isSelected)
    update(name: name, isSelected: isSelected, isActive: isActive, isFavorite: false)
  }

  /**
     Update cell contents for a sound font preset.

     - parameter name: the name of the preset
     - parameter isActive: true if the cell holds the active preset
     - parameter isEditing: true if the table view is in edit mode
     */
  public func updateForPreset(name: String, isActive: Bool) {
    os_log(.debug, log: log, "updateForPreset - '%{public}s' A: %d", name, isActive)
    update(name: name, isSelected: isActive, isActive: isActive, isFavorite: false)
  }

  /**
     Update cell contents for a favorite.

     - parameter name: the name of the favorite
     - parameter isActive: true if the favorite is the active preset
     */
  public func updateForFavorite(name: String, isActive: Bool) {
    os_log(.debug, log: log, "updateForFavorite - '%{public}s' A: %d", name, isActive)
    update(name: Self.favoriteTag(true) + name, isSelected: isActive, isActive: isActive, isFavorite: true)
  }

  /**
     Update cell contents for a tag.

     - parameter name: the tag name
     - parameter isActive: true if cell holds the active tag
     */
  public func updateForTag(name: String, isActive: Bool) {
    os_log(.debug, log: log, "updateForTag - '%{public}s' A: %d", name, isActive)
    update(name: name, isSelected: isActive, isActive: isActive, isFavorite: false)
  }

  /**
     Make sure that the 'reorder' button can be seen when the table view is in edit mode
     */
  override public func setEditing(_ editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
    if editing {
      reorderControlImageView?.tint(color: .white)
      showActiveIndicator(activeIndicatorAnimator != nil)
    }
  }

  private func update(name: String, isSelected: Bool, isActive: Bool, isFavorite: Bool) {
    self.name.text = name
    self.name.textColor = fontColorWhen(isSelected: isSelected, isActive: isActive, isFavorite: isFavorite)
    showActiveIndicator(isActive)
  }

  override public func prepareForReuse() {
    os_log(.debug, log: log, "prepareForReuse")
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
    guard isActive && !isEditing else {
      stopAnimation()
      if !activeIndicator.isHidden {
        activeIndicator.isHidden = true
        os_log(.debug, log: log, "showActiveIndicator - '%{public}s' hidden", name.text ?? "?")
      }
      return
    }

    guard activeIndicatorAnimator == nil else {
      os_log(.debug, log: log, "showActiveIndicator - '%{public}s' already done", name.text ?? "?")
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
    os_log(.debug, log: log, "showActiveIndicator - '%{public}s' done", name.text ?? "?")
  }

  private func stopAnimation() {
    activeIndicatorAnimator?.stopAnimation(false)
    activeIndicatorAnimator?.finishAnimation(at: .end)
    activeIndicatorAnimator = nil
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
    let alert = UIAlertController(
      title: "Downloading", message: "Downloading the SF2 file for '\(bookmark.name)'",
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
    let alert = UIAlertController(
      title: "File Missing",
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

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

  private let normalFontColor: UIColor = .lightGray
  private let selectedFontColor: UIColor = .white
  private let activeFontColor: UIColor = .systemTeal
  private let favoriteFontColor: UIColor = .systemOrange

  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var activeIndicator: UIView!
  /// Text field used to edit tag names (not used for SoundFont or Preset names)
  @IBOutlet weak var tagEditor: UITextField!
  @IBOutlet weak var tuningIndicator: UIView!

  private var bookmark: Bookmark?
  private var timer: Timer?

  /// Set if there is a problem accessing a file associated with this cell.
  var activeAlert: UIAlertController?

  override public func awakeFromNib() {
    super.awakeFromNib()
    translatesAutoresizingMaskIntoConstraints = true
    selectedBackgroundView = UIView()
    multipleSelectionBackgroundView = UIView()
    tuningIndicator.layer.cornerRadius = 3.0
  }

  public enum Selected: Int {
    case no = 0
    case yes = 1
  }

  public enum Active: Int {
    case no = 0
    case yes = 1
  }

  public enum CustomTuning: Int {
    case no = 0
    case yes = 1
  }

  public enum Favorite: Int {
    case no = 0
    case yes = 1
  }

  /**
   Update cell contents for a sound font.

   - parameter name: the name of the sound font to show
   - parameter kind: the type of sound font the cell represents
   - parameter isSelected: true if the cell holds the selected sound font
   - parameter isActive: true if the cell holds the sound font of the active preset
   */
  public func updateForFont(name: String, kind: SoundFontKind, selected: Selected, active: Active) {
    var name = name
    if case let .reference(bookmark) = kind {
      self.bookmark = bookmark
      name += "°"
      updateButton()
      startMonitor()
    }
    os_log(.debug, log: log, "updateForFont - '%{public}s' A: %d S: %d", name, active.rawValue, selected.rawValue)
    update(name: name, selected: selected, active: active, customTuning: .no, favorite: .no)
    self.name.accessibilityLabel = "font \(name)"
    self.name.accessibilityHint = "font list entry for font \(name)"
  }

  /**
   Update cell contents for a sound font preset.

   - parameter name: the name of the preset
   - parameter isActive: true if the cell holds the active preset
   */
  public func updateForPreset(name: String, active: Active, customTuning: CustomTuning) {
    os_log(.debug, log: log, "updateForPreset - '%{public}s' A: %d T: %d", name, active.rawValue, customTuning.rawValue)
    update(name: name, selected: Selected(rawValue: active.rawValue)!, active: active, customTuning: customTuning,
           favorite: .no)
    self.name.accessibilityLabel = "preset \(name)"
    self.name.accessibilityHint = "preset list entry for preset \(name)"
  }

  /**
   Update cell contents for a favorite.

   - parameter name: the name of the favorite
   - parameter isActive: true if the favorite is the active preset
   */
  public func updateForFavorite(name: String, active: Active, customTuning: CustomTuning) {
    os_log(.debug, log: log, "updateForFavorite - '%{public}s' A: %d T: %d", name, active.rawValue, customTuning.rawValue)
    update(name: Self.favoriteTag(true) + name, selected: Selected(rawValue: active.rawValue)!, active: active,
           customTuning: customTuning, favorite: .yes)
    self.name.accessibilityLabel = "favorite \(name)"
    self.name.accessibilityHint = "preset list entry for favorite \(name)"
  }

  /**
   Update cell contents for a tag.

   - parameter name: the tag name
   - parameter active: .yes if cell holds the active tag
   */
  public func updateForTag(name: String, active: Active) {
    os_log(.debug, log: log, "updateForTag - '%{public}s' A: %d", name, active.rawValue)
    update(name: name, selected: Selected(rawValue: active.rawValue)!, active: active, customTuning: .no, favorite: .no)
    self.name.accessibilityLabel = "tag \(name)"
    self.name.accessibilityHint = "tag list entry for tag \(name)"
  }

  /**
   Make sure that the 'reorder' button can be seen when the table view is in edit mode
   */
  override public func setEditing(_ editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
    if editing {
      reorderControlImageView?.tint(color: .white)
    }
  }

  private func update(name: String, selected: Selected, active: Active, customTuning: CustomTuning, favorite: Favorite) {
    self.name.text = name
    self.name.textColor = fontColorWhen(selected: selected, active: active, favorite: favorite)
    showActiveIndicator(active)
    showTuningIndicator(customTuning)
    activeIndicator.accessibilityIdentifier = active == .yes ? "\(name) is active" : "\(name) is not active"
    tuningIndicator.accessibilityIdentifier = customTuning == .yes ? "\(name) has tuning" : "\(name) has no tuning"
  }

  override public func prepareForReuse() {
    os_log(.debug, log: log, "prepareForReuse")
    super.prepareForReuse()

    stopMonitor()
    accessoryView = nil
    activeAlert = nil

    name.isHidden = false
    tagEditor.isHidden = true
    tagEditor.isEnabled = false

    tuningIndicator.isHidden = true
  }

  private func stopMonitor() {
    timer?.invalidate()
  }

  private func startMonitor() {
    stopMonitor()
    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.updateButton() }
  }

  private func showTuningIndicator(_ customTuning: CustomTuning) {
    tuningIndicator.isHidden = customTuning == .no
  }

  private func showActiveIndicator(_ active: Active) {
    guard active == .yes && !isEditing else {
      if !activeIndicator.isHidden {
        activeIndicator.isHidden = true
        os_log(.debug, log: log, "showActiveIndicator - '%{public}s' hidden", name.text ?? "?")
      }
      return
    }

    activeIndicator.isHidden = false
    os_log(.debug, log: log, "showActiveIndicator - '%{public}s' done", name.text ?? "?")
  }

  private func fontColorWhen(selected: Selected, active: Active, favorite: Favorite) -> UIColor? {
    if active == .yes { return activeFontColor }
    if favorite == .yes { return favoriteFontColor }
    if selected == .yes { return selectedFontColor }
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
    alert.addAction(UIAlertAction(title: "OK", style: .cancel) { [weak self] _ in self?.activeAlert = nil })
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
    alert.addAction(UIAlertAction(title: "OK", style: .cancel) { [weak self] _ in self?.activeAlert = nil })
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

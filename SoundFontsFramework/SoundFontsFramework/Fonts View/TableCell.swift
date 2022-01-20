// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/// Specialization of UITableViewCell that will display a SoundFont name, a Preset name, or a Tag name.
/// Probably better would be to separate these into distinct classes, but this works for now.
public final class TableCell: UITableViewCell, ReusableView, NibLoadableView {
  fileprivate lazy var log = Logging.logger("TableCell")

  /**
   Attribute flags that describes the models the state of a row in a table
   */
  public struct Flags: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// The row is currently selected but not active (pertains to the list of fonts)
    public static let selected = Flags(rawValue: 1 << 0)
    /// The row is currently active -- shows marker besides the name
    public static let active = Flags(rawValue: 1 << 1)
    /// The row is showing a favorited item -- shows a `star` before the name
    public static let favorite = Flags(rawValue: 1 << 2)
    /// The row is showing a preset with a custom tuning adjustment
    public static let tuningSetting = Flags(rawValue: 1 << 3)
    /// The row is showing a preset with a custom pan adjustment
    public static let panSetting = Flags(rawValue: 1 << 4)
    /// The row is showing a preset with a custom gain adjustment
    public static let gainSetting = Flags(rawValue: 1 << 5)

    public var isSelected: Bool { self.contains(.selected) }
    public var isActive: Bool { self.contains(.active) }
    public var isFavorite: Bool { self.contains(.favorite) }
    public var hasTuningSetting: Bool { self.contains(.tuningSetting) }
    public var hasPanSetting: Bool { self.contains(.panSetting) }
    public var hasGainSetting: Bool { self.contains(.gainSetting) }
  }

  /// Unicode character to show when a cell refers to a preset that is in a Favorite
  private static let goldStarPrefix = "✪"

  public static func favoriteTag(_ isFavorite: Bool) -> String { isFavorite ? goldStarPrefix + " " : "" }

  private let normalFontColor: UIColor = .lightGray
  private let selectedFontColor: UIColor = .white
  private let activeFontColor: UIColor = .systemTeal
  private let favoriteFontColor: UIColor = .systemOrange

  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var activeIndicator: UIView!
  /// Text field used to edit tag names (not used for SoundFont or Preset names)
  @IBOutlet weak var tagEditor: UITextField!
  @IBOutlet weak var tuningIndicator: UILabel!
  @IBOutlet weak var panIndicator: UILabel!
  @IBOutlet weak var gainIndicator: UILabel!

  private var bookmark: Bookmark?
  private var buttonMonitor: Timer?

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
  public func updateForFont(at indexPath: IndexPath, name: String, kind: SoundFontKind, flags: Flags) {
    var name = name
    if case let .reference(bookmark) = kind {
      self.bookmark = bookmark
      name += "°"
      updateButton()
      startButtonMonitor()
    }

    os_log(.debug, log: log, "updateForFont - '%{public}s' flags: %d", name, flags.rawValue)
    update(name: indexPath.prefixRow + name, flags: flags)
    self.name.accessibilityLabel = "font \(name)"
    self.name.accessibilityHint = "font list entry for font \(name)"
  }

  /**
   Update cell contents for a sound font preset.

   - parameter name: the name of the preset
   - parameter isActive: true if the cell holds the active preset
   */
  public func updateForPreset(at indexPath: IndexPath, name: String, flags: Flags) {
    update(name: indexPath.prefixSectionRow + name, flags: flags)
    self.name.accessibilityLabel = "preset \(name)"
    self.name.accessibilityHint = "preset list entry for preset \(name)"
  }

  /**
   Update cell contents for a favorite.

   - parameter name: the name of the favorite
   - parameter isActive: true if the favorite is the active preset
   */
  public func updateForFavorite(at indexPath: IndexPath, name: String, flags: Flags) {
    update(name: indexPath.prefixSectionRow + Self.favoriteTag(true) + name, flags: flags)
    self.name.accessibilityLabel = "favorite \(name)"
    self.name.accessibilityHint = "preset list entry for favorite \(name)"
  }

  /**
   Update cell contents for a tag.

   - parameter name: the tag name
   - parameter active: .yes if cell holds the active tag
   */
  public func updateForTag(at indexPath: IndexPath, name: String, flags: Flags) {
    update(name: indexPath.prefixRow + name, flags: flags)
    self.name.accessibilityLabel = "tag \(name)"
    self.name.accessibilityHint = "tag list entry for tag \(name)"
  }

  /**
   Make sure that the 'reorder' button can be seen when the table view is in edit mode
   */
  override public func setEditing(_ editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
  }

  private func update(name: String, flags: Flags) {
    self.name.text = name
    self.name.textColor = fontColor(for: flags)

    activeIndicator.isHidden = !flags.isActive
    tuningIndicator.isHidden = !flags.hasTuningSetting
    panIndicator.isHidden = !flags.hasPanSetting
    gainIndicator.isHidden = !flags.hasGainSetting

    // showsReorderControl = true

    activeIndicator.accessibilityIdentifier = flags.isActive ? "\(name) is active" : "\(name) is not active"
    tuningIndicator.accessibilityIdentifier = flags.hasTuningSetting ? "\(name) has tuning" : "\(name) has no tuning"
    panIndicator.accessibilityIdentifier = flags.hasPanSetting ? "\(name) has pan" : "\(name) has no pan"
    gainIndicator.accessibilityIdentifier = flags.hasGainSetting ? "\(name) has gain" : "\(name) has no gain"
  }

  private func stopButtonMonitor() {
    buttonMonitor?.invalidate()
  }

  private func startButtonMonitor() {
    stopButtonMonitor()
    buttonMonitor = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.updateButton() }
  }

  override public func prepareForReuse() {
    os_log(.debug, log: log, "prepareForReuse")
    super.prepareForReuse()

    accessoryView = nil
    activeAlert = nil

    name.isHidden = false
    tagEditor.isHidden = true
    tagEditor.isEnabled = false

    tuningIndicator.isHidden = true
    panIndicator.isHidden = true
    gainIndicator.isHidden = true
  }

  private func fontColor(for flags: Flags) -> UIColor? {
    if flags.contains(.active) { return activeFontColor }
    if flags.contains(.favorite) { return favoriteFontColor }
    if flags.contains(.selected) { return selectedFontColor }
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

extension UIImageView {
  fileprivate func tint(color: UIColor) {
    self.image = self.image?.withRenderingMode(.alwaysTemplate)
    self.tintColor = color
  }
}

#if SHOW_INDEX_PATHS
extension IndexPath {
  fileprivate var prefixRow: String { "[\(row)]:"}
  fileprivate var prefixSectionRow: String { "[\(section).\(row)]:"}
}
#else
extension IndexPath {
  fileprivate var prefixRow: String { ""}
  fileprivate var prefixSectionRow: String { "" }
}
#endif

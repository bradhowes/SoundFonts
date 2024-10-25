// Copyright © 2022 Brad Howes. All rights reserved.

import UIKit
import os.log

/**
 The view controller for the table view showing the SF2 fonts that are available. The contents of this
 view come from the names of the SoundFonts collection, filtered by the active tag value managed by an
 `ActiveTagManager`. Swiping right on a row allows for editing font meta data. Swiping left on a row gives
 the user the chance to hide a built-in font or to delete a user-added one.
 */
final class FontsTableViewController: UITableViewController {
  private lazy var log = Logging.logger("FontsTableViewController")
  private let serialQueue = DispatchQueue(label: "FontsTableViewController", qos: .userInteractive, attributes: [],
                                          autoreleaseFrequency: .inherit, target: .main)
  private var selectedSoundFontManager: SelectedSoundFontManager!
  private var activePresetManager: ActivePresetManager!
  private var activeTagManager: ActiveTagManager!
  private var fontSwipeActionGenerator: FontActionManager!

  private var soundFonts: SoundFontsProvider!
  private var tags: TagsProvider!
  private var settings: Settings!

  private var bookmarkMonitor: Timer?

  private var dataSource = [SoundFont.Key]()
}

extension FontsTableViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.register(TableCell.self)
    tableView.estimatedRowHeight = 44.0
    tableView.rowHeight = UITableView.automaticDimension

    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
    longPressGesture.minimumPressDuration = 0.5
    tableView.addGestureRecognizer(longPressGesture)
  }

  @objc private func handleLongPress(_ sender: UILongPressGestureRecognizer) {
    let point = sender.location(in: tableView)
    if let indexPath = tableView.indexPathForRow(at: point),
       let cell = tableView.cellForRow(at: indexPath) as? TableCell,
       let soundFont = soundFonts.getBy(key: dataSource[indexPath.row]) {
      fontSwipeActionGenerator.beginEditingFont(at: indexPath, cell: cell, soundFont: soundFont) { done in
        if done {
          self.tableView.reloadRows(at: [indexPath], with: .none)
        }
      }
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    startBookmarkMonitor()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopBookmarkMonitor()
  }

  func activate(_ soundFontAndPreset: SoundFontAndPreset) {
    activePresetManager.setActive(preset: soundFontAndPreset, playSample: true)
  }
}

extension FontsTableViewController: ControllerConfiguration {

  func establishConnections(_ router: ComponentContainer) {
    soundFonts = router.soundFonts
    selectedSoundFontManager = router.selectedSoundFontManager
    activePresetManager = router.activePresetManager
    activeTagManager = router.activeTagManager
    tags = router.tags
    settings = router.settings
    fontSwipeActionGenerator = router.fontSwipeActionGenerator

    soundFonts.subscribe(self, notifier: soundFontsChangedNotificationInBackground)
    selectedSoundFontManager.subscribe(self, notifier: selectedSoundFontChangedNotificationInBackground)
    activePresetManager.subscribe(self, notifier: activePresetChangedNotificationInBackground)
    activeTagManager.subscribe(self, notifier: activeTagChangedNotificationInBackground)
    tags!.subscribe(self, notifier: tagsChangedNotificationInBackground)

    router.infoBar.addEventClosure(.editSoundFonts) { sender in
      if let sender = sender as? UILongPressGestureRecognizer {
        if sender.state == .began {
          let config = FontsEditorTableViewController.Config(fonts: self.soundFonts, settings: self.settings)
          guard let parent = self.parent as? SoundFontsViewController else { fatalError() }
          parent.performSegue(withIdentifier: .fontsEditor, sender: config)
        }
      }
    }

    updateTableView()
  }
}

// MARK: - UITableViewDataSource Protocol

extension FontsTableViewController {

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { dataSource.count }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    updateCell(cell: tableView.dequeueReusableCell(at: indexPath), indexPath: indexPath)
  }
}

// MARK: - UITableViewDelegate Protocol

extension FontsTableViewController {

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    UITableView.automaticDimension
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let soundFont = soundFonts.getBy(key: dataSource[indexPath.row]) else { return }
    selectedSoundFontManager.setSelected(soundFont)
  }

  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    .none
  }

  override func tableView(_ tableView: UITableView,
                          leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let cell: TableCell = tableView.cellForRow(at: indexPath) else { return nil }
    guard let soundFont = soundFonts.getBy(key: dataSource[indexPath.row]) else { return nil }
    let action = fontSwipeActionGenerator.createEditSwipeAction(at: indexPath, cell: cell, soundFont: soundFont)
    let actions = UISwipeActionsConfiguration(actions: [action])
    actions.performsFirstActionWithFullSwipe = false
    return actions
  }

  override func tableView(_ tableView: UITableView,
                          trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let cell: TableCell = tableView.cellForRow(at: indexPath) else { return nil }
    guard let soundFont = soundFonts.getBy(key: dataSource[indexPath.row]) else { return nil }
    let action: UIContextualAction = {
      switch soundFont.kind {
      case .builtin:
        return fontSwipeActionGenerator.createDeleteSwipeAction(at: indexPath, cell: cell, soundFont: soundFont)
      case .installed:
        return fontSwipeActionGenerator.createHideSwipeAction(at: indexPath, cell: cell, soundFont: soundFont)
      case .reference:
        return fontSwipeActionGenerator.createUnlinkSwipeAction(at: indexPath, cell: cell, soundFont: soundFont)
      }
    }()

    let actions = UISwipeActionsConfiguration(actions: [action])
    actions.performsFirstActionWithFullSwipe = false
    return actions
  }
}

// MARK: - Private

private extension FontsTableViewController {

  func updateBookmarkButtons() {
    for index in 0..<soundFonts.count {
      let soundFont = soundFonts.getBy(index: index)
      if soundFont.kind.reference {
        if let cell: TableCell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) {
          cell.updateBookmarkButton()
        }
      }
    }
  }

  func stopBookmarkMonitor() {
    self.bookmarkMonitor?.invalidate()
    self.bookmarkMonitor = nil
  }

  func startBookmarkMonitor() {
    stopBookmarkMonitor()
    self.bookmarkMonitor = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      self.updateBookmarkButtons()
    }
  }

  func soundFontsChangedNotificationInBackground(_ event: SoundFontsEvent) {
    os_log(.debug, log: log, "soundFontsChangedNotificationInBackground BEGIN - %{public}s", event.description)
    switch event {
    case let .added(new, soundFont):
      serialQueue.async { self.addSoundFont(index: new, soundFont: soundFont) }
    case let .moved(old, new, soundFont):
      serialQueue.async { self.movedSoundFont(oldIndex: old, newIndex: new, soundFont: soundFont) }
    case let .removed(old, deletedSoundFont):
      serialQueue.async { self.removeSoundFont(index: old, soundFont: deletedSoundFont) }
    case .presetChanged: break
    case .unhidPresets: break
    case .restored:
      serialQueue.async { self.updateTableView() }
    }
  }

  func selectedSoundFontChangedNotificationInBackground(_ event: SelectedSoundFontEvent) {
    os_log(.debug, log: log, "selectedSoundFontChangedNotificationInBackground BEGIN - %{public}s", event.description)
    if case let .changed(old: old, new: new) = event {
      serialQueue.async { self.handleFontChanged(old: old, new: new) }
    }
  }

  func activePresetChangedNotificationInBackground(_ event: ActivePresetEvent) {
    os_log(.debug, log: log, "activePresetChangedNotificationInBackground BEGIN - %{public}s", event.description)
    switch event {
    case let .changed(old: old, new: new, playSample: _):
      serialQueue.async { self.handlePresetChanged(old: old, new: new) }
    case .loaded:
      break
    }
  }

  func activeTagChangedNotificationInBackground(_ event: ActiveTagEvent) {
    os_log(.debug, log: log, "activeTagChangedNotificationInBackground BEGIN - %{public}s", event.description)
    switch event {
    case let .change(old: old, new: new):
      serialQueue.async { self.handleActiveTagChanged(old: old, new: new) }
    }
  }

  func tagsChangedNotificationInBackground(_ event: TagsEvent) {
    os_log(.debug, log: log, "tagsChangedNotificationInBackground BEGIN - %{public}s", event.description)
    if case let .removed(_, tag) = event {
      serialQueue.async { self.handleTagRemoved(tag) }
    }
  }

  func handleTagRemoved(_ tag: Tag) {
    self.soundFonts.removeTag(tag.key)
    self.updateTableView()
  }

  func handleActiveTagChanged(old: Tag?, new: Tag) {
    updateTableView()
  }

  func updateTableView() {
    os_log(.debug, log: log, "updateTableView BEGIN")
    guard tags.isRestored && soundFonts.isRestored else {
      os_log(.debug, log: log, "updateTableView END - not restored yet")
      return
    }

    dataSource = soundFonts.filtered(by: activeTagManager.activeTag.key)
    os_log(.debug, log: log, "updateTableView - dataSource: %{public}s", dataSource.description)
    os_log(.debug, log: log, "updateTableView - names: %{public}s", soundFonts.names(of: dataSource).description)

    tableView.reloadData()
  }

  func handlePresetChanged(old: ActivePresetKind, new: ActivePresetKind) {
    os_log(.debug, log: log, "handlePresetChanged BEGIN - old: %{public}s new: %{public}s", old.description,
           new.description)

    if old.soundFontAndPreset?.soundFontKey != new.soundFontAndPreset?.soundFontKey {
      os_log(.debug, log: log, "handlePresetChanged - font key differs")
      if let key = old.soundFontAndPreset?.soundFontKey {
        let row = dataSource.firstIndex(of: key)
        os_log(.debug, log: log, "handlePresetChanged - updating old row")
        updateRow(row: row)
      }

      if let soundFontAndPreset = new.soundFontAndPreset {
        let key = soundFontAndPreset.soundFontKey
        if let row = dataSource.firstIndex(of: key) {
          os_log(.debug, log: log, "handlePresetChanged - updating new row")
          updateRow(row: row)
        }
        if let soundFont = activePresetManager.resolveToSoundFont(soundFontAndPreset) {
          os_log(.debug, log: log, "handlePresetChanged - selecting font")
          selectedSoundFontManager.setSelected(soundFont)
        } else {
          os_log(.debug, log: log, "handlePresetChanged - clearing font")
          selectedSoundFontManager.clearSelected()
        }
      }
    }
    os_log(.debug, log: log, "handlePresetChanged END")
  }

  func handleFontChanged(old: SoundFont.Key?, new: SoundFont.Key?) {
    if let key = old, let row = dataSource.firstIndex(of: key) {
      updateRow(row: row)
    }

    if let key = new, let row = dataSource.firstIndex(of: key) {
      updateRow(row: row)
      selectAndShow(row: row)
    }
  }

  func indexFilteredByActiveTag(_ index: Int) -> Int {
    soundFonts.indexFilteredByTag(index: index, tag: activeTagManager.activeTag.key)
  }

  func addSoundFont(index: Int, soundFont: SoundFont) {
    let filteredIndex = indexFilteredByActiveTag(index)
    guard filteredIndex >= 0 else { return }
    tableView.performBatchUpdates {
      dataSource.insert(soundFont.key, at: filteredIndex)
      tableView.insertRows(at: [filteredIndex.indexPath], with: .automatic)
    } completion: { completed in
      if completed {
        self.selectedSoundFontManager.setSelected(soundFont)
        self.selectAndShow(row: filteredIndex)
      }
    }
  }

  func movedSoundFont(oldIndex: Int, newIndex: Int, soundFont: SoundFont) {
    let oldFilteredIndex = indexFilteredByActiveTag(oldIndex)
    guard oldFilteredIndex >= 0 else { return }
    let newFilteredIndex = indexFilteredByActiveTag(newIndex)
    guard newFilteredIndex >= 0 else { return }
    tableView.performBatchUpdates {
      dataSource.insert(dataSource.remove(at: oldFilteredIndex), at: newFilteredIndex)
      tableView.moveRow(at: oldFilteredIndex.indexPath, to: newFilteredIndex.indexPath)
    } completion: { completed in
      if completed {
        self.updateRow(row: newFilteredIndex)
        if self.selectedSoundFontManager.selected == soundFont.key {
          self.selectAndShow(row: newFilteredIndex)
        }
      }
    }
  }

  func removeSoundFont(index: Int, soundFont: SoundFont) {
    let filteredIndex = indexFilteredByActiveTag(index)
    guard filteredIndex >= 0 else { return }
    tableView.performBatchUpdates {
      dataSource.remove(at: filteredIndex)
      tableView.deleteRows(at: [filteredIndex.indexPath], with: .automatic)
    } completion: { _ in
      let newRow = min(filteredIndex, self.dataSource.count - 1)
      guard newRow >= 0 else {
        self.selectedSoundFontManager.clearSelected()
        return
      }

      guard let newSoundFont = self.soundFonts.getBy(key: self.dataSource[newRow]) else {
        return
      }

      if self.activePresetManager.activeSoundFont == soundFont {
        self.activePresetManager.setActive(preset: .init(soundFontKey: newSoundFont.key,
                                                         soundFontName: newSoundFont.originalDisplayName,
                                                         presetIndex: 0,
                                                         itemName: newSoundFont.presets[0].presetConfig.name),
                                           playSample: false)
        self.selectedSoundFontManager.setSelected(newSoundFont)
      } else if self.selectedSoundFontManager.selected == soundFont.key {
        self.selectedSoundFontManager.setSelected(newSoundFont)
      }

      self.selectAndShow(row: newRow)
    }
  }

  func selectAndShow(row: Int) {
    tableView.performBatchUpdates {
      self.tableView.selectRow(at: row.indexPath, animated: true, scrollPosition: .none)
    } completion: { _ in
      self.tableView.scrollToRow(at: row.indexPath, at: .none, animated: true)
    }
  }

  func updateRow(row: Int?) {
    guard let row = row else { return }
    os_log(.debug, log: log, "updateRow - %d", row)
    if let cell: TableCell = tableView.cellForRow(at: row.indexPath) {
      updateCell(cell: cell, indexPath: row.indexPath)
    }
  }

  @discardableResult
  func updateCell(cell: TableCell, indexPath: IndexPath) -> TableCell {
    let key = dataSource[indexPath.row]
    guard let soundFont = soundFonts.getBy(key: key) else { fatalError("data out of sync") }
    os_log(.debug, log: log, "updateCell - font '%{public}s' %d", soundFont.displayName, indexPath.row)
    var flags: TableCell.Flags = .init()
    if selectedSoundFontManager.selected == soundFont.key { flags.insert(.selected) }
    if activePresetManager.activeSoundFontKey == soundFont.key { flags.insert(.active) }
    cell.updateForFont(at: indexPath, name: soundFont.displayName, kind: soundFont.kind, flags: flags)
    return cell
  }
}

fileprivate extension Int {
  /// Sugar to create an IndexPath from a row value.
  var indexPath: IndexPath { IndexPath(row: self, section: 0) }
}

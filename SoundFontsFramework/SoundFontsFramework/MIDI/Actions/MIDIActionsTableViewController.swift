// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI
import MorkAndMIDI

/**
 A table view that shows the assignments of SoundFont actions to MIDI controllers.
 */
final class MIDIActionsTableViewController: UITableViewController {
  private var midiEventRouter: MIDIEventRouter!
  private var monitorToken: NotificationObserver?
  private var learning: Bool = false

  func configure(midiEventRouter: MIDIEventRouter) {
    self.midiEventRouter = midiEventRouter
  }
}

// MARK: - View Management

extension MIDIActionsTableViewController {

  override public func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(MIDIActionsTableCell.self)
    tableView.registerHeaderFooter(MIDIActionsTableHeaderView.self)
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    monitorToken = MIDIEventRouter.monitorControllerActivity { [weak self] payload in
      guard let self = self else { return }
      if self.learning {
        print(payload.controller, payload.value)
        self.learning = false
      }
    }
  }

  override public func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    monitorToken?.forget()
    monitorToken = nil
  }
}

// MARK: - Table View Methods

extension MIDIActionsTableViewController {

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view: MIDIActionsTableHeaderView = tableView.dequeueReusableHeaderFooterView()
    return view
  }

  override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    MIDIControllerAction.allCases.count
  }

  override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: MIDIActionsTableCell = tableView.dequeueReusableCell(at: indexPath)
    let action = MIDIControllerAction.allCases[indexPath.row]

    cell.name.text = action.displayName

    return cell
  }
}

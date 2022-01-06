// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation
import UIKit
import os.log

extension UIDocument.State {
  var description: String {
    switch self {
    case .normal: return "normal"
    case .closed: return "closed"
    case .inConflict: return "inConflict"
    case .savingError: return "savingError"
    case .editingDisabled: return "editingDisabled"
    case .progressAvailable: return "progressAvailable"
    default: return "unknown"
    }
  }
}

class ConfigFileConflictMonitor: NSObject {
  private let log = Logging.logger("ConfigFileConflictMonitor")

  weak var configFile: ConsolidatedConfigFile?

  init(configFile: ConsolidatedConfigFile) {
    self.configFile = configFile
    super.init()
    NotificationCenter.default.addObserver(self, selector: #selector(processStateChange(_:)),
                                           name: UIDocument.stateChangedNotification, object: configFile)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc func processStateChange(_ notification: Notification) {
    os_log(.info, log: log, "processStateChange: %{public}s", configFile?.documentState.description ?? "NA")
  }
}

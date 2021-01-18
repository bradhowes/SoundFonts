// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

public final class TagsTableViewController: UITableViewController {
    private lazy var log = Logging.logger("TagsTVM")

    public struct Config {
        let tags: [String]
        let completionHandler: ((Bool) -> Void)?
    }

    private var viewManager: TagsTableViewManager!
    private var completionHandler: ((Bool) -> Void)?

    override public func viewDidLoad() {
        viewManager = TagsTableViewManager(view: tableView)
    }

    func configure(_ config: Config) {
        self.completionHandler = config.completionHandler
    }
}

//
//  TableHeaderView.swift
//  SoundFontsFramework
//
//  Created by Brad Howes on 01/04/2023.
//  Copyright © 2023 Brad Howes. All rights reserved.
//

import UIKit

final public class MIDIConnectionsTableHeaderView: UITableViewHeaderFooterView, ReusableView, NibLoadableView {
  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var connected: UILabel!
}

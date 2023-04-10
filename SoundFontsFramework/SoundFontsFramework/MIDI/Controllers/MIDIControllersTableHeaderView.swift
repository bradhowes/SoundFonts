//
//  TableHeaderView.swift
//  SoundFontsFramework
//
//  Created by Brad Howes on 01/04/2023.
//  Copyright © 2023 Brad Howes. All rights reserved.
//

import UIKit

final public class MIDIControllersTableHeaderView: UITableViewHeaderFooterView, ReusableView, NibLoadableView {
  @IBOutlet var stackView: UIStackView!
  @IBOutlet weak var identifier: UILabel!
  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var value: UILabel!
  @IBOutlet weak var used: UILabel!
}

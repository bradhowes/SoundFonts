//
//  PatchesTableView.swift
//  SoundFontsFramework
//
//  Created by Brad Howes on 31/5/21.
//  Copyright © 2021 Brad Howes. All rights reserved.
//

import UIKit

public final class PatchesTableView: UITableView {

  public typealias OneShotLayoutCompletionHandler = (() -> Void)
  public var oneShotLayoutCompletionHandler: OneShotLayoutCompletionHandler?

  override public func layoutSubviews() {
    super.layoutSubviews()
    oneShotLayoutCompletionHandler?()
    oneShotLayoutCompletionHandler = nil
  }
}

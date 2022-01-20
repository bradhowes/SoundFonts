//
//  TagsVisibilityManager.swift
//  SoundFontsFramework
//
//  Created by Brad Howes on 20/01/2022.
//  Copyright © 2022 Brad Howes. All rights reserved.
//

import UIKit

/**
 Controls visibility of the tags table view.
 */
struct TagsVisibilityManager {

  private let tagsBottomConstraint: NSLayoutConstraint
  private let tagsViewHeightConstraint: NSLayoutConstraint
  private let fontsView: UIView
  private let containerView: UIView
  private let tagsTableViewController: TagsTableViewController
  private let infoBar: InfoBar
  private let maxTagsViewHeightConstraint: CGFloat

  /**
   Construct new instance

   - parameter tagsBottomConstraint: constraint that controls where the tags view bottom resides
   - parameter tagsViewHeightConstrain: constraint that controls the height of the tags view
   - parameter fontsView: the view showing the fonts
   - parameter containerView: the container view that shows the fonts and tags
   - parameter tagsTableViewController: the view controller for the tags table
   - parameter infoBar: the InfoBar that holds the button used to show/hide the tags table
   */
  init(tagsBottonConstraint: NSLayoutConstraint, tagsViewHeightConstrain: NSLayoutConstraint, fontsView: UIView,
       containerView: UIView, tagsTableViewController: TagsTableViewController, infoBar: InfoBar) {
    self.tagsBottomConstraint = tagsBottonConstraint
    self.tagsViewHeightConstraint = tagsViewHeightConstrain
    self.fontsView = fontsView
    self.containerView = containerView
    self.tagsTableViewController = tagsTableViewController
    self.infoBar = infoBar
    self.maxTagsViewHeightConstraint = tagsViewHeightConstraint.constant

    infoBar.addEventClosure(.showTags, self.toggleShowTags)
  }

  /// True when the tags view is visible
  var showingTags: Bool { tagsBottomConstraint.constant == 0.0 }

  /**
   Toggle the visibility of the tags table

   - parameter sender: the object that sent the request
   */
  func toggleShowTags(_ sender: AnyObject) {
    let button = sender as? UIButton
    if tagsBottomConstraint.constant == 0.0 {
      hideTags()
    } else {
      button?.tintColor = .systemOrange
      showTags()
    }
  }

  /**
   Show the tags table view
   */
  public func showTags() {
    guard !showingTags else { return }
    let maxHeight = fontsView.frame.height - 8
    let midHeight = maxHeight / 2.0
    let minHeight = CGFloat(120.0)

    var bestHeight = midHeight
    if bestHeight > maxHeight { bestHeight = maxHeight }
    if bestHeight < minHeight { bestHeight = maxHeight }

    tagsViewHeightConstraint.constant = bestHeight
    tagsBottomConstraint.constant = 0.0

    UIViewPropertyAnimator.runningPropertyAnimator(
      withDuration: 0.25,
      delay: 0.0,
      options: [.allowUserInteraction, .curveEaseIn],
      animations: {
        self.containerView.layoutIfNeeded()
        self.tagsTableViewController.scrollToActiveRow()
      }, completion: { _ in })
  }

  /**
   Hide the tags table view
   */
  public func hideTags() {
    guard showingTags else { return }
    infoBar.resetButtonState(.showTags)
    tagsViewHeightConstraint.constant = maxTagsViewHeightConstraint
    tagsBottomConstraint.constant = tagsViewHeightConstraint.constant + 8
    UIViewPropertyAnimator.runningPropertyAnimator(
      withDuration: 0.25, delay: 0.0,
      options: [.allowUserInteraction, .curveEaseOut],
      animations: self.containerView.layoutIfNeeded,
      completion: nil
    )
  }

}

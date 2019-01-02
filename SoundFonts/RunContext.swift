//
//  RunContext.swift
//  SoundFonts
//
//  Created by Brad Howes on 12/26/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import UIKit

/**
 Collection of UIViewControllers and protocol facades which helps establish inter-controller relationships during the
 application launch. Each view controller is responsible for establishing the connections in their
 `establishConnections` method. The goal should be to have relations between a controller and protocols / facades, and
 not between controllers themselves. This is enforced here through access restrictions to known controllers.
 */
final class RunContext {

    private var mainViewController: MainViewController! {
        didSet { oneTimeSet(oldValue) }
    }

    private var soundFontPatchesController: SoundFontPatchesViewController! {
        didSet { oneTimeSet(oldValue) }
    }

    var activeSoundFontManager: ActiveSoundFontManager { return soundFontPatchesController }
    var activePatchManager: ActivePatchManager { return soundFontPatchesController }

    private var favoritesController: FavoritesViewController! {
        didSet { oneTimeSet(oldValue) }
    }

    var favoritesManager: FavoritesManager { return favoritesController }

    private var infoBarController: InfoBarController! {
        didSet { oneTimeSet(oldValue) }
    }

    var infoBarManager: InfoBarManager { return infoBarController }

    private var keyboardController: KeyboardController! {
        didSet { oneTimeSet(oldValue) }
    }

    var keyboardManager: KeyboardManager { return keyboardController }

    /**
     Collect the known view controllers and track what we have.
    
     - parameter mvc: the sole MainViewController instances
     - parameter vcs: collection of other instances
     */
    func addViewControllers(_ mvc: MainViewController, _ vcs: [UIViewController]) {
        mainViewController = mvc
        for obj in vcs {
            switch obj {
            case let vc as SoundFontPatchesViewController: soundFontPatchesController = vc
            case let vc as FavoritesViewController: favoritesController = vc
            case let vc as InfoBarController: infoBarController = vc
            case let vc as KeyboardController: keyboardController = vc
            default: assertionFailure("unknown child UIViewController")
            }
        }

        validate()
    }

    /**
     Invoke `establishConnections` on each tracked view controller.
     */
    func establishConnections() {
        mainViewController.establishConnections(self)
        soundFontPatchesController.establishConnections(self)
        favoritesController.establishConnections(self)
        infoBarController.establishConnections(self)
        keyboardController.establishConnections(self)
    }
    
    private func validate() {
        precondition(mainViewController != nil, "nil MainViewController")
        precondition(soundFontPatchesController != nil, "nil SoundFontPatchesViewController")
        precondition(favoritesController != nil, "nil FavoritesViewController")
        precondition(infoBarController != nil, "nil InfoBarController")
        precondition(keyboardController != nil, "nil KeyboardController")
    }
    
    private func oneTimeSet(_ oldValue: UIViewController?) {
        if let _ = oldValue {
            preconditionFailure("expected nil value")
        }
    }
}

let runContext = RunContext()

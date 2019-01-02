//
//  ViewController.swift
//  SoundFonts
//
//  Created by Brad Howes on 11/1/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import UIKit

extension SettingKeys {
    static let showingFavorites = SettingKey<Bool>("showingFavorites", defaultValue: false)
}

/**
 Top-level view controller for the application.
 */
final class MainViewController: UIViewController {
    
    @IBOutlet private weak var patches: UIView!
    @IBOutlet private weak var favorites: UIView!

    private lazy var sampler = Sampler(patch: SoundFont.library[SoundFont.keys.first!]!.patches.first!)

    private var upperViewManager = UpperViewManager()
    private weak var infoBarManager: InfoBarManager!
    private weak var favoritesManager: FavoritesManager!
    private weak var keyboardManager: KeyboardManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        upperViewManager.add(view: patches)
        upperViewManager.add(view: favorites)
        runContext.addViewControllers(self, children)
        runContext.establishConnections()
    }
}

// MARK: - Controller Configuration
extension MainViewController: ControllerConfiguration {
    func establishConnections(_ context: RunContext) {
        infoBarManager = context.infoBarManager
        favoritesManager = context.favoritesManager
        keyboardManager = context.keyboardManager
        keyboardManager.delegate = self

        context.activePatchManager.addPatchChangeNotifier { patch in self.selected(patch: patch) }
        context.favoritesManager.addFavoriteChangeNotifier { favorite in self.selected(favorite: favorite) }

        infoBarManager.addTarget(.swipeLeft, target: self, action: #selector(showNextConfigurationView))
        infoBarManager.addTarget(.swipeRight, target: self, action: #selector(showPreviousConfigurationView))

        let showingFavorites = Settings[.showingFavorites]
        self.patches.isHidden = showingFavorites
        self.favorites.isHidden = !showingFavorites
    }

    private func selected(patch: Patch) {
        keyboardManager.releaseAllKeys()
        infoBarManager.setPatchInfo(name: patch.name, isFavored: favoritesManager.isFavored(patch: patch))
        sampler.load(patch: patch)
        Settings[.activeSoundFont] = patch.soundFont.name
        Settings[.activePatch] = patch.index
    }
    
    private func selected(favorite: Favorite) {
        // The patch will be applied above -- just do favorite-specific settings here
        sampler.setGain(favorite.gain)
        sampler.setPan(favorite.pan)
    }

    @IBAction private func showNextConfigurationView() {
        let showingFavorites = favorites.isHidden
        Settings[.showingFavorites] = showingFavorites
        self.upperViewManager.slideNextHorizontally()
    }
    
    @IBAction private func showPreviousConfigurationView() {
        let showingFavorites = favorites.isHidden
        Settings[.showingFavorites] = showingFavorites
        self.upperViewManager.slidePrevHorizontally()
    }
}

// MARK: - KeyboardManagerDelegate protocol
extension MainViewController : KeyboardManagerDelegate {
    func noteOn(_ note: Note) {
        infoBarManager.setStatus(note.label + " - " + note.solfege)
        sampler.noteOn(note.midiNoteValue)
    }
    
    func noteOff(_ note: Note) {
        sampler.noteOff(note.midiNoteValue)
    }
}

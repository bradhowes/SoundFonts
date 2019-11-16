//
//  ViewController.swift
//  SoundFonts
//
//  Created by Brad Howes on 11/1/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import UIKit
import AVKit

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

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { return [.left, .right, .bottom] }

    private var volume: Float = 0.0 {
        didSet {
            KeyboardRender.isMuted = isMuted
        }
    }
    private var muted = false {
        didSet {
            KeyboardRender.isMuted = isMuted
        }
    }

    private var isMuted: Bool { volume < 0.01 || muted }

    private struct Observation {
        static let VolumeKey = "outputVolume"
        static var Context = 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        upperViewManager.add(view: patches)
        upperViewManager.add(view: favorites)
        runContext.addViewControllers(self, children)
        runContext.establishConnections()

        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }

    override func viewDidAppear(_ animated: Bool) {
        Mute.shared.notify = {muted in self.muted = muted }

        let session = AVAudioSession.sharedInstance()
        session.addObserver(self, forKeyPath: Observation.VolumeKey, options: [.initial, .new],
                            context: &Observation.Context)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if context == &Observation.Context {
            if keyPath == Observation.VolumeKey, let volume = (change?[NSKeyValueChangeKey.newKey] as? NSNumber)?.floatValue {
                self.volume = volume
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: Observation.VolumeKey, context: &Observation.Context)
    }
}

// MARK: - Controller Configuration

extension MainViewController: ControllerConfiguration {

    func establishConnections(_ context: RunContext) {
        infoBarManager = context.infoBarManager

        let activePatchManager = context.activePatchManager
        let favoritesManager = context.favoritesManager
        let patchesManager = context.patchesManager
        let keyboardManager = context.keyboardManager

        keyboardManager.delegate = self

        activePatchManager.addPatchChangeNotifier(self) { observer, patch in
            keyboardManager.releaseAllKeys()
            self.infoBarManager.setPatchInfo(name: patch.name, isFavored: favoritesManager.isFavored(patch: patch))
            self.sampler.load(patch: patch)
            Settings[.activeSoundFont] = patch.soundFont.name
            Settings[.activePatch] = patch.index
        }

        favoritesManager.addFavoriteChangeNotifier(self) { observer, kind, favorite in
            if favorite.patch == activePatchManager.activePatch {
                self.sampler.setGain(favorite.gain)
                self.sampler.setPan(favorite.pan)
                let patch = favorite.patch
                self.infoBarManager.setPatchInfo(name: patch.name, isFavored: favoritesManager.isFavored(patch: patch))
            }
        }
        
        infoBarManager.addTarget(.doubleTap, target: self, action: #selector(showNextConfigurationView))

        let showingFavorites = Settings[.showingFavorites]
        self.patches.isHidden = showingFavorites
        self.favorites.isHidden = !showingFavorites

        patchesManager.addTarget(.swipeLeft, target: self, action: #selector(showNextConfigurationView))
        patchesManager.addTarget(.swipeRight, target: self, action: #selector(showPreviousConfigurationView))

        favoritesManager.addTarget(.swipeLeft, target: self, action: #selector(showNextConfigurationView))
        favoritesManager.addTarget(.swipeRight, target: self, action: #selector(showPreviousConfigurationView))
    }

    @IBAction func showNextConfigurationView() {
        let showingFavorites = favorites.isHidden
        Settings[.showingFavorites] = showingFavorites
        self.upperViewManager.slideNextHorizontally()
    }
    
    @IBAction func showPreviousConfigurationView() {
        let showingFavorites = favorites.isHidden
        Settings[.showingFavorites] = showingFavorites
        self.upperViewManager.slidePrevHorizontally()
    }
}

// MARK: - KeyboardManagerDelegate protocol
extension MainViewController : KeyboardManagerDelegate {

    func noteOn(_ note: Note) {
        if isMuted {
            infoBarManager.setStatus("🔇")
        }
        else {
            infoBarManager.setStatus(note.label + " - " + note.solfege)
            sampler.noteOn(note.midiNoteValue)
        }
    }
    
    func noteOff(_ note: Note) {
        sampler.noteOff(note.midiNoteValue)
    }
}

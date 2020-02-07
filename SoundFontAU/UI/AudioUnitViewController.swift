// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework

public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    let sampler = Sampler(mode: .audiounit)
    var audioUnit: AUAudioUnit { return sampler.auAudioUnit }
    let components = Components<AudioUnitViewController>()

    var activePatchManager: ActivePatchManager!
    var infoBar: InfoBar!

    public override func viewDidLoad() {
        super.viewDidLoad()
        components.addMainController(self)
    }
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {

        // audioUnit = try SoundFontAUAudioUnit(componentDescription: componentDescription, options: [])

        _ = sampler.start()
        return audioUnit
    }
}

// MARK: - Controller Configuration

extension AudioUnitViewController: ControllerConfiguration {

    /**
     Establish connections with other managers / controllers.

     - parameter context: the RunContext that holds all of the registered managers / controllers
     */
    public func establishConnections(_ router: ComponentContainer) {
        activePatchManager = router.activePatchManager
        infoBar = router.infoBar
        activePatchManager.subscribe(self, closure: activePatchChange)
        router.favorites.subscribe(self, closure: favoritesChange)
        useActivePatchKind(activePatchManager.active)
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        if case let .active(old: _, new: new) = event {
            useActivePatchKind(new)
        }
    }

    private func favoritesChange(_ event: FavoritesEvent) {
        switch event {
        case let .added(index: _, favorite: favorite): updateInfoBar(with: favorite)
        case let .changed(index: _, favorite: favorite): updateInfoBar(with: favorite)
        case let .removed(index: _, favorite: favorite, bySwiping: _): updateInfoBar(with: favorite.soundFontPatch)
        default: break
        }
    }

    private func updateInfoBar(with favorite: Favorite) {
        if favorite.soundFontPatch == activePatchManager.soundFontPatch {
            infoBar.setPatchInfo(name: favorite.name, isFavored: true)
        }
    }

    private func updateInfoBar(with soundFontPatch: SoundFontPatch) {
        if soundFontPatch == activePatchManager.soundFontPatch {
            infoBar.setPatchInfo(name: soundFontPatch.patch.name, isFavored: false)
        }
    }

    private func useActivePatchKind(_ activePatchKind: ActivePatchKind) {

        if let favorite = activePatchKind.favorite {
            infoBar.setPatchInfo(name: favorite.name, isFavored: true)
        }
        else {
            infoBar.setPatchInfo(name: activePatchKind.soundFontPatch.patch.name, isFavored: false)
        }

        _ = self.sampler.load(activePatchKind: activePatchKind)
    }
}

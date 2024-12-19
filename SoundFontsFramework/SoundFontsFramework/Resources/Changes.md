Note to self: this file is used to record the major changes made between versions.
It is parsed by `ChangesCompiler.compile` to build up a collection of items to show to the user.
The parsing is really simplistic:

- if a line begins with '# ' then it must contain a version string.
- always put most-recent changes at the top of the file (versions in descending order)
- if a line begins with '* ' then it is a change entry to show to the user. The change *must* be all on one line (keep it short and sweet)

# 2.30.4

* Fixed crash in AUv3 component when host app moved to background
* Eliminate race conditions involving configuration file loading and saving
* Validated fixes in AUM, Cubasis, and GarageBand hosts using multiple instances of SoundFonts

# 2.30.3

* Fixed crash due to accessing configuration information before config file was loaded
* Fixed crash due to invalid assumption when saving configuration file

# 2.30.2

* Fixed restoration of SF2 files store on iCloud

# 2.30.1

* Fixed crash on iOS 18

NOTE: there is a known issue where the app and AUv3 extension will fail if the SF2 file is on an iCloud Drive but needs
to be downloaded. Best option is to tell iOS to keep them downloaded using the Files app.

# 2.30.0

* Fixed alert title that was missing localization entry
* Fixed improper note playing when keyboard is movable
* Improved restoration of AUv3 component. Tested in GarageBand, AUM, and Cubasis 3 with 3 and 4 SoundFonts instances in
a file.

# 2.29.2

* Revert back to MIDI v1.0 processing due to issues with stuck notes.

# 2.29.1

* Fix access to font files on external drive after device restart. Thanks to Eduard for alerting me to the problem.
* Minor UI fixes.

# 2.29.0

* Additional MIDI controller labels
* Updates to MID Devices view in Settings panel
* Show MIDI channel of last incoming message
* Allow fix-velocity notes per MIDI connection
* New MIDI Assignments view in Settings panel
* Assign MIDI change controller (CC) to predefined app actions
* Allow changing of favorites via assigned MIDI CC
* Allow changing of effect settings via assigned MIDI CC

# 2.28.0

* Use MorkAndMIDI Swift package for all MIDI processing
* Using MIDI v2.0 in CoreMIDI API when available
* New MIDI controller display in Settings view
* Individual MIDI controller input can be now be disabled

# 2.27.4

* Simplify shift A4 behavior.
* Fix reporting of channel info in connection view
* New controls to manage MIDI device connections
* New control to auto-connect to new MIDI devices

# 2.27.3

* Restore support for macOS Catalyst, including AUv3 access in GarageBand.
* Cosmetic improvements for AUv3 interface.
* Fix crash in app running on macOS when GarageBand starts SoundFonts AUv3 component.

# 2.27.2

* Allow MIDI processing and audio generation while app is in background.
* Long-press on effects button or active preset name in info bar to stop all playing notes.

# 2.27.1

* Rename the previous "transpose" control to more accurately describe the effect as a shift of the A4 frequency.

# 2.27.0

* The app now honors the MIDI channel. A MIDI activity indicator in the info bar above the
  keyboard blinks BLUE when MIDI affects the synth and ORANGE if not. There is also an indicator 
  in the Settings panel.
* New transpose control in Settings panel (global) and per-preset in the Preset editor (swipe right and tap pencil to 
  view).
* Show "Changes" screen when starting new version. You can always bring it back up via a button at the bottom of the
  Settings panel.

# 2.26.1

* Fixed improper deletion of referenced files
* Minor UI improvements to the font removal screen

# 2.26.0

* Long-press on ⨁ to bulk remove fonts

# 2.25.0

* Stop all notes before changing preset and prevent note playing until engine is ready

# 2.24.0

* Allow adding font via openURL API

# 2.21.3

* Reduced screen updates for presets
* Reduced startup time
* Removed check for "silent mode" switch

# 2.21.0

* Pitch bend range can now be set, both globally and per preset.

Note to self: this file is used to record the major changes made between versions.
It is parsed by `ChangesCompiler.compile` to build up a collection of items to show to the user.
The parsing is really simplistic:

- if a line begins with '# ' then it must contain a version string. This will be compared to the version last seen by the user to determine when
to stop processing the file
- because of how the processing works, always put most-recent changes at the top of the file (versions in descending order)
- if a line begins with '* ' then it is a change entry to show to the user. The change *must* be all on one line (keep it short and sweet)

# 2.27.0

* The app now honors the MIDI channel for all MIDI traffic. MIDI activity while viewing the Settings panel will cause 
  GREEN flashing over the MIDI devices label
  if incoming MIDI traffic is on the configured MIDI channel; it will flash YELLOW otherwise, meaning that MIDI messages
  will be ignored by the synthesizer.

* New transpose control in Settings panel (global) and per-preset in the Preset editor (swipe right and tap pencil to 
  view).
* Show "Changes" screen when starting new version.

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

# 1.0.0

* One
* Two
* Three
* Four
* Five
* Six
* Seven
* Eight
* Nine
* Ten



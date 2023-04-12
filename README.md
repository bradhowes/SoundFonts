[![CI](https://github.com/bradhowes/SoundFonts/workflows/CI/badge.svg)](https://github.com/bradhowes/SoundFonts)
[![Swift 5.4](https://img.shields.io/badge/Swift-5.4-orange.svg?style=flat)](https://swift.org)
[![AUv3](https://img.shields.io/badge/AU-v3-green.svg)](https://github.com/bradhowes/SoundFonts)
[![License: MIT](https://img.shields.io/badge/License-MIT-A31F34.svg)](https://opensource.org/licenses/MIT)

# SoundFonts App

🥳 [Check it out on Apple's App Store](https://apps.apple.com/us/app/soundfonts/id1453325077)

<p align="center">
<img src="https://github.com/bradhowes/SoundFonts/blob/main/images/landscape.png?raw=true" alt="App shown in landscape orientation on iPhone"/>
</p>

This is an iOS / macOS application that acts as a polyphonic synthesizer. It uses
an `AVAudioUnitSampler` instance to generate the sounds for touched keys. The sounds that are available come from
_sound font_ files such as those available [online](http://www.synthfont.com/links_to_soundfonts.html) for free
(and of variable quality). There are four sound font files that are bundled with the application, and more can
be added via the iCloud integration.

<p align="center">
<img src="https://github.com/bradhowes/SoundFonts/blob/main/images/portrait.png?raw=true" alt="App shown in portrait orientation on iPhone"/>
</p>

> NOTE: AVAudioUnitSampler can and will crash if the SoundFont preset it is using for rendering does not conform
> to spec. Unfortunately, there is no way to insulate the app from this so it too will crash along with
> AVAudioUnitSampler.

I have also curated a small collection of SoundFont files that I found useful and/or interesting: [Sample
SoundFonts](https://keystrokecountdown.com/extras/SoundFonts/index.html). If you visit the site from your iOS
device and touch one of the links, you can add the fire directly to the SoundFonts application.

Here are some additional sites that have curated or custom SF2 files that should work with the application:

* [Soundfonts 4u](https://sites.google.com/site/soundfonts4u/)
* [Les Productions Zvon](https://lesproductionszvon.com/freesounds.htm)

# Recent Changes

## 2.29.1

* Fix access to font files on external drive after device restart. Thanks to Eduard for alerting me to the problem.
* Minor UI fixes.

## 2.29.0

* Additional MIDI controller labels
* Updates to MID Devices view in Settings panel
* Show MIDI channel of last incoming message
* Allow fix-velocity notes per MIDI connection
* New MIDI Assignments view in Settings panel
* Assign MIDI change controller (CC) to predefined app actions
* Allow changing of favorites via assigned MIDI CC
* Allow changing of effect settings via assigned MIDI CC

## 2.28.0

* Use [MorkAndMIDI](https://github.com/bradhowes/morkandmidi) Swift package for all MIDI processing
* Using MIDI v2.0 in CoreMIDI API when available
* New MIDI controller display in Settings view
* Individual MIDI controller input can be now be disabled

## AUv3 App Extensions

Starting with v2.0, the application now contains an AUv3 app extension that can be loaded by other music
applications that support AUv3 audio units, such as
[GarageBand](https://apps.apple.com/us/app/garageband/id408709785) and
[AUM](https://apps.apple.com/app/id1055636344).

<p align="center">
<img src="https://github.com/bradhowes/SoundFonts/blob/main/images/AUM.png?raw=true" alt="AUM hosting SoundFonts AUv3 component"/>
</p>

And here are 4 instances running in GarageBand:

<p align="center">
<img src="https://github.com/bradhowes/SoundFonts/blob/main/images/GarageBand.png?raw=true" alt="GarageBand hosting SoundFonts AUv3 component"/>
</p>

Here is a rendering straight from GarageBand: <a href="https://github.com/bradhowes/SoundFonts/blob/main/media/Rendering.m4a?raw=true">Rendering.m4a</a>
</p>

The app also includes two AUv3 effects: reverb, and delay. You can use them directly in the application, or add
them to your signal processing chain in an AUv3 host such as AUM.

<p align="center">
<img src="https://github.com/bradhowes/SoundFonts/blob/main/images/effects.png?raw=true" alt="App effects controls"/>
</p>

I have additional AUv3 effects available here and on the AppStore:

- [Simply Flange](https://github.com/bradhowes/SimplyFlange) -- a simple flange effect
- [Simply Tremolo](https://github.com/bradhowes/SimplyTremolo) -- a simple tremolo effect
- [Simply Phaser](https://github.com/bradhowes/SimplyPhaser) -- a simple phaser effect

## User Interface

There is a bar between the list views and the keyboard. This is called the "info bar" since it shows the name of the current preset. It is also the
location for most of the controls for the app. On smaller devices, some of the control buttons are hidden until revealed by touching the unfilled
triangle at the far right of the bar. Below is an image of the additional controls that appear:

<p align="center">
<img src="https://github.com/bradhowes/SoundFonts/blob/main/images/infobar.png?raw=true" alt="SoundFonts info bar"/>
</p>

Here are some of the features available:

* Switch between the presets view (image above) and a _favorites_ view (see below) by swiping left/right on the upper view with two touches.
* Double-tapping the preset name in the info bar above the keyboard will also switch the upper view
* You can touch the labels at either end of the black bar to change the range of the keyboard. In the image
  above, the first key is at "C4" and the last key shown is "G5". You can go as low as "C0" and as high as "C9".
* You can also swipe with a finger on back bar to change the keyboard range
* Swipe right on a preset name to make it a favorite (same to unfavorite). Favorited presets have a star next to
  their name. You can also swipe to edit or hide a preset.
* Add/Remove sound font files. In the "presets view" press the "+" button to bring up a file picker. Locate a sound font file
  to add from a location on your device, or from your iCloud drive or Google Drive. Added files can be removed via a
  left-swipe on the sound font name.
* Adjust visibility of individual presets either by a swipe or as a whole via the "list" button.

## Notes on Adding From Cloud Drives

* __Files app (iCloud)__ — long-press on the file you want to import, select "Share" option. You should then be able to select "Copy to SoundFonts"
from the sharing sheet that appears.

* __Google Drive__ — touch the "•••" button next to the file name and then choose "Open in" from the list of available options. You
should then be able to select "Copy to SoundFonts" from the sharing sheet that appears.

* __Dropbox__ —  touch on the circled "•••" button below the file you want to import. Choose "Copy Link" option that appears. Select "Open In…"
and then "Copy to SoundFonts" from the sharing sheet that appears.

Unfortunately as far as I can tell there is no way to import directly from a web page with a native SF2 URL link. One must first have the file available on
a cloud drive before it can be imported via the iOS sharing sheet.

## Favorites

Double-tapping on the info bar switches between the fonts view and the the "favorites". This view shows all of the presets that have been
"faved" or "starred". Pressing on a favorite will make its associated preset active. You can also reorder them by long-touching one and
moving it to a new location among the others. There are various parameters one can adjust for a favorite that remain independent of the
original preset it derived from. These include:

<p align="center">
<img src="https://github.com/bradhowes/SoundFonts/blob/main/images/favorite.png?raw=true" alt="Favorite configuration editor"/>
</p>

- the first note of the keyboard when the favorite becomes active
- a custom tuning to apply
- pitch bend range
- custom gain
- custom stereo panning
- reverb and delay settings (app only)

Also, you can have more than one favorite for the same preset, each with its own collection of settings.

## Tags

You can create custom "tags" and assign them to sound fonts in your collection. Selecting a tag acts as a filter, only showing the sound fonts
are a member of the active tag. This can be an easy and effective way to organize your sound fonts files by categories or even by performance
or song.

## Settings

There are a variety of customization settings available.

<p align="center">
<img src="https://github.com/bradhowes/SoundFonts/blob/main/images/settings.png?raw=true" alt="Settings configuration editor"/>
</p>

The app supports MIDI connectivity via direct wired connection or via Bluetooth MIDI.

You can also control how the app adds new SF2 files. By default, the app will copy the SF2 file into the app's sandbox. This is the safest since
it guarantees that the app will always be able to locate and use the file. However, it does take up additional space on your device. Disabling
the "Copy SF2 files when adding" option means the app will instead obtain a secure bookmark reference to the file's location. This can be
somewhere else on your device -- including the Files app for iCloud files -- or on a supported external USB storage device. However, these
files may not always be available. Hopefully the code does the right thing in these situations, but the secure bookmarking API is not exactly
intuitive and clear on all points. That said, it appears to work great for me so far with my devices and iCloud and I have also tested it using an
external USB drive without any issues so far.

## Importing and Exporting App Configuration

The Settings panel above provides a way to export the existing app configuration to a location outside of the app's private sandbox. You can
visit this location using the Files app, selecting "On My…" location, and scrolling to find the folder for SoundFonts. The exported configuration
files all end with "plist" extension (there are currently three of them). The export operation will also make copies of any  installed SF2 files. You
can replicate a SoundFonts setup on another device by simply copying everything that is exported to the SoundFonts folder on the new
device and then choose "Import all SF2 files…" action in the Settings panel.

## Dependencies

There are no external dependencies. I wrote the code in Xcode 10.1, targeting iOS 12.1. The Xcode version has increased as has the Swift
version, but it still works on iOS 12.1 devices.

The keys of the keyboard are painted by the code found in `KeyboardRender.swift`. This was generated by the
[PaintCode](https://www.paintcodeapp.com) application. The PaintCode file is `Keyboard.pcvd`, but it is not part
of the build process and PaintCode is not necessary to build.

## Embedded Sound Fonts

The repository comes with four SoundFont files, though the largest one -- `FluidR3_GM` -- is too large to store
natively on Github so it has been broken into three files: `FluidR3_GM.sf2.1`, `FluidR3_GM.sf2.2`, and
`FluidR3_GM.sf2.3`. I could move it to LFS but I do not want to mess with that. Instead, I have an Xcode build
phaase that should concatenate the individual files into one big one before packaging them all up into a
resource in the SF2Files target.

# API Documentation

If you are interested, there is some [developer documentation](https://bradhowes.github.io/SoundFonts/)
available.

## Code Guide

The application and the three AUv3 app extensions are found in the
[SoundFontsApp](https://github.com/bradhowes/SoundFonts/tree/main/SoundFontsApp/SoundFontsApp) folder. There you will find:

* [App](https://github.com/bradhowes/SoundFonts/tree/main/SoundFontsApp/SoundFontsApp/App) -- the application code and resources
* [DelayAU](https://github.com/bradhowes/SoundFonts/tree/main/SoundFontsApp/SoundFontsApp/DelayAU) -- the AUv3 component for the
delay effect that you can use in an AUv3 host app
* [ReverbAU](https://github.com/bradhowes/SoundFonts/tree/main/SoundFontsApp/SoundFontsApp/ReverbAU) -- the AUv3 component
for the reverb effect that you can use in an AUv3 host app
* [SoundFontsAU](https://github.com/bradhowes/SoundFonts/tree/main/SoundFontsApp/SoundFontsApp/SoundFontsAU) -- the AUv3
component for the SoundFonts instrument that lets you use SoundFonts functionality in an AUv3 host app such as AUM.

The app and the AUv3 app extensions share code via the
[SoundFontsFramework](https://github.com/bradhowes/SoundFonts/tree/main/SoundFontsFramework) framework. This holds most of the UI
definitions and nearly all of the SF2 handling code. This is all in Swift.

Parsing SF2 files is done in an Objective-C framework with C++ code that represents entities defined the in the SoundFont v2 specification.
It is called [SoundFontInfoLib](https://github.com/bradhowes/SoundFonts/tree/main/SoundFontInfoLib). Its original purpose was to provide
a fast way to extract the preset information from an SF2 file, but it has grown to understand all of the components in the SoundFont v2 spec.
There is also the beginnings of my own custom SF2 audio rendering facility which will one day replace SoundFonts' dependency on
Apple's own AVAudioUnitSampler.

Finally, the embedded SF2 files that come with the app in the App Store are packaged up in the
[SF2Files](https://github.com/bradhowes/SoundFonts/tree/main/SF2Files) framework. As mentioned above, there is special-handling of the
FluidR3_GM SF2 file which is performed in a custom build phase for this framework. It does nothing more than concatenate the three parts
together to make a whole SF2 file which the build system then puts into the framework.

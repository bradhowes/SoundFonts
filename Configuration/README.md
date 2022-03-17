# Configuration

This directory contains three [Xcode config](https://nshipster.com/xcconfig/) files that are used to setup
certain build variables and some entries in the various Info.plist files that help define the frameworks and
AUv3 app extensions. The `Common.xcconfig` file holds the common settings, all having to do with configuring the
audio unit component that is embedded in the macOS and iOS app extensions. The `Dev.xcconfig` and
`Staging.xcconfig` files include the `Common.xcconfig` and then define their own customizations.

Here are the elements in the `Common.xcconfig` and their reason for being:

* AU_BASE_NAME (LPF) — defines the display name for bundles; app extensions will have " AUv3" appended to it
* AU_COMPONENT_NAME (B-Ray: Low-pass) — defines the audio unit component name which by convention is made up of
  the manufacturer name and the audio unit name separated by a ':'
* AU_COMPONENT_TYPE (aufx) — the value for the `componentType` attribute in the `AudioComponentDescription`
  object. The value `aufx` indicates an audio effects unit.
* AU_COMPONENT_SUBTYPE (lpas) — the value for the `componentSubType` attribute in the
  `AudioComponentDescription` object.
* AU_COMPONENT_MANUFACTURER (BRay) — the value for the `componentManufacturer` attribute in the
  `AudioComponentDescription` object. This is the unique identifier for the entity that is distributing the
  audio unit, and according to Apple it cannot be all lower-case.
* AU_FACTORY_FUNCTION (LowPassFilterFramework.FilterViewController) — identifies the bundle path to the entity
  that derives from `AUAudioUnitFactory` protocol for creating new audio unit entities from an
  `AudioComponentDescription`

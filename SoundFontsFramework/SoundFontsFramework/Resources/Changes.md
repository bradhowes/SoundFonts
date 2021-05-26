Note to self: this file is used to record the major changes made between versions. It is parsed by `ChangesCompiler.compile` to build up
a collection of items to show to the user. The parsing is really simplistic:

- if a line begins with '# ' then it must contain a version string. This will be compared to the version last seen by the user to determine when
to stop processing the file
- because of how the processing works, always put most-recent changes at the top of the file (versions in descending order)
- if a line begins with '* ' then it is a change entry to show to the user. The change *must* be all on one line (keep it short and sweet)

# 2.20.2

* Reduced screen updates for presets
* Reduced startup time
* Removed check for "silent mode" switch

#  2.21.0

* Pitch bend range can now be set, both globally and per preset.


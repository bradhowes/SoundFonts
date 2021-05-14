#!/bin/bash

set -x

OUTPUT="./docs/swift"
rm -rf "${OUTPUT}"
mkdir -p "${OUTPUT}"
cp -r images "${OUTPUT}"

# SoundFontsFramework documentation
sourcekitten doc \
             --module-name SoundFontsFramework \
             -- \
             -workspace SoundFonts.xcworkspace \
             -scheme App \
             -destination name='iPhone 11' \
             > /tmp/docs_SoundFontsFramework.json

# App documentation
sourcekitten doc \
             -- \
             -workspace SoundFonts.xcworkspace \
             -scheme App \
             -destination name='iPhone 11' \
             > /tmp/docs_app.json


# Generate HTML from documentation content
jazzy --output "${OUTPUT}" \
      --min-acl internal \
      --sourcekitten-sourcefile /tmp/docs_SoundFontsFramework.json,/tmp/docs_app.json \
      -g https://github.com/bradhowes/SoundFonts \
      -a "Brad Howes" \
      -u https://linkedin.com/in/bradhowes \
      --module-version $(bumpVersions -v)

# Generate C++ documentation
rm -rf docs/cpp
doxygen SoundFontInfoLib/Doxygen.config

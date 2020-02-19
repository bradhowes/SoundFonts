#!/bin/bash

set -x
rm -rf ./docs
mkdir ./docs
cp *.gif *.png docs/

# xcodebuild -workspace SoundFonts.xcworkspace -scheme SoundFonts

JAZZY=$(type -p jazzy)

${JAZZY} --sdk iphoneos \
         --swift-build-tool xcodebuild \
         --min-acl internal \
         -g https://github.com/bradhowes/SoundFonts \
         -a "Brad Howes" \
         -u https://linkedin.com/in/bradhowes \
         -b -workspace,SoundFonts.xcworkspace,-scheme,SoundFontsFramework \
         -m SoundFontsFramework --module-version 2.0

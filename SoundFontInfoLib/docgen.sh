#!/bin/bash

set -x

rm -rf ./docs/*

JAZZY=$(type -p jazzy)

${JAZZY} --min-acl internal \
         --swift-build-tool xcodebuild \
         -b -workspace,../SoundFonts.xcworkspace,-scheme,SoundFontInfoLib \
         -m SoundFontInfoLib --module-version 2.3.8

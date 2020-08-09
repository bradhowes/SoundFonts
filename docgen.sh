#!/bin/bash

set -x

rm -rf ./docs/*
# mkdir ./docs
cp images/* docs/

# xcodebuild -workspace SoundFonts.xcworkspace -scheme App

JAZZY=$(type -p jazzy)

${JAZZY} --sdk iphoneos \
         --min-acl internal \
         --swift-build-tool xcodebuild \
         -b -sdk,iphoneos,-workspace,SoundFonts.xcworkspace,-scheme,SoundFontsFramework \
         -g https://github.com/bradhowes/SoundFonts \
         -a "Brad Howes" \
         -u https://linkedin.com/in/bradhowes \
         -m SoundFontsFramework --module-version 2.3.8

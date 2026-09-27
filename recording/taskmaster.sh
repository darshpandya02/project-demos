#!/usr/bin/env bash
# Session: TaskMaster (Android) JVM unit tests, then the instrumented suite on an
# Android 14 emulator. Run from the root of a taskmaster-android checkout with
# JAVA_HOME (JDK 17) and ANDROID_HOME set, and the emulator already booted.
set -u
source "$(dirname "$0")/lib.sh"
PROMPT_DIR="taskmaster-android"
clear

note "JVM unit tests: repository, ViewModels, backup codec and manager, date text (fakes for the DAO and scheduler)"
run './gradlew :app:testDebugUnitTest --console=plain --rerun-tasks -q'
run 'python3 scripts/test-summary.py unit'

note "instrumented tests on the Android 14 arm64 emulator: Room DAO, WorkManager + notifications, SAF backup, Espresso"
run 'export ANDROID_SERIAL=emulator-5554'
run 'adb shell getprop ro.build.version.release'
note "remove the release build left from the screen recording (it is signed with a different key than the test build)"
run 'adb uninstall com.darshpandya.taskmaster'
run './gradlew :app:connectedDebugAndroidTest --console=plain -q'
run 'python3 scripts/test-summary.py connected'

note "the release APK attached to the GitHub release, and its signing certificate (a throwaway key, not in the repo)"
run 'ls -l app/build/outputs/apk/release/app-release.apk'
run '$ANDROID_HOME/build-tools/36.0.0/apksigner verify --print-certs app/build/outputs/apk/release/app-release.apk | head -2'

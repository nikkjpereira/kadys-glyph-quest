#!/usr/bin/env bash
set -euo pipefail
APK="build/kadys-glyph-quest-v0.2.0-debug.apk"
echo "Android install diagnostic: $(adb shell getprop ro.build.version.release) / API $(adb shell getprop ro.build.version.sdk)"
echo "Emulator ABI: $(adb shell getprop ro.product.cpu.abilist)"
echo "APK size: $(wc -c < "$APK")"
echo "--- DOWNLOAD EXACT RELEASE APK ---"
EXACT="build/kadys-glyph-quest-v0.2.0-released-arm64.apk"
curl --fail --location --retry 3 --silent --show-error -o "$EXACT" "https://github.com/nikkjpereira/kadys-glyph-quest/releases/download/v0.2.0/kadys-glyph-quest-v0.2.0-debug.apk"
test -s "$EXACT"
echo "Official released APK: $(wc -c < "$EXACT") bytes"
echo "--- INSTALL EXACT RELEASE APK ---"
if adb install --no-incremental "$EXACT"; then
  echo "EXACT_RELEASE_RESULT=SUCCESS"
  adb shell pm path com.nefariousmedia.kadysglyphquest
  adb uninstall com.nefariousmedia.kadysglyphquest
else
  echo "EXACT_RELEASE_RESULT=FAILURE"
  adb logcat -d -t 800 -v time | grep -Ei 'PackageInstaller|PackageManager|install_failed|No certificates|Signature|parse failed|INSTALL_PARSE|ApkSignature|ParsingPackage' | tail -100 || true
  exit 1
fi
echo "--- INSTALL ATTEMPT ---"
if adb install --no-incremental "$APK"; then
  echo "INSTALL_RESULT=SUCCESS"
else
  echo "INSTALL_RESULT=FAILURE"
  echo "--- LAST PACKAGE INSTALL DIAGNOSTICS ---"
  adb logcat -d -t 500 -v time | grep -Ei 'PackageInstaller|PackageManager|install_failed|No certificates|Signature|parse failed|INSTALL_PARSE|ApkSignature|ParsingPackage' | tail -100 || true
  exit 1
fi
echo "--- PACKAGE MANAGER CHECK ---"
adb shell pm path com.nefariousmedia.kadysglyphquest
adb shell cmd package resolve-activity --brief com.nefariousmedia.kadysglyphquest || true
echo "Installation passed on emulator."
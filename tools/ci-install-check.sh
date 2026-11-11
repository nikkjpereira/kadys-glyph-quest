#!/usr/bin/env bash
set -euo pipefail
APK="build/kadys-glyph-quest-v0.2.0-debug.apk"
echo "Android install diagnostic: $(adb shell getprop ro.build.version.release) / API $(adb shell getprop ro.build.version.sdk)"
echo "Emulator ABI: $(adb shell getprop ro.product.cpu.abilist)"
echo "APK size: $(wc -c < "$APK")"
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

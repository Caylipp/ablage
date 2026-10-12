#!/bin/sh
# Baut die native App (v2) inkl. Tastatur als IPA für SideStore/AltStore/Xcode-Sideloading.
# Ad-hoc signiert MIT Entitlements: SideStore liest daraus die App Group und signiert neu.
# Ergebnis: dist/Ablage-native.ipa
set -eu
cd "$(dirname "$0")/../native"
xcodegen generate >/dev/null
xcodebuild -project Ablage.xcodeproj -scheme Ablage -configuration Release -sdk iphoneos \
  -destination 'generic/platform=iOS' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build \
  | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" || true

APP=build/Build/Products/Release-iphoneos/Ablage.app
[ -d "$APP/PlugIns/AblageKeyboard.appex" ] || { echo "Build fehlgeschlagen: $APP oder Tastatur fehlt" >&2; exit 1; }

codesign -f -s - --entitlements Keyboard/AblageKeyboard.entitlements "$APP/PlugIns/AblageKeyboard.appex"
codesign -f -s - --entitlements App/Ablage.entitlements "$APP"

OUT=../dist
rm -rf "$OUT/ipa" && mkdir -p "$OUT/ipa/Payload"
cp -R "$APP" "$OUT/ipa/Payload/"
(cd "$OUT/ipa" && rm -f ../Ablage-native.ipa && zip -qry ../Ablage-native.ipa Payload)
rm -rf "$OUT/ipa"
echo "Fertig: dist/Ablage-native.ipa ($(du -h "$OUT/Ablage-native.ipa" | cut -f1))"

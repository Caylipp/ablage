#!/bin/sh
# Baut eine unsignierte iOS-IPA (Release) – z. B. für LiveContainer, SideStore oder AltStore.
# Diese signieren die App beim Import selbst. Ergebnis: dist/Ablage.ipa
set -eu
cd "$(dirname "$0")/.."

npx expo prebuild --platform ios --no-install >/dev/null
(cd ios && pod install >/dev/null)

xcodebuild \
  -workspace ios/Ablage.xcworkspace \
  -scheme Ablage \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath ios/build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" || true

APP=ios/build/Build/Products/Release-iphoneos/Ablage.app
[ -d "$APP" ] || { echo "Build fehlgeschlagen: $APP fehlt" >&2; exit 1; }

rm -rf dist/ipa && mkdir -p dist/ipa/Payload
cp -R "$APP" dist/ipa/Payload/
(cd dist/ipa && zip -qry ../Ablage.ipa Payload)
rm -rf dist/ipa
# ZIP-Variante für AirDrop: Eine nackte IPA würde iOS selbst zu installieren versuchen.
(cd dist && rm -f Ablage.ipa.zip && zip -q Ablage.ipa.zip Ablage.ipa)
echo "Fertig: dist/Ablage.ipa ($(du -h dist/Ablage.ipa | cut -f1)) und dist/Ablage.ipa.zip"

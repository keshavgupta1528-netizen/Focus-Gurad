#!/usr/bin/env bash
# Builds FocusGuard into app-release.apk. Run on Mac/Linux (or Windows via WSL/Git Bash).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/app"

command -v flutter >/dev/null || { echo "Install Flutter first: https://docs.flutter.dev/get-started/install"; exit 1; }
command -v keytool >/dev/null || { echo "keytool not found. Install JDK 17 (Android Studio bundles one)."; exit 1; }

# 1) Generate a clean Flutter Android project once
if [ ! -d "$APP" ]; then
  flutter create --org com.focusguard --project-name focusguard --platforms android "$APP"
fi

# 2) Lay our source over it
rm -rf "$APP/lib" "$APP/test" "$APP/android/app/src/main/kotlin" \
       "$APP/android/app/build.gradle" "$APP/android/app/build.gradle.kts"
cp -R "$ROOT/overlay/." "$APP/"

# 3) Create a local signing key once (BACK UP android/focusguard-release.jks)
KS="$APP/android/focusguard-release.jks"
if [ ! -f "$KS" ]; then
  keytool -genkeypair -keystore "$KS" -alias focusguard -keyalg RSA -keysize 2048 \
    -validity 10000 -storepass focusguard123 -keypass focusguard123 \
    -dname "CN=FocusGuard, O=FocusGuard, C=US"
fi
cat > "$APP/android/key.properties" <<PROPS
storeFile=focusguard-release.jks
storePassword=focusguard123
keyAlias=focusguard
keyPassword=focusguard123
PROPS

# 4) Build
cd "$APP"
flutter pub get
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk "$ROOT/app-release.apk"
echo "Done: $ROOT/app-release.apk"

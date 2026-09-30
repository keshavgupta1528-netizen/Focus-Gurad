# FocusGuard (steps 1-2: setup + Focus Engine)

## Build
1. Install Flutter (stable) and JDK 17, plus the Android SDK (Android Studio does this).
2. Run `flutter doctor` and fix anything it flags.
3. In this folder run: `./build_apk.sh`
4. Copy `app-release.apk` to your phone and open it (allow "install unknown apps").

Manual commands if you prefer: `flutter create --org com.focusguard --project-name focusguard --platforms android app`,
copy `overlay/` over `app/` (delete `app/android/app/build.gradle.kts` and the generated Kotlin folder first),
then `cd app && flutter pub get && flutter build apk --release`.

## Included so far
- Dark glass theme, swipe paging (Focus <-> Tasks)
- Draggable timer dial (5-180m) with haptics + spring knob
- Foreground timer service, survives app close and reboot, completion notification
- Confetti on session complete
- Full manifest with every permission, ProGuard release config

## Next steps
3: app picker, usage monitoring, overlay, hold/math unlock. 4: tasks, gestures, alarms. 5: widget.

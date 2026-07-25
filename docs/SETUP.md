# MyLibrary — Setup

## Prerequisites
- Flutter SDK (stable channel)
- Android Studio / Xcode for platform builds
- A physical device recommended for TTS testing (see IMPLEMENTATION_PLAN.md)

## First-time setup

```bash
flutter pub get

# Required: generates lib/objectbox.g.dart and objectbox-model.json
# from the @Entity() classes in lib/models/. This repo does not
# commit generated code — run this before first build and again
# any time a model in lib/models/ changes.
dart run build_runner build --delete-conflicting-outputs
```

## Android
`android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```
ObjectBox ships native `.so` libraries via `objectbox_flutter_libs` —
no manual NDK config needed for standard builds.

## iOS
`ios/Podfile`:
```ruby
platform :ios, '13.0'
```
Run `cd ios && pod install` after `flutter pub get`.

## Running
```bash
flutter run
```

## Regenerating after model changes
Any time you add/edit a field on `Book`, `Genre`, or `Bookmark`:
```bash
dart run build_runner build --delete-conflicting-outputs
```
ObjectBox migrates the local schema automatically on next app launch
for additive changes (new fields/entities). Renames/removals need the
`@Id(assignable: true)` / uid annotations described in ObjectBox docs
if you need to preserve existing user data across the change.

## Verifying zero network dependency
Turn on airplane mode and run the full import -> read -> TTS flow.
Nothing in this app should require connectivity at any point.

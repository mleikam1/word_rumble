# Word Rumble

A Flutter and Flame arcade word game for touch and mouse. Play a three-stop physics campaign, practice five-letter deductions, or take the daily puzzle. The menus, hints, results and shop use the same round and profile state as the game board.

## Run locally

Open the folder containing this file in Android Studio or VS Code. This project was developed with Flutter 3.29.2, Dart 3.7.2 and the committed dependency lockfile.

```sh
flutter pub get
flutter run -d chrome
```

Use `flutter devices` and `flutter run -d <device-id>` to select a mobile target. Native development requires the corresponding Android or iOS toolchain. Use `flutter test` for the widget, gameplay and persistence tests.

## Interface

[Screen flow, visual assets and extension points](docs/ui/interface.md) · [Underlying gameplay and physics audit](docs/gameplay/audit.md)

Production purchases and live ads are deferred. The shop buys inventory with coins earned from campaign wins. The default mobile identifiers and debug signing configuration are development settings.

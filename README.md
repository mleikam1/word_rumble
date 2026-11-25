# Word Rumble

An arcade word game built with Flutter and Flame for touch and mouse. The seven-round Campaign starts on a rocking dock in Splash Bay. Grab a letter, steady it over a numbered berth and release. The word banks when its last letter settles before the clock expires.

The atlas tracks clears and best medals across Splash Bay, Lava Core and Wind Peak. Legacy Word Guess and Daily Rumble keep their deduction rules and existing local profile records. A physics-based Daily is deferred.

## Run locally

Use Flutter 3.29.2, Dart 3.7.2 and the committed dependency lockfile.

```sh
flutter pub get
flutter run -d chrome
```

Use `flutter devices` to find a connected mobile target. To run the game there, pass its ID to `flutter run -d`.

## Verify gameplay

```sh
flutter analyze
flutter test
flutter test -d <device-id> --reporter expanded integration_test/native_gameplay_test.dart
```

The native integration test opens the campaign through the app, drags tiles through the Flutter hit-test tree and reads the resulting board. Boot an Android emulator or iOS simulator before selecting its ID. The native workflow also supports a manual CI run.

The Chrome harness builds a separate QA entry point with read-only board geometry. The driver sends touch events through Chrome DevTools Protocol. Use Node.js 22 or later and a fresh Chrome profile. The driver clears the test origin’s local storage before each run.

1. Build and serve the QA app.

   ```sh
   flutter build web --no-web-resources-cdn -t tool/browser_qa.dart
   python3 -m http.server 19449 --bind 127.0.0.1 --directory build/web
   ```

2. In another terminal, start Chrome with a temporary profile. This command uses the standard macOS installation.

   ```sh
   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
     --headless=new --remote-debugging-port=19448 \
     --user-data-dir="$(mktemp -d)" about:blank
   ```

   On Linux, use the local Chrome executable with the same arguments.

3. Run the chapter driver from a third terminal. It writes screenshots into the supplied capture directory.

   ```sh
   node tool/chrome_touch_qa.mjs http://127.0.0.1:19449 19448 build/qa-captures 390 844 chapter
   ```

For the regular web build, use `flutter build web --no-web-resources-cdn`.

## Project notes

[Campaign rules, level values and interface](docs/ui/interface.md) · [Historical audit of the earlier three-stop campaign](docs/gameplay/audit.md)

The shop uses coins earned from campaign wins. Production purchases and live ads are deferred. Native identifiers and signing are configured for development.

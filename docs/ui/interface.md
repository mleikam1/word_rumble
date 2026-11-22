# Word Rumble UI handoff

The root tabs are **Play**, **Worlds**, **Shop** and **Settings**. A wallet shortcut opens the shop. The profile button opens the player passport. The game board stays mounted when players inspect their guess history, pause, adjust settings or visit the shop.

## Navigation and state

| Entry | What the player sees | Actions and destinations |
| --- | --- | --- |
| Play | Current campaign destination, Word Guess, Daily Rumble, atlas progress | Open the next level briefing, either puzzle lobby, the field guide, or the atlas |
| Worlds | Three playable locations and a Zero-G Station preview | Inspect a level and its unlock condition. Clear its predecessor to play |
| Level briefing | Destination art, target, timer, decoys, physics tip and reward | Play level, read the guide, or go back |
| Campaign | Visible target, top timer, balance, interactive Flame board and bottom tools | Drop individual tiles into slots. Winning awards coins and opens the next level |
| Word Guess | Practice lobby and six-guess round | Build and submit five-letter words. View guess history and inspect exact, present and absent clues |
| Daily Rumble | Dated lobby, one local attempt and a finished-day recap | One start per UTC day per local profile. Leaving ends the attempt. Practice remains available afterward |
| Pause | Frozen round clock | Resume, change settings or confirm leaving |
| Campaign results | Solved word and actual payout, or timeout and answer | Advance, replay, visit the shop or return to Play. After a timeout, one paid extension preserves the board |
| Word Guess results | Answer and submitted guesses | Replay the same puzzle or start a new one. Daily results close that day’s attempt |
| Shop | Coin balance, power-up inventory, costs and purchase confirmation | Buy a use with earned coins. A shortage explains the amount needed. Real-money packs are unavailable |
| Passport | Campaign wins, daily wins, balance and collected world stamps | View each destination’s briefing |
| Settings | Sound feedback, haptics, reduced decorative motion, additional clue symbols | Preferences persist on this device. Gameplay physics still carry information about each world |
| Field guide | Instructions for each mode, an example scored guess and the four power-ups | Switch between Campaign and Rumble rules |
| About & local data | Local storage policy and license viewer | Inspect licenses or confirm a local reset from root Settings. Settings opened mid-round omits reset |

## Round values

| Campaign level | Word | Clock | Decoys | Win |
| --- | --- | --- | --- | --- |
| Splash Bay | WATER | 30 s | 2 | 5 coins |
| Lava Core | FIRE | 25 s | 3 | 6 coins |
| Wind Peak | STORM | 35 s | 4 | 8 coins |

Word Guess uses the existing **WATERSOLL** physical rack, a 30-second clock, the bundled offline dictionary and a 12-answer pool. Duplicate-letter evaluation uses exact matches first. Daily uses a fixed mapping from the UTC date to that same answer pool. It cycles every 12 days. The daily limit is local to one profile and clears when local progress is reset.

Hint costs 10 coins. Freeze costs 20 coins for five seconds. Campaign-only Clear costs 20 coins and removes up to three loose decoys. Shuffle is free and preserves slotted tiles. Stored uses are consumed before coins. A Campaign timeout allows one 10-second extension for 10 coins; Retry is free.

## Visual system

Travel-poster illustrations distinguish locations. Ink outlines and cream tiles make the active board readable over the art. Gold marks the primary play action and currency, lavender identifies practice, and a clock stamp identifies the daily puzzle. Barlow Condensed ExtraBold supplies headline lettering and DM Sans supplies labels and body copy. Their licenses are bundled and accessible from Settings.

| Component or data | Entry point |
| --- | --- |
| Typography, colors, wordmark, wallet, card elements | `lib/ui/style.dart` |
| Root tabs, mode cards and player passport | `lib/ui/main_menu_page.dart` |
| Atlas, world illustrations and level briefing | `lib/ui/screens/worlds.dart`, `assets/art/` |
| Daily selection, availability and practice | `lib/ui/screens/rumble_lobby.dart` |
| Shop, settings, local reset, rules and licenses | `lib/ui/screens/support_screens.dart` |
| Arena host, app backgrounding and navigation | `lib/ui/game_page.dart` |
| Controls, timer, history and post-round actions | `lib/game/overlays/` |
| Slot ownership, release rules, physics and scoring | `lib/game/word_rumble_game.dart`, `lib/game/components/` |
| Level content, dictionary and store supplies | `lib/data/`, `assets/words/` |
| Device profile, guarded spending and queued saves | `lib/core/game_state.dart` |

## Adding another playable world

Add its level to `LevelRepository.campaignLevels`, reference a defined theme, and register its illustration and input tip in `WorldPoster.all`. The atlas reads the configured levels, the briefing uses that level’s timer/reward/decoy count, and winning unlocks the next entry in repository order. Add and play-test a concrete level before turning an upcoming destination into a play action.

## Checks

`flutter analyze`, `flutter test` and `flutter build web --no-web-resources-cdn` cover the Flutter source and web build. Tests exercise physical tile releases, duplicate feedback, permission to continue, single-charge spending, pause and resume, rotation, the shop and device profile restoration. The downloadable screen atlas uses real rendered widgets, including seeded round or wallet states for some examples.

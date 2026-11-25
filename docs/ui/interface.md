# Word Rumble UI handoff

The root tabs are **Play**, **Worlds**, **Shop** and **Settings**. A wallet shortcut opens the shop. The profile button opens the player passport. Campaign opens first. The board stays mounted during pause and settings. Deduction rounds also retain their guess history.

## Navigation and state

| Entry | What the player sees | Actions and destinations |
| --- | --- | --- |
| Play | Current campaign destination, legacy practice and Daily, atlas progress | Open the next level briefing, either puzzle lobby, the field guide, or the atlas |
| Worlds | Seven numbered stops grouped under three illustrated worlds and a Zero-G preview | Inspect a stop, replay a clear or unlock the next stop |
| Level briefing | Destination art, target, timer, decoys, physics tip and reward | Play level, read the guide, or go back |
| Campaign | Spelling objective, countdown, hazard signal, pause and a reserved feedback line | Catch a loose letter, aim for the numbered berth and release when the check appears |
| Word Guess | Practice lobby and six-guess round | Build and submit five-letter words. View guess history and inspect exact, present and absent clues |
| Daily Rumble | Dated lobby, one local attempt and a finished-day recap | One start per UTC day per local profile. Leaving ends the attempt. Practice remains available afterward |
| Pause | Frozen clock and field | Resume, restart, use a Campaign supply, open settings or confirm leaving |
| Campaign results | Solved word, medal, world reaction and coin payout, or timeout and answer | Advance, replay or return to Play. A single paid extension can reopen a timed-out attempt |
| Word Guess results | Answer and submitted guesses | Replay the same puzzle or start a new one. Daily results close that day’s attempt |
| Shop | Coin balance, power-up inventory, costs and purchase confirmation | Buy a use with earned coins. A shortage explains the amount needed. Real-money packs are unavailable |
| Passport | Campaign wins, daily wins, balance and collected world stamps | View each destination’s briefing |
| Settings | Sound feedback, haptics, reduced decorative motion, additional clue symbols | Preferences persist on this device. Gameplay physics still carry information about each world |
| Field guide | Instructions for each mode, an example scored guess and the four power-ups | Switch between Campaign and Rumble rules |
| About & local data | Local storage policy and license viewer | Inspect licenses or confirm a local reset from root Settings. Settings opened mid-round omits reset |

## Round values

| Atlas stop | Stable save ID | World | Word | Seconds | Extra tile | Win | Swift cutoff |
| ---: | ---: | --- | --- | ---: | --- | ---: | ---: |
| 1 | 1 | Splash Bay | WATER | 35 | S | 5 coins | 12 s |
| 2 | 4 | Splash Bay | SHIP | 35 | A | 5 coins | 12 s |
| 3 | 5 | Splash Bay | BUOY | 35 | S | 5 coins | 12 s |
| 4 | 2 | Lava Core | FIRE | 25 | A | 6 coins | 7 s |
| 5 | 6 | Lava Core | EMBER | 30 | A | 6 coins | 9 s |
| 6 | 7 | Wind Peak | GUST | 35 | A | 7 coins | 11 s |
| 7 | 3 | Wind Peak | STORM | 35 | A | 8 coins | 10 s |

Each berth has a number and letter. Crossing it with a tile in hand keeps the tile free. The check means its center and relative speed are within the current landing window. Releasing on the check reserves the berth, then latches the tile after a quarter second. An occupied berth rejects the drop. A failed edit returns its tile to its original berth. Drag a latched tile to **Return tile** to open that berth. A wrong full word stays editable.

WATER introduces the dock. SHIP adds a marked swell and BUOY narrows the landing window. FIRE and EMBER have glowing vents and a calm interval between puffs. Each E in EMBER is a separate physical tile. GUST uses a wind signal and moving berths. STORM sends a pair of opposing gusts in an eight-second cycle. Each gust gets a 1.2-second warning. The first burst gives way to a 0.9-second calm before the second warning, followed by a longer recovery after the second burst. Retry restores the same seeded setup.

A successful round earns its configured coins on every play. The Swift medal requires at least the listed time left. Clean adds zero misses and zero assists to the Swift requirement. The profile keeps the best medal by permanent ID. Players with an earlier WATER or FIRE clear retain access to their previously unlocked destinations.

Word Guess uses the existing **WATERSOLL** physical rack, a 30-second clock, the bundled offline dictionary and a 12-answer pool. Duplicate-letter evaluation uses exact matches first. Daily uses a fixed mapping from the UTC date to that same answer pool. It cycles every 12 days. The daily limit is local to one profile and clears when local progress is reset.

Hint costs 10 coins. It identifies a landing in Campaign and places a correct letter in legacy deduction play. Freeze costs 20 coins for five seconds. Campaign-only Clear costs 20 coins and removes up to three loose decoys. Shuffle is free and preserves slotted tiles. Stored uses are consumed before coins. A Campaign timeout allows one 10-second extension for 10 coins. Retry is free.

## Visual system

Travel-poster illustrations distinguish locations. Ink outlines and cream tiles make the active board readable over the art. Gold marks the primary play action and currency, lavender identifies practice, and a clock stamp identifies the daily puzzle. Barlow Condensed ExtraBold supplies headline lettering and DM Sans supplies labels and body copy. Their licenses are bundled and accessible from Settings.

| Component or data | Entry point |
| --- | --- |
| Typography, colors, wordmark, wallet, card elements | `lib/ui/style.dart` |
| Root tabs, mode cards and player passport | `lib/ui/main_menu_page.dart` |
| Atlas, world illustrations and level briefing | `lib/ui/screens/worlds.dart`, `assets/art/` |
| Daily selection, availability and practice | `lib/ui/screens/rumble_lobby.dart` |
| Shop, settings, local reset, rules and licenses | `lib/ui/screens/support_screens.dart` |
| Raw pointer input, arena host, backgrounding and navigation | `lib/ui/game_page.dart` |
| Fixed Campaign HUD, legacy deduction history and results | `lib/game/overlays/` |
| Landing evaluation, berth ownership, motion and scoring | `lib/game/landing.dart`, `lib/game/campaign_round.dart`, `lib/game/word_rumble_game.dart`, `lib/game/components/` |
| Level content, dictionary and store supplies | `lib/data/`, `assets/words/` |
| Device profile, guarded spending and queued saves | `lib/core/game_state.dart` |

## Adding another playable world

Give the level a permanent ID and an explicit prerequisite ID. Configure its target and exact extras, time, theme, layout, hazard cycle, landing tolerance, medal threshold and coin reward in `LevelRepository.campaignLevels`. List order controls the atlas and Next button. Keep IDs stable when changing the order. Add a poster in `WorldPoster.all` for a new destination.

## Checks

The unit and widget suites exercise landing windows, ownership, countdown boundaries, navigation and profile persistence. The native integration test and Chrome driver exercise touch input through the production game surface. The README includes commands for the app, tests and screenshot driver. [Local verification](../../README.md#verify-gameplay)

Daily Rumble retains the UTC-date deduction puzzle and prior saved results. A versioned daily physics arena is deferred.

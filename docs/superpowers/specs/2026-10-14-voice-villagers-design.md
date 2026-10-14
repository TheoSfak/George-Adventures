# Voices for the villagers — design

Date: 2026-10-14. Status: first step of the 1.5.0 batch Theodore asked for ("start with the order you proposed": voices,
then camera and pathfinding, then more mobs; spec only, no plan). Extends `2026-10-14-voice-over-design.md`, which left the
villagers' gossip silent because their speaker names are not NPC names.

## Behaviour

When George talks to an ambient villager, a tavern regular, a stall vendor or a stage musician (R), the line they say is
spoken, with the same rules as the story dialogue (text in step with the voice, a press moves on, music ducks).
Everything else is unchanged: the speech bubbles of strolling pairs and the tavern conversations stay silent.

## Rules

- Speaker -> voice: a name in `VillagerData.NAMES_FEMALE` is `woman`, in `NAMES_MALE` is `man`; the six named square people
  (`VillagerData.SQUARE_SPEAKERS`: name -> "f" / "m") likewise. `VoiceData.profile_for` checks the story NPCs first, then these.
  The models already agree with the names (`gender_test`), so the voice agrees with the face.
- Which lines: any villager can say any line of `VillagerData.GOSSIP` and `DRINK_LINES`, so each is recorded for both
  profiles (`man`, `woman`); each stall vendor has three lines (`VillagerData.VENDOR_CALLOUT[name]` + the two of
  `VENDOR_TALK`); both musicians share `MUSICIAN_TALK`. The line lists move into `VillagerData` (`square.gd` reads them from
  there: `VillagerData.vendor_talk(name)`, `MUSICIAN_TALK`) so `VoiceData` stays pure and does not load `square.gd`. The first
  bubble line of each stall in `VillageSquare.STALLS` equals `VENDOR_CALLOUT` (a test checks it at run time).
- `VoiceData.lines()` returns the extra entries with an explicit profile (`speaker` is a sample name of that gender); about
  3,200 more characters, 3 minutes, 1.5 MB.

## Tests

`voice_data_test` gets: every ambient name and square speaker has a profile of the right gender; every `GOSSIP` and
`DRINK_LINES` text is in `lines()` for both profiles; vendor and musician lines are there under their names; the stall call-outs
match. `voice_files_test` covers the new recordings automatically; `dialogue_voice_test` gets a villager greeting.

## Not included

Bubbles of walking pairs and tavern conversations, banners, boss shouts.

# Dodge roll and shield bash — design

Date: 2026-10-15. Status: Theodore chose "start with 3" (the two combat extras left out of the levels-combat spec), the details below follow the descriptions he saw in the earlier question; the key was changed from Left Alt to V (Alt alone activates the Windows window menu and remote-desktop tools mangle it; V is free and rebindable).

## Dodge roll (`CombatExtras`, `Player._start_dodge`)
- Key **V** (action `dodge`, rebindable in the settings as «Αποφυγή (κύλιση)», gamepad right shoulder), listed on the controls page.
- Direction: the keys he holds (forward/back, Q/E strafe, A/D strafe while the right mouse button is held, gamepad stick relative to the camera); with nothing pressed a hop backwards. Animation by the direction relative to his facing: `Dodge_Forward / Backward / Left / Right` (0.4 s).
- Movement: pushed at `CombatExtras.dodge_speed(acceleration)` for 0.30 s so the roll covers 4.2 m in all, counting the slide while he slows down.
- Invulnerable for 0.38 s (`_invulnerable`): blows, arrows and orbs do nothing. Cooldown 1.4 s.
- It cancels a swing in progress. Not possible mounted, busy (dialogue, shop), stunned, dead, in a skill (dash, leap, gesture) or in the air; no blocking during it.
- Sound `jump`, a small dust ring.

## Shield bash (`Player._start_bash`)
- Attack while blocking (K / Ctrl held, the attack input or a quick click): plays `Block_Attack` at the swing speed (1.7x), the shield lands after 0.30 s of animation time, free again after 0.62 s.
- Hits enemies within 2.5 m in a 145 degree cone in front: 50% of the sword damage, knockback 9, stun 1.4 s (`Enemy.stun`); named bosses (they have a `display_name`) are stunned for 0.5 s only. Totems break like under the sword.
- Cooldown 2.5 s. During the cooldown attacking while blocking does nothing (no sword swing, he keeps blocking). He blocks again after the bash while the key is held.

## Tests
`dodge_bash_test` (headless, 34 checks: rules, the roll in each direction, invulnerability, distance, cooldown, backward hop, cancelling a swing, not mounted/busy, the bash: damage, stun, knockback, cooldown, bosses, the controls page). Regression: `combat_move_test`, `click_attack_test`, `shield_test`, `mount_ride_test`, `savetest`.

## Guesses
Distance, invulnerability, cooldowns, bash damage and stun times, and the hit time of `Block_Attack` (0.30 s) are first guesses to tune by playing; Dodge_Left/Right may be mirrored for the Knight model (checked by name only).

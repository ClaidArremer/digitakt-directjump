# DIRECT JUMP for the Digitakt mk1

**For the Elektron Digitakt mk1, OS 1.54.** The Digitone mk1 version is a separate mod in its own repository
([Digitone-directjump](https://github.com/ClaidArremer/Digitone-directjump)); the two are not interchangeable.

An [elekloader](https://github.com/irpina/elekloader) mod (id `directjump-dt`). Two SETTINGS rows decide what
picking a pattern does while the sequencer plays:

- **DIRECT JUMP**: the pattern takes over on the **next step**, legato, carrying on from the same place in the bar.
- **START ON BAR**: the pattern starts from its **first step on the next bar line**, perfectly in time. Press the
  key of the pattern that's playing to relaunch it from its first step on the **next beat**, as an Erica Synths
  Perkons does.

By Robbie. GPL-2.0-or-later.

> Unofficial and unsupported. Flashing modified firmware is at your own risk; the stock OS always
> recovers the unit (hold FUNC while powering on, TRIG 4 OS UPGRADE, send the stock .syx).

## What you need

| | |
|---|---|
| Unit | **Digitakt mk1** (not the Digitakt II) |
| OS | **1.54** |
| Mods | elekloader's **core** for the Digitakt mk1 |

## Install

Add `directjump-dt-1.0-os1.54.elemod` in the elekloader app together with core, build, and send the firmware to
the Digitakt. From the command line:

```
python -m elekloader.patch --stock Digitakt_OS1.54.syx \
  --mod core-4.1-os1.54.elemod --mod directjump-dt-1.0-os1.54.elemod --out Digitakt_directjump.syx
```

It combines with the rest: checked linked with core 4.1, machine-pages 1.3, PUMP-DT 1.3, DH-101 0.25,
Digi Mono 0.24, digihealth 1.0.1, LØST LVLS 1.0, seq-events 0.1 and DIGISNAKE-DT 0.3.

## Using it

**SETTINGS > DIRECT JUMP** and **SETTINGS > START ON BAR**: YES (or RIGHT) ticks a row, YES (or LEFT) unticks it.

**Both are ticked at power-on.** The Digitakt's core has no project storage, so the settings cannot be saved
(as with DIGISNAKE-DT); untick one and it stays unticked until the next power-on.

| DIRECT JUMP | START ON BAR | pick another pattern | press the pattern playing |
|---|---|---|---|
| off | off | at the pattern's end (stock) | nothing (stock) |
| **on** | off | **next step, legato** | nothing |
| off | **on** | **step 1, next bar line** | **relaunch: step 1, next beat** |
| **on** | **on** | **next step, legato** | **relaunch: step 1, next beat** |

- **Legato jumps**: the new pattern plays on from the step the old one would have played, wrapped to its
  length. In per-track scale mode every track, audio and MIDI, lands where it would be had the new pattern been
  playing all along, in its own speed and length.
- **The bar and the beat** are the Digitakt's own song position: the 16ths since PLAY, or the MIDI song position
  it is sent. So starts and relaunches stay locked to the tempo and to other gear.
- **DIGISNAKE-DT** (0.3): a start relaunches every snake from its path's start with the pattern. A legato jump
  leaves the snakes walking.
- **Chains** play on as stock. **Song mode** is left as stock.

## How it works

It is the Digitone version's code. The Digitakt's sequencer is the same program: the same tick interrupt
(`0x4007041c` in 1.54), the same peek of the next pattern, arm and switch, instruction for instruction. Its state
sits at `0x4199ea24` with the Digitone's offsets for most fields; the per-track arrays are twice as long (16
tracks) and the fields after them have moved on. DIRECT JUMP arms the change itself after a pick (site A) and
works each track's step out again after a jump (site B), as on the Digitone.

| | 1.54 |
|---|---|
| site A, after the next pattern is peeked | `0x40070e26`, over `mvs.w 0x4199ed4c,d1` |
| site B, the switch's per-track steps | `0x4007124e`, over `move.w d4,0x4199ecc2` |
| the stock arm it reproduces | `0x40070e9e` (goes on at `0x40071278`) |
| the song position | `0x4199ec68` (16ths), `0x4199ec6c` (ticks) |

## Checked

- Builds, lints and links with the mods above; elekloader verified the patched image (every other section byte
  for byte, the main OS unpacks in place). The two sites hold the stock bytes the Digitone version's do, at the
  Digitakt's addresses.
- The Digitakt source run natively against a model of the Digitakt's sequencer state (16 tracks, its pattern
  layout): every case that leaves a change to the stock, the arm's fields, the start step, 16 tracks' steps in
  per-track mode at mixed speeds and lengths; a tick-by-tick timeline of 14,112 starts, each on a bar line, and
  2,016 relaunches, each on a beat.
- On a unit (Robbie's Digitakt mk1, OS 1.54, with the mods above): legato jumps mid-pattern, relaunches of the
  playing pattern on the beat, starts of another pattern on the bar (DIRECT JUMP unticked), and per-track
  patterns all play in time.

## Building

With elekloader and an m68k cross GCC on the path:

```
python -m elekloader.sdk.build --stock Digitakt_OS1.54.syx .
```

## Credits and third-party code

DIRECT JUMP is Robbie's own work, written with Claude (Anthropic). The SETTINGS rows' callbacks are adapted from
**digihealth**'s SYSTEM INFO row (irpina/digihealth, `sysinfo.s`, GPL-2.0-or-later). It builds against irpina's
elekloader SDK and runs on its core (GPL-2.0-or-later); none of them is included here. The firmware addresses were
found by studying the Digitakt's own OS so the mod can work with it; no Elektron code is included.

## Trademarks

Elektron and Digitakt are trademarks of Elektron Music Machines; Erica Synths and Perkons of Erica Synths. They
are named only to say what this works with or was inspired by. This project is not affiliated with or endorsed by
any of them.

## Licence

GPL-2.0-or-later, see [LICENSE](LICENSE).

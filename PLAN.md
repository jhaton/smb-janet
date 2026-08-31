# Janet SMB1 Port Plan

## Goal

Build a Janet-native reconstruction of NES Super Mario Bros. with Janet owning gameplay, state, entities, collision, level logic, live redefinition, and later game-specific DSLs. Jaylib/raylib owns windowing, input, rendering, audio playback, textures, and platform integration.

The port must preserve recognizable SMB1 behavior before any architectural redesign.

## Decisions

- Primary readable reference: `nukep/smb-vanilla-port` pinned to commit `87af9a388eb01093f99c2ac6a81238bce4d7158d`.
- Permission has been obtained to use that source as though MIT licensed.
- Behavioral authority: a legally obtained SMB1 ROM running under an emulator, with `smb-vanilla-port` as the readable reference and first comparison target.
- Local ROM path: `local/smb.nes`; `local/` must never be committed.
- Local ROM identifiers:
  - Headered SHA-1: `33d23c2f2cfa4c9efec87f7bc1321ce3ce6c89bd`
  - Headerless PRG+CHR SHA-1: `facee9c577a5262dbe33ac4930bb0b58c8c037f7`
  - Size: 40,976 bytes
- First milestone: deterministic reference oracle and first-divergence comparator, then the fixed-point motion kernel.
- Jaylib is pinned to `d7da7f14815e5ac70d02d6a942d1ae5adb04cb12`; Spork is pinned to `3918802d6b79848a3dba113b1fe2ee1a8f7b667b`.
- No generic ECS. Preserve SMB1's fixed object slots and update order initially.
- No CPU, PPU rasterizer, APU emulator, 6502 registers, instruction helpers, or cycle accounting in Janet.

## Non-negotiable translation rules

1. Translation and redesign are separate phases.
2. Preserve byte wrapping, signed-byte interpretation, carry/borrow behavior, fixed-point positions, frame timing, object-slot reuse, collision ordering, scroll behavior, and state-transition timing.
3. Preserve odd-looking source logic until a deterministic trace proves a replacement equivalent.
4. Simulation is stepped by an explicit `step!`; it never consumes wall-clock delta time.
5. Rendering and audio playback cannot mutate gameplay state.
6. Headless simulation must work without importing or initializing Jaylib.
7. The original ROM and ROM-derived assets remain local and untracked.

## Reference architecture

`smb-vanilla-port` provides a frame-level `SMB_tick`, a gameplay core, fixed-width RAM-backed state, fixed object slots, area decoding, collision, scrolling, and renderer callbacks. It has already removed most CPU machinery and raises graphics to ordered 8x8 tile commands, but still retains NES-shaped gameplay RAM, nametable, palette, OAM, and APU-register output.

The initial Janet port keeps only the compatibility state needed for behavior and comparison:

- a 0x800-byte gameplay buffer with symbolic accessors;
- fixed-size structure-of-arrays object slots;
- separate PRG and CHR input buffers;
- small nametable, palette, and sprite-command buffers where rendering requires them;
- explicit byte arithmetic helpers.

It does not keep a 64 KiB emulated address space or memory-mapped hardware registers.

## Target architecture

```text
Janet
├── fixed-step game loop
├── explicit gameplay state
├── player and fixed actor slots
├── collision orchestration
├── level/object/scroll logic
├── deterministic trace snapshots
├── live REPL and frame-boundary reload
└── later: fibers and game-specific DSLs
     │
     ▼
Jaylib / raylib
├── window and input
├── direct tile/texture drawing
├── audio playback
├── textures and render targets
└── platform services
```

## Planned project layout

```text
project.janet
src/
├── main.janet
├── app/
│   ├── loop.janet
│   ├── resources.janet
│   ├── repl.janet
│   └── reload.janet
├── smb/
│   ├── step.janet
│   ├── state.janet
│   ├── bytes.janet
│   ├── runtime.janet
│   ├── live-step.janet
│   ├── constants.janet
│   ├── input.janet
│   ├── reset.janet
│   ├── timers.janet
│   ├── rng.janet
│   ├── modes.janet
│   ├── pause.janet
│   ├── score.janet
│   ├── movement.janet
│   ├── player.janet
│   ├── collision.janet
│   ├── actors.janet
│   ├── objects.janet
│   ├── area.janet
│   ├── scroll.janet
│   └── sound-state.janet
└── render/
    ├── tiles.janet
    ├── world.janet
    └── hud.janet
test/
├── unit/
│   ├── frame-spine.janet
│   ├── movement.janet
│   └── runtime.janet
└── fixtures/
tools/
├── trace-reference.c
├── motion-reference.c
├── frame-spine-reference.c
├── trace-schema.jdn
└── compare-traces.janet
reference/
└── smb-vanilla-port/   # pinned external source; no ROM
```

Directories are introduced only when their first real implementation is added.

## Deterministic trace contract

Input record `N` is consumed by simulation step `N`. Snapshot `N` is emitted immediately after that step.

Each versioned trace records at least:

```text
frame
input byte
player page/pixel/fraction position
player velocity and movement force
player state and status
camera and scroll state
active object-slot flags
object identifiers, positions, velocities, and states
collision flags
mode, task, area, and level state
timers and PRNG state
```

During the compatibility phase the full 0x800-byte gameplay state may also be recorded. A schema maps byte offsets to semantic field names. The comparator streams two traces in lockstep, stops on the first differing frame, and reports semantic field paths plus expected and actual values. Cumulative-only hashes are insufficient.

Rendering gets an independent headless trace of ordered tile commands: tile index, palette, flips, position, type, and priority. This avoids requiring a GPU for rendering parity.

## Migration stages

### 0. Provenance and pins

- Record permission, source revision, ROM hashes, and toolchain revisions.
- Keep ROM and derived data untracked.

### 1. Reference oracle

- Build the pinned C reference without SDL/OpenGL.
- Feed a deterministic controller sequence into `SMB_tick`.
- Dump per-frame gameplay state and ordered tile commands.
- Add an emulator-derived trace path when FCEUX tooling is available.

### 2. Janet/Jaylib shell

- Create the Janet project and dependency pins.
- Separate headless `step!` from rendering.
- Add a minimal 256x240 nearest-neighbor Jaylib surface.
- Establish a stable world and frame-boundary function-dispatch swap for reloads.

### 3. Byte and motion kernel

- Port explicit `u8`, `i8`, carry, borrow, 16-bit, and 24-bit helpers.
- Port `MoveObjectHorizontally` and `ImposeGravity` without cleanup.
- Compare boundary vectors and multi-frame traces against the C reference.

### 4. Frame spine and compatibility state

- Port input encoding, reset order, timers, PRNG, pause, and mode/task dispatch.
- Preserve fixed frame ordering.

### 5. Area and scrolling

- Port ROM access, area/enemy stream decoding, metatile buffer, spawning, and scrolling.

### 6. Player

- Port player states, physics, animation timing, background collision, pipes, climbing, death, and size/status transitions.

### 7. Actors and objects

- Port six fixed actor slots and their original processing order.
- Port fireballs, blocks, misc objects, platforms, cannons, whirlpools, flagpole, and collision interactions.

### 8. Direct rendering and audio presentation

- Decode CHR into an atlas once and draw tiles directly with Jaylib.
- Preserve tile ordering, palette selection, flips, priority, and integer coordinates.
- Preserve sound-engine state separately from conventional raylib playback.

### 9. Full parity corpus

- Add focused traces for movement, collision, death, pipes, water, platforms, scrolling, slot pressure, castles, and known glitches.
- Add complete TAS and non-TAS routes.
- Classify every accepted difference explicitly.

### 10. Idiomatic Janet refactor

- Replace compatibility RAM one state region at a time.
- Continue emitting the old snapshot schema during each cutover.
- Split tightly coupled translated code only where traces remain identical.

### 11. Live-world architecture

- Formalize atomic hot reload and state-schema migrations.
- Add REPL inspection and mutation commands.

### 12. Fibers and DSLs

- Introduce actor, state, level, and cutscene abstractions only after parity is protected.

## First subsystem

The first Janet gameplay code is the fixed-point motion kernel:

- wrapping/signed byte conversion;
- carry and borrow;
- 16-bit and 24-bit arithmetic;
- horizontal object movement;
- gravity and velocity clamping.

It must cover speeds `0x00`, `0x01`, `0x7f`, `0x80`, and `0xff`, pixel/page wrap in both directions, fractional carry, upward/downward clamps, and multi-frame sequences. A Jaylib smoke surface will visualize one marker while hot-reloading motion functions without resetting its state.

## Milestone status

The first milestone is complete:

- The pinned C reference builds headlessly and emits a 900-frame deterministic boot/walk trace from `test/fixtures/boot-walk.inputs`.
- The binary trace stores controller input, ordered tile hash/count, palette hash, and the complete 2 KiB gameplay RAM snapshot for every frame.
- `tools/compare-traces.janet` reports the first differing frame, record field, or schema-named RAM address. Its negative check identified a deliberate mutation at `frame 300`, `object.x[0]`, address `0x0086`.
- Janet byte helpers and the direct ports of `MoveObjectHorizontally` and `ImposeGravity` match 10,455 C-generated boundary vectors.
- The headless runtime recompiles `src/smb/live-step.janet` at a frame boundary while retaining the world table, gameplay RAM buffer, frame counter, and unrelated RAM.
- The Jaylib smoke surface runs the real player-control kernel, performs an in-process reload at frame 60, reaches frame 120 with reload generation 2, and captures `build/motion-smoke.png`.

Focused verification is `make check`; it requires the untracked local ROM and locally installed project dependencies. The visual runtime proof is `make smoke`; it requires the same local ROM and dependencies.

Migration stage 4 is complete. The C oracle now emits 73 focused vectors covering controller edge suppression, cold/warm reset ranges, timer gates, the 56-bit PRNG, both top-score comparisons, pause transitions, and all 16 SMB1 mode/task routes. Janet matches them with 135 assertions, including initialization-boundary and missing-handler failures. `src/smb/step.janet` preserves the NMI gameplay order: input, pause, top score, unpaused timers/frame counter, always-running PRNG, unpaused mode dispatch, then the host trace frame.

Migration stage 5 is complete. ROM access validates and reads the untracked mapper-0 SMB1 image without copying PRG or CHR data. The C oracle emits 10,243 focused rows covering all 36 world/area pointers and headers, 339 object decodes, 9,216 constructed columns across every official area, 549 enemy-stream events, 22 maze-loop outcomes, 72 direct scroll transitions, and 9 camera-handler branches. Janet matches those rows with 93,242 assertions, including metatile and collision buffers, three-slot area-object scheduling, deterministic actor spawn state, enemy placement, maze loopback, byte-wrapped camera state, and flagpole slot-state preservation.

Migration stage 6 is complete. `src/smb/player.janet` ports player state physics, horizontal input, jump and swimming gravity, background collision, vertical and side pipe entry, vine climbing, death, injury, power-up and size transitions, control dispatch, and animation timing. The C oracle emits 1,302 before/after vectors with the complete 2 KiB gameplay RAM image for each case; Janet matches them with 1,316 assertions. `src/smb/live-step.janet` dispatches every World 1 player routine through ordinary, pipe, vine, flagpole, castle, injury, death, size-change, and fire-flower paths.

Migration stage 7 is complete. `src/smb/actors.janet` and `src/smb/objects.janet` port fixed actor initialization, movement, background/player/fireball/enemy collisions, fireballs, bubbles, block objects and metatile updates, miscellaneous objects, platforms, cannons, whirlpools, flagpole behavior, firebars, Bowser, and floatey-number processing. The C oracle emits 1,239 before/after vectors with the complete 2 KiB gameplay RAM image; Janet matches them with 1,257 assertions, including the normal actor-core dispatch across actor IDs `0` through `20` and focused regressions for slot cleanup, power-up collection, fireball collision, platform contact, firebars, Bowser flame, and Bowser defeat. Two `A_UNK_0x13` state-`0x20` vectors whose reference execution corrupts OAM remain deferred to explicit glitch classification. `src/smb/live-step.janet` preserves the C game-core order across player control, fireball and bubble processing, six actor slots, player graphics, blocks, miscellaneous objects, cannons, whirlpools, and the flagpole.

Migration stage 8 is complete. `tools/render-reference.c` emits all 512 decoded CHR tiles plus seven exact palette and ordered presentation-command scenarios; Janet matches 11,668 assertions covering 11,136 commands, scroll boundaries, sprite priority, palettes, flips, and coordinates. The headless runtime owns Jaylib-free nametable, OAM-capture, palette, command, and isolated sound state. Jaylib uploads CHR once, draws the SMB1 status, area, and sprites through fixed-size nearest-neighbor render targets, feeds conventional PCM playback without mutating gameplay RAM, and explicitly unloads render textures, the CHR texture, the audio stream, and the audio device. `make smoke` reaches frame 420 after the frame-210 hot reload and exports the title and gameplay surfaces.

Migration stage 9 vertical slice is complete. `src/smb/startup.janet` ports cold boot, title screen construction, the title menu Start transition, World 1-1 screen construction, shared secondary setup, VRAM-buffer lifetime, live area-parser scheduling, player entrance, and game-timer startup. The runtime now begins from `reset/reset!` instead of synthetic gameplay state. `tools/trace-janet.janet` emits the same binary trace format as the C oracle, and `tools/compare-route-traces.janet` matches 420 frames across controller input, tile visibility, the complete mode/screen/parser route, camera motion, game timer, and player trajectory. `make smoke` drives the same Start/walk/jump input route through a frame-210 hot reload and captures both `build/title-smoke.png` and `build/motion-smoke.png`.

The World 1-1 completion path now covers flagpole slide and castle walk player routines, star-flag timer awards and rendering, optional fireworks, and the `NextArea` handoff. `test/unit/end-level.janet` exercises the visible-star-flag crash regression and the full mode-task transition into the next area.

The World 1-2 block path now preserves the two-slot block state encoding, consumes the default gameplay VRAM buffer every NMI, restores completed metatiles, releases brick chunks, spawns block items and jumping coins, and renders power-ups. `test/unit/blocks.janet` covers the reported persistent-block regression, while the C player oracle includes second-slot brick shattering and power-up question-block hits.

The deterministic World 1 route is complete. `test/fixtures/world1-warpless.inputs` drives 7,915 frames from cold boot through World 1-1, the World 1-2 underground entrance and pipe exit, World 1-3 moving/falling/balance platforms, World 1-4 castle loops, firebars, Bowser, bridge collapse, victory messages, and World 2 initialization. `make world1-check` matches the C reference across controller input, tile visibility, 42 route fields, active actor and fireball state, and conditional platform, firebar, Bowser, bridge, and victory state. `test/unit/victory.janet` separately protects bridge removal, Bowser fall, victory setup, automatic walking, message timing, and the World 2 handoff.

## Major risks

- Janet numeric operations do not implicitly reproduce C `uint8_t` behavior.
- RAM aliasing and fixed slot ordering are behavior, not implementation noise.
- `smb-vanilla-port` intentionally differs from hardware for lag frames and some memory-corruption glitches.
- Direct rendering must retain scroll, priority, offscreen, palette, and tile-order semantics without retaining a PPU.
- Jaylib API coverage and explicit raylib resource destruction must be verified against pinned revisions.
- Wall-clock timing, audio callbacks, REPL pauses, and garbage collection must not affect simulation steps.
- Hot reload can retain stale closures or invalidate resource/state layouts unless swaps occur at frame boundaries.
- Long playthroughs do not replace targeted fixtures for rare branches and glitches.

## Current execution order

- [x] Build and inspect the pinned headless reference.
- [x] Generate the first deterministic reference trace.
- [x] Create the Janet headless project and comparator.
- [x] Port and verify the motion kernel.
- [x] Add the minimal Jaylib and hot-reload smoke proof.
- [x] Port and verify the frame spine.
- [x] Port area decoding, initialization, and scrolling.
- [x] Port player behavior and runtime control.
- [x] Port fixed actors and object interactions.
- [x] Replace the marker with direct SMB1 rendering and audio presentation.
- [x] Port and verify boot, title, Start, and World 1-1 gameplay.
- [x] Port and verify the complete World 1 route through World 2 initialization.

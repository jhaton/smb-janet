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
- The Jaylib smoke surface runs the same horizontal and gravity kernel, performs an in-process reload at frame 60, reaches frame 120 with reload generation 2, and captures `build/motion-smoke.png`.

Focused verification is `make check`; it requires the untracked local ROM and locally installed project dependencies. The visual runtime proof is `make smoke`; it requires only the local dependencies.

Migration stage 4 is complete. The C oracle now emits 73 focused vectors covering controller edge suppression, cold/warm reset ranges, timer gates, the 56-bit PRNG, both top-score comparisons, pause transitions, and all 16 SMB1 mode/task routes. Janet matches them with 135 assertions, including initialization-boundary and missing-handler failures. `src/smb/step.janet` preserves the NMI gameplay order: input, pause, top score, unpaused timers/frame counter, always-running PRNG, unpaused mode dispatch, then the host trace frame.

The next implementation boundary is migration stage 5: area/enemy stream access, area initialization, metatile buffering, spawning, and scrolling. Mode routing is complete, but the routed mode/task bodies intentionally remain unavailable until their real area and screen behavior is ported; missing handlers fail rather than silently doing nothing. Full Janet frame traces begin after those handlers can execute the boot path. Hot reload currently preserves compatible state only; schema migrations, rollback after compile errors, and resource reload policy remain stage 11 work.

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
- [ ] Port area decoding, initialization, and scrolling.

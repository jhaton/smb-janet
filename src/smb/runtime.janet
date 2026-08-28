(import ./area)
(import ./modes)
(import ./movement)
(import ./rng)
(import ./rom)
(import ./state)
(import ./step)

(def default-live-step-path "src/smb/live-step.janet")

(defn make-runtime
  [&opt image]
  (def world (state/make-world))
  (when image
    (rom/attach! world image))
  (state/write-u8! world movement/page-base 0)
  (state/write-u8! world movement/x-position-base 32)
  (state/write-u8! world movement/x-fraction-base 0)
  (state/write-u8! world movement/x-speed-base 0x10)
  (state/write-u8! world movement/y-high-base 1)
  (state/write-u8! world movement/y-position-base 112)
  (state/write-u8! world movement/y-position-fraction-base 0)
  (state/write-u8! world movement/y-speed-base 0xfb)
  (state/write-u8! world movement/y-move-force-base 0)
  (state/write-u8! world modes/oper-mode-address modes/game)
  (state/write-u8! world modes/oper-mode-task-address modes/game-core)
  (state/write-u8! world rng/register-base 0xa5)
  @{:world world
    :step nil
    :mode-handlers @{:game/initialize-area area/initialize!}
    :reload-generation 0
    :last-reload-frame nil})

(defn reload-step!
  "Compile and install the live frame function without replacing runtime or world state."
  [runtime &opt path]
  (default path default-live-step-path)
  (def world (runtime :world))
  (def environment (dofile path))
  (def step ((get environment 'live-step) :value))
  (unless (function? step)
    (error (string "live step file must define live-step: " path)))
  (put runtime :step step)
  (put (runtime :mode-handlers) :game/game-core step)
  (put runtime :reload-generation (inc (runtime :reload-generation)))
  (put runtime :last-reload-frame (world :frame))
  (unless (= world (runtime :world))
    (error "hot reload replaced stable world state"))
  runtime)

(defn tick!
  [runtime &opt joypad-one joypad-two]
  (default joypad-one 0)
  (default joypad-two 0)
  (unless (function? (runtime :step))
    (error "runtime has no installed frame step"))
  (step/step! (runtime :world) joypad-one joypad-two
              (runtime :mode-handlers))
  runtime)

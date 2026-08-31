(import ./area)
(import ./modes)
(import ./presentation)
(import ./player)
(import ./rom)
(import ./state)
(import ./reset)
(import ./sound-state)
(import ./step)
(import ./startup)
(import ./victory)

(def default-live-step-path "src/smb/live-step.janet")


(defn make-runtime
  [&opt image]
  (default image (rom/load))
  (def world (state/make-world))
  (rom/attach! world image)
  (reset/reset! world)
  (def ram (world :ram))
  (def display (presentation/make-state))
  (presentation/load-default-presentation! display image)
  (presentation/capture-sprites! display ram)
  (presentation/build-commands! display)
  (def handlers @{})
  (def runtime
    @{:world world
      :rom image
      :presentation display
      :sound (sound-state/make-state)
      :step nil
      :mode-handlers handlers
      :reload-generation 0
      :last-reload-frame nil
      :title-loaded false})
  (put handlers :title-screen/initialize-game startup/initialize-game!)
  (put handlers :title-screen/screen-routines startup/screen-routines!)
  (put handlers :title-screen/primary-game-setup startup/primary-game-setup!)
  (put handlers :title-screen/game-menu
       |(startup/game-menu! $ (runtime :step)))
  (put handlers :game/initialize-area area/initialize!)
  (put handlers :game/screen-routines startup/screen-routines!)
  (put handlers :game/secondary-game-setup startup/secondary-game-setup!)
  (put handlers :victory/bridge-collapse victory/bridge-collapse!)
  (put handlers :victory/setup-victory victory/setup!)
  (put handlers :victory/player-victory-walk victory/player-walk!)
  (put handlers :victory/print-victory-messages victory/print-messages!)
  (put handlers :victory/player-end-world victory/player-end-world!)
  runtime)

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
  (def world (runtime :world))
  (def ram (world :ram))
  (startup/consume-vram-buffer! world)
  (def display (runtime :presentation))
  # OAM DMA and PPUMASK visibility use the state from the start of the NMI.
  (def screen-was-enabled (= (get ram area/disable-screen-address) 0))
  (presentation/capture-sprites! display ram)
  (step/step! world joypad-one joypad-two
              (runtime :mode-handlers))
  (def mode (get ram modes/oper-mode-address))
  (when (and (= mode modes/title-screen)
             (= (get ram modes/oper-mode-task-address) modes/title-game-menu)
             (not (runtime :title-loaded)))
    (presentation/load-title-presentation! display (runtime :rom))
    (put runtime :title-loaded true))
  (when (or (= mode modes/game)
            (= mode modes/victory))
    (presentation/sync-metatiles! display world))
  (put display :scroll-x
       (+ (* (get ram player/addr-screen-left-page) 256)
          (get ram player/addr-screen-left-x)))
  (put display :screen-on screen-was-enabled)
  (sound-state/update! (runtime :sound) ram)
  (presentation/sync-status! display ram)
  (presentation/build-commands! display)
  runtime)

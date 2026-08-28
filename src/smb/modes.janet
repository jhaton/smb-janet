(def oper-mode-address 0x0770)
(def oper-mode-task-address 0x0772)

(def title-screen 0)
(def game 1)
(def victory 2)
(def game-over 3)

(def title-initialize-game 0)
(def title-screen-routines 1)
(def title-primary-game-setup 2)
(def title-game-menu 3)

(def game-initialize-area 0)
(def game-screen-routines 1)
(def game-secondary-game-setup 2)
(def game-core 3)

(def victory-bridge-collapse 0)
(def victory-setup 1)
(def victory-player-walk 2)
(def victory-print-messages 3)
(def victory-player-end-world 4)

(def game-over-setup 0)
(def game-over-screen-routines 1)
(def game-over-run 2)

(defn route
  "Resolve one SMB1 operation-mode/task pair to its semantic handler key."
  [mode task]
  (case mode
    0 (case task
        0 :title-screen/initialize-game
        1 :title-screen/screen-routines
        2 :title-screen/primary-game-setup
        3 :title-screen/game-menu
        nil)
    1 (case task
        0 :game/initialize-area
        1 :game/screen-routines
        2 :game/secondary-game-setup
        3 :game/game-core
        nil)
    2 (case task
        0 :victory/bridge-collapse
        1 :victory/setup-victory
        2 :victory/player-victory-walk
        3 :victory/print-victory-messages
        4 :victory/player-end-world
        nil)
    3 (case task
        0 :game-over/setup-game-over
        1 :game-over/screen-routines
        2 :game-over/run-game-over
        nil)
    nil))

(defn- automatic-next-task
  [mode task]
  (cond
    (and (= mode title-screen) (= task title-initialize-game)) title-screen-routines
    (and (= mode title-screen) (= task title-primary-game-setup)) title-game-menu
    (and (= mode game) (= task game-initialize-area)) game-screen-routines
    (and (= mode game) (= task game-secondary-game-setup)) game-core
    nil))

(defn dispatch!
  "Dispatch the current operation mode/task and apply the four caller-owned task transitions."
  [world handlers]
  (def ram (world :ram))
  (def mode (get ram oper-mode-address))
  (def task (get ram oper-mode-task-address))
  (def handler-key (route mode task))
  (unless handler-key
    (error (string "invalid operation mode/task: " mode "/" task)))
  (def handler (get handlers handler-key))
  (unless (function? handler)
    (error (string "missing operation mode handler: " handler-key)))

  (handler world)
  (when (def next-task (automatic-next-task mode task))
    (unless (= (get ram oper-mode-address) mode)
      (error (string "operation mode changed during caller-owned transition: " handler-key)))
    (put ram oper-mode-task-address next-task))
  world)

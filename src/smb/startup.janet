(import ./area)
(import ./bytes)
(import ./input)
(import ./metatiles)
(import ./modes)
(import ./oam)
(import ./reset)
(import ./rom)

(def screen-routine-task-address 0x073c)
(def vram-address-control-address 0x0773)
(def disable-screen-address 0x0774)
(def screen-timer-address 0x07a0)
(def demo-timer-address 0x07a2)
(def saved-joypad-base input/saved-joypad-base)
(def display-digits-base 0x07d7)

(defn- clear-range!
  [ram address count]
  (loop [offset :range [0 count]]
    (put ram (+ address offset) 0)))

(defn- move-all-sprites-offscreen!
  [ram]
  (loop [sprite :range [0 oam/sprite-count]]
    (put ram (+ oam/data-base (* sprite 4)) oam/offscreen-y)))

(def sound-memory-addresses
  @[0x07b0 0x07b1 0x07b2 0x07b3 0x07b4 0x07b5 0x07b6 0x07b7
    0x07b8 0x07b9 0x07ba 0x07bb 0x07bd 0x07be 0x07bf 0x07c0
    0x07c1 0x07c4 0x07c5 0x07c6 0x07c7 0x07ca])

(defn- initialize-sound-memory!
  [ram]
  (each address sound-memory-addresses
    (put ram address 0)))

(defn initialize-game!
  "Initialize the title-screen area exactly at the SMB mode boundary."
  [world]
  (def ram (world :ram))
  (reset/initialize-memory! ram 0x6f)
  (initialize-sound-memory! ram)
  (put ram demo-timer-address 0x18)
  (area/load-pointer! world)
  (area/initialize! world)
  world)

(def sprite-offsets @[4 48 72 96 120 144 168 192 216 232 36 248 252 40 44])

(defn secondary-game-setup!
  "Install the shared title/game sprite layout and enable the screen."
  [world]
  (def ram (world :ram))
  (put ram disable-screen-address 0)
  (clear-range! ram 0x0300 0x100)
  (put ram 0x0759 0) # GameTimerExpiredFlag
  (put ram 0x0769 0) # DisableIntermediate
  (put ram area/backloading-address 0)
  (put ram 0x03a0 0xff) # BalPlatformAlignment
  (put ram 0x0778
       (bor (band (get ram 0x0778) 0xfe)
            (band (get ram area/screen-left-page-address) 1)))
  (put ram 0x06e3 0x38)
  (put ram 0x06e2 0x48)
  (put ram 0x06e1 0x58)
  (eachp [index offset] sprite-offsets
    (put ram (+ 0x06e4 index) offset))
  (put ram (+ oam/data-base 0) 24)
  (put ram (+ oam/data-base 1) 0xff)
  (put ram (+ oam/data-base 2) 0x23)
  (put ram (+ oam/data-base 3) 88)
  (put ram 0x0722 (bytes/u8 (inc (get ram 0x0722))))
  (put ram 0x06c9 0xff)
  world)

(defn primary-game-setup!
  "Initialize a new title-menu player and then apply the shared setup."
  [world]
  (def ram (world :ram))
  (put ram 0x0757 1)
  (put ram 0x0754 1)
  (put ram 0x075a 2)
  (put ram 0x0761 2)
  (secondary-game-setup! world))

(defn- render-parser-columns!
  [world]
  # One AreaParserTaskHandler drain performs two parser cores and advances two columns.
  (metatiles/render-column! world)
  (area/increment-column! (world :ram))
  (metatiles/render-column! world)
  (area/increment-column! (world :ram)))

(defn- load-title-buffer!
  [world]
  (def ram (world :ram))
  (def cartridge (world :rom))
  (loop [offset :range [0 0x13a]]
    (put ram (+ 0x0300 offset) (rom/read-chr cartridge (+ 0x1ec0 offset)))))

(defn- draw-mushroom-icon!
  [ram]
  (clear-range! ram 0x0300 0x100)
  (clear-range! ram 0x0400 0x100)
  # Vertical stream at NT0 (9,18): mushroom, blank, blank; offset byte and terminator included.
  (eachp [offset value] @[7 0x22 0x49 0x83 0xce 0x24 0x24 0]
    (put ram (+ 0x0300 offset) value)))

(defn screen-routines!
  "Advance one SMB1 screen-construction task."
  [world]
  (def ram (world :ram))
  (def task (get ram screen-routine-task-address))
  (case task
    0 (do
        (move-all-sprites-offscreen! ram)
        (put ram 0x0778 (bor (band (get ram 0x0778) 0xf0) 0x10))
        (when (not= (get ram modes/oper-mode-address) modes/title-screen)
          (put ram vram-address-control-address 3))
        (put ram screen-routine-task-address 1))
    1 (put ram screen-routine-task-address 2)
    2 (put ram screen-routine-task-address 3)
    3 (put ram screen-routine-task-address 4)
    4 (if (not= (get ram 0x0759) 0)
        (do
          (put ram 0x0759 0)
          (put ram screen-timer-address 7)
          (put ram screen-routine-task-address 5)
          (put ram disable-screen-address 0))
        (put ram screen-routine-task-address 6))
    5 (when (= (get ram screen-timer-address) 0)
        (move-all-sprites-offscreen! ram)
        (put ram screen-timer-address 7)
        (put ram screen-routine-task-address 6))
    6 (case (get ram modes/oper-mode-address)
        0 (put ram screen-routine-task-address 8)
        1 (if (or (not= (get ram area/alternate-entrance-address) 0)
                  (and (not= (get ram area/area-type-address) 3)
                       (not= (get ram 0x0769) 0)))
            (put ram screen-routine-task-address 8)
            (do
              (put ram screen-timer-address 7)
              (put ram disable-screen-address 0)
              (put ram screen-routine-task-address 7)))
        (error "unsupported screen-routine mode"))
    7 (when (= (get ram screen-timer-address) 0)
        (move-all-sprites-offscreen! ram)
        (put ram screen-timer-address 7)
        (put ram screen-routine-task-address 8))
    8 (do
        (put ram disable-screen-address
             (bytes/u8 (inc (get ram disable-screen-address))))
        (render-parser-columns! world)
        (put ram area/column-sets-address
             (bytes/u8 (dec (get ram area/column-sets-address))))
        (when (>= (get ram area/column-sets-address) 0x80)
          (put ram screen-routine-task-address 9))
        (put ram vram-address-control-address 6))
    9 (do
        (put ram vram-address-control-address
             (case (get ram area/area-type-address) 0 1 1 2 2 3 3 4))
        (put ram screen-routine-task-address 10))
    10 (put ram screen-routine-task-address 11)
    11 (do
         (when (= (get ram area/area-style-address) 1)
           (put ram vram-address-control-address 11))
         (put ram screen-routine-task-address 12))
    12 (if (= (get ram modes/oper-mode-address) modes/title-screen)
         (do
           (load-title-buffer! world)
           (put ram vram-address-control-address 5)
           (put ram screen-routine-task-address 13))
         (put ram modes/oper-mode-task-address modes/game-secondary-game-setup))
    13 (do
         (draw-mushroom-icon! ram)
         (put ram screen-routine-task-address 14))
    14 (put ram modes/oper-mode-task-address modes/title-primary-game-setup)
    (error (string "unsupported screen routine task: " task)))
  world)

(defn game-menu!
  "Run the title menu, including the Start transition into World 1-1."
  [world game-core]
  (def ram (world :ram))
  (def buttons (bor (get ram saved-joypad-base)
                    (get ram (inc saved-joypad-base))))
  (def activate? (or (= buttons input/button-start)
                     (= buttons (bor input/button-a input/button-start))))
  (if (and (not= (get ram demo-timer-address) 0) activate?)
    (do
      (area/load-pointer! world)
      (put ram area/hidden-one-up-address
           (bytes/u8 (inc (get ram area/hidden-one-up-address))))
      (put ram 0x0764 (bytes/u8 (inc (get ram 0x0764))))
      (put ram 0x0757 (bytes/u8 (inc (get ram 0x0757))))
      (put ram modes/oper-mode-address modes/game)
      (put ram modes/oper-mode-task-address modes/game-initialize-area)
      (put ram area/primary-hard-mode-address (get ram 0x07fc))
      (put ram demo-timer-address 0)
      (clear-range! ram (+ display-digits-base 6) 24))
    (do
      (put ram saved-joypad-base 0)
      (game-core world)))
  world)

(defn consume-vram-buffer!
  "Apply the NMI-side lifetime of the gameplay VRAM buffer selector."
  [world]
  (def ram (world :ram))
  (def control (get ram vram-address-control-address))
  (put ram vram-address-control-address 0)
  (if (= control 6)
    (do
      (put ram 0x0340 0)
      (put ram 0x0341 0))
    (do
      (put ram 0x0300 0)
      (put ram 0x0301 0)))
  world)

(defn- area-parser-step!
  [world]
  (def ram (world :ram))
  (var task (get ram area/area-parser-task-address))
  (when (= task 0)
    (set task 8)
    (put ram area/area-parser-task-address task))
  (case task
    8 (metatiles/render-column! world)
    7 (put ram vram-address-control-address 6)
    6 (put ram vram-address-control-address 6)
    5 (area/increment-column! ram)
    4 (metatiles/render-column! world)
    3 (put ram vram-address-control-address 6)
    2 (put ram vram-address-control-address 6)
    1 (do
        (area/increment-column! ram)
        (put ram vram-address-control-address 6)))
  (put ram area/area-parser-task-address (dec task))
  world)

(defn update-scroll-parser!
  "Advance the live two-column area parser when camera scroll crosses 32 pixels."
  [world]
  (def ram (world :ram))
  (unless (= (get ram vram-address-control-address) 6)
    (var should-step (not= (get ram area/area-parser-task-address) 0))
    (unless should-step
      (def accumulated (get ram 0x073d))
      (when (and (>= accumulated 0x20) (< accumulated 0xa0))
        (put ram 0x073d (- accumulated 0x20))
        (put ram 0x0340 0)
        (set should-step true)))
    (when should-step
      (area-parser-step! world)))
  world)

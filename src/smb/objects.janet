(import ./actors)
(import ./bytes)
(import ./movement)
(import ./rom)
(import ./player)
(import ./sprites)

(def addr-frame-counter 0x0009)
(def addr-a-b-buttons 0x000a)
(def addr-previous-buttons 0x000d)
(def addr-enemy-flag 0x000f)
(def addr-enemy-id 0x0016)
(def addr-enemy-state 0x001e)
(def addr-fireball-state 0x0024)
(def addr-block-state 0x0026)
(def addr-misc-state 0x002a)
(def addr-fireball-bounce 0x003a)
(def addr-enemy-moving-dir 0x0046)
(def addr-enemy-x-speed 0x0058)
(def addr-fireball-x-speed 0x005e)
(def addr-block-x-speed 0x0060)
(def addr-misc-x-speed 0x0064)
(def addr-enemy-page 0x006e)
(def addr-fireball-page 0x0074)
(def addr-block-page 0x0076)
(def addr-misc-page 0x007a)
(def addr-bubble-page 0x0083)
(def addr-enemy-x 0x0087)
(def addr-fireball-x 0x008d)
(def addr-block-x 0x008f)
(def addr-misc-x 0x0093)
(def addr-bubble-x 0x009c)
(def addr-enemy-y-speed 0x00a0)
(def addr-fireball-y-speed 0x00a6)
(def addr-block-y-speed 0x00a8)
(def addr-misc-y-speed 0x00ac)
(def addr-enemy-y-high 0x00b6)
(def addr-fireball-y-high 0x00bc)
(def addr-block-y-high 0x00be)
(def addr-misc-y-high 0x00c2)
(def addr-bubble-y-high 0x00cb)
(def addr-enemy-y 0x00cf)
(def addr-fireball-y 0x00d5)
(def addr-block-y 0x00d7)
(def addr-misc-y 0x00db)
(def addr-bubble-y 0x00e4)
(def addr-square1-sound 0x00ff)
(def addr-square2-sound 0x00fe)
(def addr-flagpole-number-y 0x010d)
(def addr-flagpole-number-force 0x010e)
(def addr-flagpole-score 0x010f)
(def addr-floatey-control 0x0110)
(def addr-floatey-x 0x0117)
(def addr-floatey-y 0x011e)
(def addr-floatey-timer 0x012c)
(def addr-digit-modifier 0x0134)
(def addr-vram-offset 0x0300)
(def addr-block-relative-x 0x03b1)
(def addr-block-relative-x2 0x03b2)
(def addr-misc-relative-x 0x03b3)
(def addr-block-relative-y 0x03bc)
(def addr-block-relative-y2 0x03bd)
(def addr-misc-relative-y 0x03be)
(def addr-fireball-relative-x 0x03af)
(def addr-bubble-relative-x 0x03b0)
(def addr-fireball-relative-y 0x03ba)
(def addr-bubble-relative-y 0x03bb)
(def addr-fireball-offscreen 0x03d2)
(def addr-bubble-offscreen 0x03d3)
(def addr-block-offscreen 0x03d4)
(def addr-misc-offscreen 0x03d6)
(def addr-block-origin-y 0x03e4)
(def addr-block-buffer-low 0x03e6)
(def addr-block-metatile 0x03e8)
(def addr-block-replace 0x03ec)
(def addr-block-residual 0x03f0)
(def addr-enemy-x-force 0x0401)
(def addr-block-y-fraction 0x041f)
(def addr-bubble-y-fraction 0x042c)
(def addr-enemy-y-force 0x0434)
(def addr-block-y-force 0x043c)
(def addr-cannon-page 0x046b)
(def addr-cannon-x 0x0471)
(def addr-cannon-y 0x0477)
(def addr-cannon-timer 0x047d)
(def addr-bounding-control 0x0499)
(def addr-bounding-boxes 0x04ac)
(def addr-block-buffer1 0x0500)
(def addr-block-buffer2 0x05d0)
(def addr-hammer-enemy-offset 0x06ae)
(def addr-enemy-frenzy-buffer 0x06cb)
(def addr-secondary-hard-mode 0x06cc)
(def addr-fireball-counter 0x06ce)
(def addr-fireworks-counter 0x06d7)
(def addr-player-animation-set 0x070c)
(def addr-fireball-throw-timer 0x0711)
(def addr-misc-collision 0x06be)
(def addr-star-timer 0x079f)
(def addr-crouching 0x0714)
(def addr-screen-left-page 0x071a)
(def addr-screen-right-page 0x071b)
(def addr-screen-left-x 0x071c)
(def addr-screen-right-x 0x071d)
(def addr-timer-control 0x0747)
(def addr-star-flag-task 0x0746)
(def addr-area-type 0x074e)
(def addr-player-status 0x0756)
(def addr-scroll-amount 0x0775)
(def addr-air-bubble-timer 0x0792)
(def addr-enemy-interval-timer 0x0796)
(def addr-random 0x07a7)
(def addr-event-music-buffer 0x07b1)
(def addr-game-timer-display 0x07f8)

(defn- read8 [ram address] (get ram address))
(defn- write8! [ram address value] (put ram address (bytes/u8 value)))
(defn- slot-read [ram base slot] (read8 ram (+ base slot)))
(defn- slot-write! [ram base slot value] (write8! ram (+ base slot) value))

(defn- relative-position!
  [ram object relative-slot]
  (write8! ram (+ 0x03b8 relative-slot)
           (read8 ram (+ movement/y-position-base object)))
  (write8! ram (+ 0x03ad relative-slot)
           (- (read8 ram (+ movement/x-position-base object))
              (read8 ram addr-screen-left-x))))

(def x-offscreen-table
  @[0x7f 0x3f 0x1f 0x0f 0x07 0x03 0x01 0x00
    0x80 0xc0 0xe0 0xf0 0xf8 0xfc 0xfe 0xff])
(def y-offscreen-table @[0 8 12 14 15 7 3 1 0])

(defn- x-offscreen-index
  [ram object right]
  (def page (read8 ram (if right addr-screen-right-page addr-screen-left-page)))
  (def x (read8 ram (if right addr-screen-right-x addr-screen-left-x)))
  (var distance
    (+ (- page (read8 ram (+ movement/page-base object)))
       (/ (- x (read8 ram (+ movement/x-position-base object))) 256.0)))
  (set distance (+ (- x (read8 ram (+ movement/x-position-base object)))
                   (* (- page (read8 ram (+ movement/page-base object))) 256)))
  (var index
    (cond (< distance 0) 7
          (< distance 56) (+ 8 (div distance 8))
          true 15))
  (when right (set index (% (+ index 8) 16)))
  index)

(defn- x-offscreen-bits
  [ram object]
  (def right (get x-offscreen-table (x-offscreen-index ram object true)))
  (if (not= right 0)
    right
    (get x-offscreen-table (x-offscreen-index ram object false))))

(defn- y-offscreen-index
  [ram object a]
  (var distance
    (- 256 (* (read8 ram (+ movement/y-high-base object)) 256)
       (read8 ram (+ movement/y-position-base object))))
  (unless a (set distance (+ distance 255)))
  (var index
    (cond (< distance 0) 4
          (< distance 32) (+ 4 (div distance 8))
          true 0))
  (when a (set index (% (+ index 4) 8)))
  index)

(defn- y-offscreen-bits
  [ram object]
  (def first (get y-offscreen-table (y-offscreen-index ram object true)))
  (if (not= first 0)
    first
    (get y-offscreen-table (y-offscreen-index ram object false))))

(defn- offscreen-bits!
  [ram object relative-slot]
  (write8! ram (+ 0x03d0 relative-slot)
           (bor (blshift (y-offscreen-bits ram object) 4)
                (brshift (x-offscreen-bits ram object) 4))))

(def bbox-offsets
  @[@[2 8 14 32] @[3 20 13 32] @[2 20 14 32] @[2 9 14 21]
    @[0 0 24 6] @[0 0 32 13] @[0 0 48 13] @[0 0 8 8]
    @[6 4 10 8] @[3 14 13 20] @[0 2 16 21] @[4 4 12 28]])

(defn- bounding-box!
  [ram box-object relative-slot]
  (def control (read8 ram (+ addr-bounding-control box-object)))
  (def offsets (get bbox-offsets control))
  (def x (read8 ram (+ 0x03ad relative-slot)))
  (def y (read8 ram (+ 0x03b8 relative-slot)))
  (loop [index :range [0 4]]
    (write8! ram (+ addr-bounding-boxes (* box-object 4) index)
             (+ (if (or (= index 0) (= index 2)) x y)
                (get offsets index))))
  (def screen-left
    (bytes/pack-u16 (read8 ram addr-screen-left-page)
                    (read8 ram addr-screen-left-x)))
  (def position
    (bytes/pack-u16 (read8 ram (+ movement/page-base box-object))
                    (read8 ram (+ movement/x-position-base box-object))))
  (def address (+ addr-bounding-boxes (* box-object 4)))
  (def left (read8 ram address))
  (def right (read8 ram (+ address 2)))
  (if (>= position (+ screen-left 0x80))
    (when (< right 0x80)
      (when (< left 0x80) (write8! ram address 0xff))
      (write8! ram (+ address 2) 0xff))
    (when (>= left 0xa0)
      (when (>= right 0x80) (write8! ram (+ address 2) 0))
      (write8! ram address 0))))

(defn- get-metatile
  [ram mt-x mt-y]
  (if (or (< mt-y 0) (>= mt-y 13))
    0
    (read8 ram (+ (if (< (% mt-x 32) 16)
                   addr-block-buffer1
                   addr-block-buffer2)
                 (% mt-x 16)
                 (* mt-y 16)))))

(defn- set-metatile!
  [ram mt-x mt-y value]
  (when (and (>= mt-y 0) (< mt-y 13))
    (write8! ram (+ (if (< (% mt-x 32) 16)
                     addr-block-buffer1
                     addr-block-buffer2)
                   (% mt-x 16)
                   (* mt-y 16))
             value)))

(defn- fireball-background!
  [ram slot]
  (if (>= (slot-read ram addr-fireball-y slot) 0x18)
    (do
      (def object (+ slot 7))
      (def x-position
        (bytes/pack-u16 (read8 ram (+ movement/page-base object))
                        (read8 ram (+ movement/x-position-base object))))
      (def y-position (read8 ram (+ movement/y-position-base object)))
      (def mt-x (div (+ x-position 4) 16))
      (def mt-y (- (div (+ y-position 8) 16) 2))
      (def tile (get-metatile ram mt-x mt-y))
      (if (and (not= tile 0)
               (not (or (= tile 0x26) (= tile 0x5f) (= tile 0x60)
                        (= tile 0xc2) (= tile 0xc3))))
        (if (and (< (slot-read ram addr-fireball-y-speed slot) 0x80)
                 (zero? (slot-read ram addr-fireball-bounce slot)))
          (do
            (slot-write! ram addr-fireball-y-speed slot 0xfd)
            (slot-write! ram addr-fireball-bounce slot 1)
            (slot-write! ram addr-fireball-y slot
                         (band (slot-read ram addr-fireball-y slot) 0xf8)))
          (do
            (slot-write! ram addr-fireball-state slot 0x80)
            (write8! ram addr-square1-sound 2)))
        (slot-write! ram addr-fireball-bounce slot 0)))
    (slot-write! ram addr-fireball-bounce slot 0)))

(def fireball-x-speeds @[-87 64 -64 -122])

(defn fireball!
  [world slot]
  (def ram (world :ram))
  (def state (slot-read ram addr-fireball-state slot))
  (if (not= (band state 0x80) 0)
    (do
      (relative-position! ram (+ slot 7) 2)
      (def phase (band (brshift state 1) 7))
      (def next-state (bytes/u8 (inc state)))
      (slot-write! ram addr-fireball-state slot
                   (if (< phase 3) next-state 0))
      (when (< phase 3)
        (sprites/explosion! world phase
                            (get ram (+ sprites/addr-alt-sprite-offset slot)))))
    (when (not= state 0)
      (when (not= state 1)
        (def player-position
          (bytes/add-u16 (read8 ram player/addr-player-page)
                         (read8 ram player/addr-player-x) 0 4))
        (slot-write! ram addr-fireball-page slot (bytes/high-u16 player-position))
        (slot-write! ram addr-fireball-x slot (bytes/low-u16 player-position))
        (slot-write! ram addr-fireball-y slot (read8 ram player/addr-player-y))
        (slot-write! ram addr-fireball-y-high slot 1)
        (slot-write! ram addr-fireball-x-speed slot
                     (get fireball-x-speeds (read8 ram player/addr-player-facing)))
        (slot-write! ram addr-fireball-y-speed slot 4)
        (write8! ram (+ addr-bounding-control slot 7) 7)
        (slot-write! ram addr-fireball-state slot (dec state)))
      (movement/impose-gravity! ram false (+ slot 7) 0x50 0 3)
      (movement/move-object-horizontally! ram (+ slot 7))
      (relative-position! ram (+ slot 7) 2)
      (offscreen-bits! ram (+ slot 7) 2)
      (bounding-box! ram (+ slot 7) 2)
      (fireball-background! ram slot)
      (if (zero? (band (read8 ram addr-fireball-offscreen) 0xcc))
        (do
          (actors/fireball-collision! world slot)
          (sprites/fireball! world slot))
        (slot-write! ram addr-fireball-state slot 0))))
  world)

(defn bubble!
  [world slot]
  (def ram (world :ram))
  (var setup true)
  (if (not= (slot-read ram addr-bubble-y slot) 0xf8)
    (set setup false)
    (when (not= (read8 ram addr-air-bubble-timer) 0)
      (set setup nil)))
  (when (not (nil? setup))
    (def random (band (slot-read ram addr-random (inc slot)) 1))
    (def force (if (zero? random) 0xff 0x50))
    (when setup
      (def position
        (bytes/add-u16 (read8 ram player/addr-player-page)
                       (read8 ram player/addr-player-x) 0
                       (if (not= (band (read8 ram player/addr-player-facing) 1) 0)
                         9 0)))
      (slot-write! ram addr-bubble-page slot (bytes/high-u16 position))
      (slot-write! ram addr-bubble-x slot (bytes/low-u16 position))
      (slot-write! ram addr-bubble-y slot (+ (read8 ram player/addr-player-y) 8))
      (slot-write! ram addr-bubble-y-high slot 1)
      (write8! ram addr-air-bubble-timer (if (zero? random) 0x40 0x20)))
    (def moved
      (bytes/sub-u16 (slot-read ram addr-bubble-y slot)
                     (slot-read ram addr-bubble-y-fraction slot)
                     0 force))
    (slot-write! ram addr-bubble-y slot (bytes/high-u16 moved))
    (slot-write! ram addr-bubble-y-fraction slot (bytes/low-u16 moved))
    (when (< (slot-read ram addr-bubble-y slot) 0x20)
      (slot-write! ram addr-bubble-y slot 0xf8)))
  world)

(defn fireballs-bubbles!
  [world]
  (def ram (world :ram))
  (when (= (read8 ram addr-player-status) 2)
    (def slot (band (read8 ram addr-fireball-counter) 1))
    (when (and (not= (band (read8 ram addr-a-b-buttons) player/button-b) 0)
               (zero? (band (read8 ram addr-a-b-buttons)
                            player/button-b
                            (read8 ram addr-previous-buttons)))
               (zero? (slot-read ram addr-fireball-state slot))
               (= (read8 ram player/addr-player-y-high) 1)
               (zero? (read8 ram addr-crouching))
               (not= (read8 ram player/addr-player-state) player/state-climbing))
      (write8! ram addr-square1-sound 0x20)
      (slot-write! ram addr-fireball-state slot 2)
      (write8! ram addr-fireball-throw-timer
               (read8 ram addr-player-animation-set))
      (write8! ram 0x0781 (dec (read8 ram addr-player-animation-set)))
      (write8! ram addr-fireball-counter (inc (read8 ram addr-fireball-counter))))
    (fireball! world 0)
    (fireball! world 1))
  (when (= (read8 ram addr-area-type) 0)
    (var slot 2)
    (while (>= slot 0)
      (bubble! world slot)
      (relative-position! ram (+ slot 22) 3)
      (offscreen-bits! ram (+ slot 22) 3)
      (sprites/bubble! world slot)
      (-- slot)))
  world)

(defn block!
  [world slot]
  (def ram (world :ram))
  (def full-state (slot-read ram addr-block-state slot))
  (when (not= full-state 0)
    (def state (band full-state 0x0f))
    (if (= state 1)
      (do
        (movement/impose-gravity! ram false (+ slot 9) 0x50 0 8)
        (relative-position! ram (+ slot 9) 4)
        (relative-position! ram (+ slot 11) 5)
        (offscreen-bits! ram (+ slot 9) 4)
        (sprites/block! world slot)
        (if (> (band (slot-read ram addr-block-y slot) 0x0f) 4)
          (slot-write! ram addr-block-state slot 1)
          (do
            (slot-write! ram addr-block-replace slot 1)
            (slot-write! ram addr-block-state slot 0))))
      (do
        (movement/impose-gravity! ram false (+ slot 9) 0x50 0 8)
        (movement/move-object-horizontally! ram (+ slot 9))
        (movement/impose-gravity! ram false (+ slot 11) 0x50 0 8)
        (movement/move-object-horizontally! ram (+ slot 11))
        (relative-position! ram (+ slot 9) 4)
        (relative-position! ram (+ slot 11) 5)
        (offscreen-bits! ram (+ slot 9) 4)
        (sprites/brick-chunks! world slot)
        (if (= (slot-read ram addr-block-y-high slot) 0)
          (slot-write! ram addr-block-state slot state)
          (do
            (when (> (slot-read ram addr-block-y (+ slot 2)) 0xf0)
              (slot-write! ram addr-block-y (+ slot 2) 0xf0))
            (slot-write! ram addr-block-state slot
                         (if (< (slot-read ram addr-block-y slot) 0xf0)
                           state 0)))))))
  world)

(def block-tiles
  @[@[0x45 0x45 0x47 0x47] @[0x47 0x47 0x47 0x47]
    @[0x57 0x58 0x59 0x5a] @[0x24 0x24 0x24 0x24]])

(defn- write-block-metatile!
  [ram tile mt-x mt-y]
  (def graphics
    (cond (= tile 0) 3
          (or (= tile 0x51) (= tile 0x54)) 0
          (or (= tile 0x50) (= tile 0x52)) 1
          true 2))
  (def output (get block-tiles graphics))
  (def offset (inc (read8 ram addr-vram-offset)))
  (def tile-x (* (% mt-x 16) 2))
  (def tile-y (+ mt-y 2))
  (def nametable (if (zero? (band mt-x 0x10)) 0x20 0x24))
  (def address (bor (blshift nametable 8) (blshift tile-y 6) tile-x))
  (write8! ram (+ 0x0300 offset) (bytes/high-u16 address))
  (write8! ram (+ 0x0301 offset) (bytes/low-u16 address))
  (write8! ram (+ 0x0302 offset) 2)
  (write8! ram (+ 0x0303 offset) (get output 0))
  (write8! ram (+ 0x0304 offset) (get output 1))
  (write8! ram (+ 0x0305 offset) (bytes/high-u16 address))
  (write8! ram (+ 0x0306 offset) (+ (bytes/low-u16 address) 32))
  (write8! ram (+ 0x0307 offset) 2)
  (write8! ram (+ 0x0308 offset) (get output 2))
  (write8! ram (+ 0x0309 offset) (get output 3))
  (write8! ram (+ 0x030a offset) 0)
  (write8! ram addr-vram-offset (+ (read8 ram addr-vram-offset) 10)))

(defn update-block-metatiles!
  [world]
  (def ram (world :ram))
  (var slot 1)
  (while (>= slot 0)
    (when (and (zero? (read8 ram 0x0301))
               (not= (slot-read ram addr-block-replace slot) 0))
      (def low (slot-read ram addr-block-buffer-low slot))
      (def mt-x (+ (band low 0x0f) (if (>= low 0xd0) 16 0)))
      (def mt-y (div (slot-read ram addr-block-origin-y slot) 16))
      (def tile (slot-read ram addr-block-metatile slot))
      (set-metatile! ram mt-x mt-y tile)
      (write-block-metatile! ram tile mt-x mt-y)
      (write8! ram addr-block-residual (inc (read8 ram addr-block-residual)))
      (slot-write! ram addr-block-replace slot
                   (dec (slot-read ram addr-block-replace slot))))
    (-- slot))
  world)

(defn misc!
  [world]
  (def ram (world :ram))
  (var slot 8)
  (while (>= slot 0)
    (def state (slot-read ram addr-misc-state slot))
    (when (not= state 0)
      (if (>= state 0x80)
        (do
          (when (zero? (read8 ram addr-timer-control))
            (if (< (band state 0x7f) 2)
              (do
                (movement/impose-gravity! ram false (+ slot 13) 0x10 0x0f 4)
                (movement/move-object-horizontally! ram (+ slot 13)))
              (do
                (def enemy (slot-read ram addr-hammer-enemy-offset slot))
                (when (= (band state 0x7f) 2)
                  (slot-write! ram addr-misc-y-speed slot 0xfe)
                  (slot-write! ram addr-enemy-state enemy
                               (band (slot-read ram addr-enemy-state enemy) 0xf7))
                  (slot-write! ram addr-misc-x-speed slot
                               (if (= (slot-read ram addr-enemy-moving-dir enemy) 1)
                                 0x10 0xf0)))
                (slot-write! ram addr-misc-state slot (dec state))
                (def position
                  (bytes/add-u16 (slot-read ram addr-enemy-page enemy)
                                 (slot-read ram addr-enemy-x enemy) 0 2))
                (slot-write! ram addr-misc-page slot (bytes/high-u16 position))
                (slot-write! ram addr-misc-x slot (bytes/low-u16 position))
                (slot-write! ram addr-misc-y slot
                             (- (slot-read ram addr-enemy-y enemy) 10))
                (slot-write! ram addr-misc-y-high slot 1))))
          (when (and (not= (band (read8 ram addr-frame-counter) 1) 0)
                     (zero? (read8 ram addr-timer-control))
                     (zero? (read8 ram addr-misc-offscreen)))
            (if (actors/boxes-collide? ram 0 (+ 0x24 (* slot 4)))
              (when (zero? (slot-read ram addr-misc-collision slot))
                (slot-write! ram addr-misc-collision slot 1)
                (slot-write! ram addr-misc-x-speed slot
                             (- (slot-read ram addr-misc-x-speed slot)))
                (when (zero? (read8 ram addr-star-timer))
                  (actors/force-injury! ram)))
              (slot-write! ram addr-misc-collision slot 0)))
          (offscreen-bits! ram (+ slot 13) 6)
          (relative-position! ram (+ slot 13) 6)
          (bounding-box! ram (+ slot 9) 6)
          (sprites/hammer! world slot))
        (if (= state 1)
          (do
            (movement/impose-gravity! ram false (+ slot 13) 0x50 3 6)
            (when (= (slot-read ram addr-misc-y-speed slot) 5)
              (slot-write! ram addr-misc-state slot (inc state)))
            (relative-position! ram (+ slot 13) 6)
            (offscreen-bits! ram (+ slot 13) 6)
            (bounding-box! ram (+ slot 9) 6)
            (sprites/jumping-coin! world slot))
          (do
            (slot-write! ram addr-misc-state slot (inc state))
            (def position
              (bytes/add-u16 (slot-read ram addr-misc-page slot)
                             (slot-read ram addr-misc-x slot) 0
                             (read8 ram addr-scroll-amount)))
            (slot-write! ram addr-misc-page slot (bytes/high-u16 position))

            (slot-write! ram addr-misc-x slot (bytes/low-u16 position))
            (unless (= (slot-read ram addr-misc-state slot) 0x30)
              (relative-position! ram (+ slot 13) 6)
              (offscreen-bits! ram (+ slot 13) 6)
              (bounding-box! ram (+ slot 9) 6)
              (sprites/jumping-coin! world slot))
            (when (= (slot-read ram addr-misc-state slot) 0x30)
              (slot-write! ram addr-misc-state slot 0))))))
    (-- slot))
  world)
(defn- move-box-offscreen!
  [ram slot]
  (def address (+ addr-bounding-boxes (* (inc slot) 4)))
  (loop [index :range [0 4]]
    (write8! ram (+ address index) 0xff)))

(defn- enemy-bounding-box!
  [ram slot left-mask right-mask]
  (def page-difference
    (bytes/u8 (- (slot-read ram addr-enemy-page slot)
                 (read8 ram addr-screen-left-page)
                 (if (< (slot-read ram addr-enemy-x slot)
                        (read8 ram addr-screen-left-x))
                   1 0))))
  (def right-half
    (and (< page-difference 0x80)
         (not= (bytes/u8 (bor page-difference
                              (- (slot-read ram addr-enemy-x slot)
                                 (read8 ram addr-screen-left-x))))
               0)))
  (def masked
    (band (if right-half right-mask left-mask)
          (read8 ram 0x03d1)))
  (slot-write! ram 0x03d8 slot masked)
  (if (not= masked 0)
    (move-box-offscreen! ram slot)
    (bounding-box! ram (inc slot) 1)))

(defn- platform-bounding-box!
  [ram slot small]
  (if small
    (enemy-bounding-box! ram slot 4 8)
    (if (>= (x-offscreen-bits ram (inc slot)) 0xfe)
      (move-box-offscreen! ram slot)
      (bounding-box! ram (inc slot) 1))))

(defn- player-vertical-offscreen?
  [ram]
  (or (>= (read8 ram 0x03d0) 0xf0)
      (and (= (read8 ram player/addr-player-y-high) 1)
           (>= (read8 ram player/addr-player-y) 0xd0))))

(defn- platform-contact!
  [ram collision-slot box-slot height-value owner-slot]
  (def player-top (read8 ram (+ addr-bounding-boxes 1)))
  (def player-right (read8 ram (+ addr-bounding-boxes 2)))
  (def platform-address (+ addr-bounding-boxes (* (inc box-slot) 4)))
  (def platform-left (read8 ram platform-address))
  (def platform-top (read8 ram (+ platform-address 1)))
  (def platform-right (read8 ram (+ platform-address 2)))
  (def platform-bottom (read8 ram (+ platform-address 3)))
  (when (and (< (bytes/u8 (- platform-bottom player-top)) 4)
             (>= (read8 ram player/addr-player-y-speed) 0x80))
    (write8! ram player/addr-player-y-speed 1))
  (def landed
    (and (< (bytes/u8 (- (read8 ram (+ addr-bounding-boxes 3))
                         platform-top))
            6)
         (< (read8 ram player/addr-player-y-speed) 0x80)))
  (if landed
    (do
      (slot-write! ram 0x03a2 owner-slot
                   (if (or (= (slot-read ram addr-enemy-id collision-slot) 43)
                           (= (slot-read ram addr-enemy-id collision-slot) 44))
                     height-value
                     collision-slot))
      (write8! ram player/addr-player-state player/state-on-ground))
    (cond
      (<= (bytes/u8 (- player-right platform-left)) 7)
      (player/impede-player! ram player/button-right)
      (<= (bytes/u8 (- platform-right
                       (read8 ram addr-bounding-boxes)
                       1))
          8)
      (player/impede-player! ram player/button-left))))

(defn- large-platform-collision!
  [ram slot]
  (slot-write! ram 0x03a2 slot 0xff)
  (when (and (zero? (read8 ram addr-timer-control))
             (< (slot-read ram addr-enemy-state slot) 0x80)
             (not (player-vertical-offscreen? ram)))
    (when (= (slot-read ram addr-enemy-id slot) 36)
      (def paired (slot-read ram addr-enemy-state slot))
      (when (actors/boxes-collide? ram 0 (* (inc paired) 4))
        (platform-contact! ram paired paired
                           (slot-read ram addr-enemy-y paired) slot)))
    (when (actors/boxes-collide? ram 0 (* (inc slot) 4))
      (platform-contact! ram slot slot
                         (slot-read ram addr-enemy-y slot) slot))))

(defn- small-platform-collision!
  [ram slot]
  (when (zero? (read8 ram addr-timer-control))
    (slot-write! ram 0x03a2 slot 0)
    (unless (player-vertical-offscreen? ram)
      (var height 2)
      (var checking true)
      (while (and (> height 0) checking)
        (def address (+ addr-bounding-boxes (* (inc slot) 4)))
        (when (not= (band (read8 ram 0x03d1) 2) 0)
          (set checking false))
        (when (and checking (>= (read8 ram (+ address 1)) 0x20)
                   (actors/boxes-collide? ram 0 (* (inc slot) 4)))
          (platform-contact! ram slot slot height slot)
          (set checking false))
        (when checking
          (write8! ram (+ address 1) (+ (read8 ram (+ address 1)) 0x80))
          (write8! ram (+ address 3) (+ (read8 ram (+ address 3)) 0x80)))
        (-- height)))))

(defn- bullet-offscreen-bounds!
  [ram slot]
  (def left-x (read8 ram addr-screen-left-x))
  (def left-page (read8 ram addr-screen-left-page))
  (def right-x (read8 ram addr-screen-right-x))
  (def right-page (read8 ram addr-screen-right-page))
  (def beyond-midpoint (>= left-x 0x48))
  (def has-left-page (or beyond-midpoint
                         (and (not beyond-midpoint) (not= left-page 0))))
  (def right-limit
    (bytes/u8 (+ right-x 0x48 (if has-left-page 1 0))))
  (def right-carry
    (or (>= right-x 0xb8)
        (and has-left-page (zero? right-limit))))
  (def enemy-page (slot-read ram addr-enemy-page slot))
  (def enemy-x (slot-read ram addr-enemy-x slot))
  (def left-limit (bytes/u8 (+ left-x 0xb8)))
  (def left-difference
    (bytes/u8 (+ (- enemy-page left-page)
                 (if (not beyond-midpoint) 1 0)
                 (- (if (< enemy-x left-limit) 1 0)))))
  (def right-difference
    (bytes/u8 (+ (- enemy-page right-page)
                 (- (if right-carry 1 0))
                 (- (if (< enemy-x right-limit) 1 0)))))
  (if (or (>= left-difference 0x80)
          (< right-difference 0x80))
    (do
      (slot-write! ram addr-enemy-flag slot 0)
      false)
    true))

(defn- bullet-bill!
  [world slot]
  (def ram (world :ram))
  (var active true)
  (when (zero? (read8 ram addr-timer-control))
    (when (zero? (slot-read ram addr-enemy-state slot))
      (if (= (band (read8 ram 0x03d1) 0x0c) 0x0c)
        (do
          (slot-write! ram addr-enemy-flag slot 0)
          (set active false))
        (do
          (def player-position
            (bytes/pack-u16 (read8 ram player/addr-player-page)
                            (read8 ram player/addr-player-x)))
          (def enemy-position
            (bytes/pack-u16 (slot-read ram addr-enemy-page slot)
                            (slot-read ram addr-enemy-x slot)))
          (def difference (- enemy-position player-position))
          (def carry (>= enemy-position player-position))
          (if (< difference 0)
            (do
              (slot-write! ram addr-enemy-moving-dir slot 1)
              (slot-write! ram addr-enemy-x-speed slot 0x18))
            (do
              (slot-write! ram addr-enemy-moving-dir slot 2)
              (slot-write! ram addr-enemy-x-speed slot 0xe8)))
          (if (< (bytes/u8 (+ (bytes/u8 difference) 0x28
                              (if carry 1 0)))
                 0x50)
            (do
              (slot-write! ram addr-enemy-flag slot 0)
              (set active false))
            (do
              (slot-write! ram addr-enemy-state slot 1)
              (slot-write! ram 0x078a slot 10)
              (write8! ram addr-square2-sound 8))))))
    (when active
      (when (not= (band (slot-read ram addr-enemy-state slot) 0x20) 0)
        (movement/impose-gravity! ram false (inc slot) 0x3d 0 3))
      (movement/move-object-horizontally! ram (inc slot))))
  (when active
    (offscreen-bits! ram (inc slot) 1)
    (relative-position! ram (inc slot) 1)
    (bounding-box! ram (inc slot) 1)
    (actors/player-collision! world slot)
    (sprites/enemy! world slot)))

(defn cannons!
  [world]
  (def ram (world :ram))
  (unless (= (read8 ram addr-area-type) 0)
    (var slot 2)
    (while (>= slot 0)
      (var process-existing true)
      (when (zero? (slot-read ram addr-enemy-flag slot))
        (def mask (if (zero? (read8 ram addr-secondary-hard-mode)) 0x0f 7))
        (def cannon (band (slot-read ram addr-random (inc slot)) mask))
        (when (and (< cannon 6) (not= (slot-read ram addr-cannon-page cannon) 0))
          (if (not= (slot-read ram addr-cannon-timer cannon) 0)
            (slot-write! ram addr-cannon-timer cannon
                         (dec (slot-read ram addr-cannon-timer cannon)))
            (when (zero? (read8 ram addr-timer-control))
              (slot-write! ram addr-cannon-timer cannon 14)
              (slot-write! ram addr-enemy-page slot
                           (slot-read ram addr-cannon-page cannon))
              (slot-write! ram addr-enemy-x slot
                           (slot-read ram addr-cannon-x cannon))
              (slot-write! ram addr-enemy-y slot
                           (- (slot-read ram addr-cannon-y cannon) 8))
              (slot-write! ram addr-enemy-y-high slot 1)
              (slot-write! ram addr-enemy-flag slot 1)
              (slot-write! ram addr-enemy-state slot 0)
              (write8! ram (+ addr-bounding-control slot 1) 9)
              (slot-write! ram addr-enemy-id slot actors/actor-cannon-bullet)
              (set process-existing false)))))
      (when (and process-existing
                 (= (slot-read ram addr-enemy-id slot) actors/actor-cannon-bullet)
                 (not= (slot-read ram addr-enemy-flag slot) 0)
                 (bullet-offscreen-bounds! ram slot))
        (offscreen-bits! ram (inc slot) 1)
        (when (not= (slot-read ram addr-enemy-flag slot) 0)
          (bullet-bill! world slot)))
      (-- slot)))
  world)

(defn whirlpools!
  [world]
  (def ram (world :ram))
  (when (= (read8 ram addr-area-type) 0)
    (write8! ram addr-cannon-timer 0)
    (when (zero? (read8 ram addr-timer-control))
      (var slot 4)
      (var found false)
      (while (and (>= slot 0) (not found))
        (def whirlpool
          (bytes/pack-u16 (slot-read ram addr-cannon-page slot)
                          (slot-read ram addr-cannon-x slot)))
        (def player-position
          (bytes/pack-u16 (read8 ram player/addr-player-page)
                          (read8 ram player/addr-player-x)))
        (def length (slot-read ram addr-cannon-y slot))
        (when (and (>= whirlpool 0x100) (>= player-position whirlpool)
                   (<= (- player-position whirlpool) length))
          (def difference (- player-position whirlpool))
          (when (not= (band (read8 ram addr-frame-counter) 1) 0)
            (var moved nil)
            (cond
              (> difference (div length 2))
              (set moved (bytes/sub-u16 (read8 ram player/addr-player-page)
                                        (read8 ram player/addr-player-x) 0 1))
              (not= (band (read8 ram player/addr-collision-bits) 1) 0)
              (set moved (bytes/add-u16 (read8 ram player/addr-player-page)
                                        (read8 ram player/addr-player-x) 0 1)))
            (when moved
              (write8! ram player/addr-player-page (bytes/high-u16 moved))
              (write8! ram player/addr-player-x (bytes/low-u16 moved))))
          (write8! ram addr-cannon-timer 1)
          (movement/impose-gravity! ram false 0 0x10 0 1)
          (set found true))
        (-- slot))))
  world)

(defn- position-player-on-platform!
  [ram slot]
  (when (and (not= (read8 ram player/addr-game-routine)
                    player/routine-player-death)
             (= (slot-read ram addr-enemy-y-high slot) 1))
    (write8! ram player/addr-player-y (- (slot-read ram addr-enemy-y slot) 0x20))
    (write8! ram player/addr-player-y-high
             (- 1 (if (< (slot-read ram addr-enemy-y slot) 0x20) 1 0)))
    (write8! ram player/addr-player-y-speed 0)
    (write8! ram player/addr-player-y-force 0)))

(defn- position-player-on-small-platform!
  [ram height slot]
  (when (and (not= (read8 ram player/addr-game-routine)
                    player/routine-player-death)
             (= (slot-read ram addr-enemy-y-high slot) 1))
    (def position
      (bytes/u16 (+ (bytes/pack-u16
                      (slot-read ram addr-enemy-y-high slot)
                      (slot-read ram addr-enemy-y slot))
                    (if (= height 1) 0x80 0)
                    -0x20)))
    (write8! ram player/addr-player-y-high (bytes/high-u16 position))
    (write8! ram player/addr-player-y (bytes/low-u16 position))
    (write8! ram player/addr-player-y-speed 0)
    (write8! ram player/addr-player-y-force 0)))

(defn- update-platform-counter!
  [ram slot maximum]
  (when (zero? (band (read8 ram addr-frame-counter) 3))
    (if (not= (band (slot-read ram addr-enemy-y-speed slot) 1) 0)
      (if (not= (slot-read ram addr-enemy-x-speed slot) 0)
        (slot-write! ram addr-enemy-x-speed slot
                     (dec (slot-read ram addr-enemy-x-speed slot)))
        (slot-write! ram addr-enemy-y-speed slot
                     (inc (slot-read ram addr-enemy-y-speed slot))))
      (if (not= (slot-read ram addr-enemy-x-speed slot) maximum)
        (slot-write! ram addr-enemy-x-speed slot
                     (inc (slot-read ram addr-enemy-x-speed slot)))
        (slot-write! ram addr-enemy-y-speed slot
                     (inc (slot-read ram addr-enemy-y-speed slot)))))))

(defn- move-platform-counter!
  [ram slot]
  (def amount (slot-read ram addr-enemy-x-speed slot))
  (if (not= (band (slot-read ram addr-enemy-y-speed slot) 2) 0)
    (slot-write! ram addr-enemy-moving-dir slot 1)
    (do
      (slot-write! ram addr-enemy-x-speed slot (- amount))
      (slot-write! ram addr-enemy-moving-dir slot 2)))
  (def delta (movement/move-object-horizontally! ram (inc slot)))
  (slot-write! ram addr-enemy-x-speed slot amount)
  delta)

(defn platform!
  [world slot]
  (def ram (world :ram))
  (def id (slot-read ram addr-enemy-id slot))
  (case id
    36 (when (not= (slot-read ram addr-enemy-y-high slot) 3)
         (def paired (slot-read ram addr-enemy-state slot))
         (when (< paired 0x80)
           (if (not= (slot-read ram addr-enemy-moving-dir slot) 0)
             (do
               (movement/impose-gravity! ram false (inc slot) 0x20 0 3)
               (movement/impose-gravity! ram false (inc paired) 0x20 0 3))
             (do
               (def old-y (slot-read ram addr-enemy-y slot))
               (if (= (slot-read ram 0x03a2 slot) slot)
                 (movement/impose-gravity! ram false (inc slot) 5 10 3)
                 (movement/impose-gravity! ram true (inc slot) 5 10 3))
               (slot-write! ram addr-enemy-y paired
                            (+ (- old-y (slot-read ram addr-enemy-y slot))
                               (slot-read ram addr-enemy-y paired)))
               (when (< (slot-read ram 0x03a2 slot) 0x80)
                 (position-player-on-platform! ram (slot-read ram 0x03a2 slot)))))))
    37 (do
         (def stationary
           (zero? (bor (slot-read ram addr-enemy-y-speed slot)
                       (slot-read ram addr-enemy-y-force slot))))
         (when stationary
           (slot-write! ram 0x0417 slot 0))
         (if (and stationary
                  (< (slot-read ram addr-enemy-y slot)
                     (slot-read ram addr-enemy-x-force slot)))
           (when (zero? (band (read8 ram addr-frame-counter) 7))
             (slot-write! ram addr-enemy-y slot
                          (inc (slot-read ram addr-enemy-y slot))))
           (if (<= (slot-read ram addr-enemy-x-speed slot)
                   (slot-read ram addr-enemy-y slot))
             (movement/impose-gravity! ram true (inc slot) 5 10 3)
             (movement/impose-gravity! ram false (inc slot) 5 10 3)))
         (when (< (slot-read ram 0x03a2 slot) 0x80)
           (position-player-on-platform! ram slot)))
    38 (do
         (unless (not= (read8 ram addr-timer-control) 0)
           (def moved
             (bytes/add-u16 (slot-read ram addr-enemy-y slot)
                            (slot-read ram 0x0417 slot)
                            (slot-read ram addr-enemy-y-speed slot)
                            (slot-read ram addr-enemy-y-force slot)))
           (slot-write! ram addr-enemy-y slot (bytes/high-u16 moved))
           (slot-write! ram 0x0417 slot (bytes/low-u16 moved)))
         (when (< (slot-read ram 0x03a2 slot) 0x80)
           (position-player-on-platform! ram slot)))
    39 (do
         (unless (not= (read8 ram addr-timer-control) 0)
           (def moved
             (bytes/add-u16 (slot-read ram addr-enemy-y slot)
                            (slot-read ram 0x0417 slot)
                            (slot-read ram addr-enemy-y-speed slot)
                            (slot-read ram addr-enemy-y-force slot)))
           (slot-write! ram addr-enemy-y slot (bytes/high-u16 moved))
           (slot-write! ram 0x0417 slot (bytes/low-u16 moved)))
         (when (< (slot-read ram 0x03a2 slot) 0x80)
           (position-player-on-platform! ram slot)))
    40 (do
         (update-platform-counter! ram slot 0x0e)
         (def delta (move-platform-counter! ram slot))
         (when (< (slot-read ram 0x03a2 slot) 0x80)
           (def moved
             (bytes/u16 (+ (bytes/pack-u16 (read8 ram player/addr-player-page)
                                                (read8 ram player/addr-player-x))
                            (bytes/i8 delta))))
           (write8! ram player/addr-player-page (bytes/high-u16 moved))
           (write8! ram player/addr-player-x (bytes/low-u16 moved))
           (write8! ram 0x03a1 delta)
           (position-player-on-platform! ram slot)))
    41 (when (< (slot-read ram 0x03a2 slot) 0x80)
         (movement/impose-gravity! ram false (inc slot) 0x7f 0 2)
         (position-player-on-platform! ram slot))
    42 (do
         (def delta (movement/move-object-horizontally! ram (inc slot)))
         (when (< (slot-read ram 0x03a2 slot) 0x80)
           (slot-write! ram addr-enemy-x-speed slot 0x10)
           (def moved
             (bytes/u16 (+ (bytes/pack-u16 (read8 ram player/addr-player-page)
                                                (read8 ram player/addr-player-x))
                            (bytes/i8 delta))))
           (write8! ram player/addr-player-page (bytes/high-u16 moved))
           (write8! ram player/addr-player-x (bytes/low-u16 moved))
           (write8! ram 0x03a1 delta)
           (position-player-on-platform! ram slot)))
    43 (do
         (unless (not= (read8 ram addr-timer-control) 0)
           (def moved
             (bytes/add-u16 (slot-read ram addr-enemy-y slot)
                            (slot-read ram 0x0417 slot)
                            (slot-read ram addr-enemy-y-speed slot)
                            (slot-read ram addr-enemy-y-force slot)))
           (slot-write! ram addr-enemy-y slot (bytes/high-u16 moved))
           (slot-write! ram 0x0417 slot (bytes/low-u16 moved)))
         (when (not= (slot-read ram 0x03a2 slot) 0)
           (position-player-on-small-platform!
             ram (slot-read ram 0x03a2 slot) slot)))
    44 (do
         (unless (not= (read8 ram addr-timer-control) 0)
           (def moved
             (bytes/add-u16 (slot-read ram addr-enemy-y slot)
                            (slot-read ram 0x0417 slot)
                            (slot-read ram addr-enemy-y-speed slot)
                            (slot-read ram addr-enemy-y-force slot)))
           (slot-write! ram addr-enemy-y slot (bytes/high-u16 moved))
           (slot-write! ram 0x0417 slot (bytes/low-u16 moved)))
         (when (not= (slot-read ram 0x03a2 slot) 0)
           (position-player-on-small-platform!
             ram (slot-read ram 0x03a2 slot) slot)))
    nil)
  world)
(defn- erase-actor!
  [ram slot]
  (slot-write! ram addr-enemy-flag slot 0)
  (slot-write! ram addr-enemy-id slot 0)
  (slot-write! ram addr-enemy-state slot 0)
  (slot-write! ram addr-floatey-control slot 0)
  (slot-write! ram addr-enemy-interval-timer slot 0)
  (slot-write! ram 0x0125 slot 0)
  (slot-write! ram 0x03c5 slot 0)
  (slot-write! ram 0x078a slot 0))

(defn- offscreen-bounds!
  [ram slot]
  (def id (slot-read ram addr-enemy-id slot))
  (unless (= id actors/actor-flying-cheep)
    (def special (or (= id actors/actor-hammer-bro)
                     (= id actors/actor-piranha)))
    (def regular (or (<= id actors/actor-red-koopa)
                     (and (>= id actors/actor-goomba)
                          (<= id actors/actor-podoboo))))
    (def left-x
      (if special
        (bytes/u8 (+ (read8 ram addr-screen-left-x) 0x39))
        (read8 ram addr-screen-left-x)))
    (def left-condition
      (cond special (and (< (read8 ram addr-screen-left-x) 0xc8)
                         (not= left-x 0))
            regular true
            true false))
    (def midpoint-or-after (>= left-x 0x48))
    (def past-midpoint (> left-x 0x48))
    (def outside-left
      (or (and (not left-condition) midpoint-or-after)
          (and left-condition past-midpoint)))
    (def inside-left (not outside-left))
    (def page-carry
      (or outside-left
          (and (not outside-left)
               (not= (read8 ram addr-screen-left-page) 0))))
    (def right-limit
      (bytes/u8 (+ (read8 ram addr-screen-right-x) 0x48
                   (if page-carry 1 0))))
    (def right-carry
      (or (>= (read8 ram addr-screen-right-x) 0xb8)
          (and page-carry (zero? right-limit))))
    (def enemy-page (slot-read ram addr-enemy-page slot))
    (def enemy-x (slot-read ram addr-enemy-x slot))
    (def left-limit (bytes/u8 (+ left-x 0xb8 (- (if left-condition 1 0)))))
    (def left-difference
      (bytes/u8 (+ (- enemy-page (read8 ram addr-screen-left-page))
                   (if inside-left 1 0)
                   (- (if (< enemy-x left-limit) 1 0)))))
    (def right-difference
      (bytes/u8 (+ (- enemy-page (read8 ram addr-screen-right-page))
                   (- (if right-carry 1 0))
                   (- (if (< enemy-x right-limit) 1 0)))))
    (cond
      (>= left-difference 0x80) (erase-actor! ram slot)
      (>= right-difference 0x80) nil
      (or (= (slot-read ram addr-enemy-state slot) 5)
          (= id actors/actor-piranha)
          (= id actors/actor-flagpole)
          (= id actors/actor-star-flag)
          (= id actors/actor-jumpspring)) nil
      true (erase-actor! ram slot))))

(def firebar-position-table
  @[@[0x00 0x01 0x03 0x04 0x05 0x06 0x07 0x07 0x08]
    @[0x00 0x03 0x06 0x09 0x0b 0x0d 0x0e 0x0f 0x10]
    @[0x00 0x04 0x09 0x0d 0x10 0x13 0x16 0x17 0x18]
    @[0x00 0x06 0x0c 0x12 0x16 0x1a 0x1d 0x1f 0x20]
    @[0x00 0x07 0x0f 0x16 0x1c 0x21 0x25 0x27 0x28]
    @[0x00 0x09 0x12 0x1b 0x21 0x27 0x2c 0x2f 0x30]
    @[0x00 0x0b 0x15 0x1f 0x27 0x2e 0x33 0x37 0x38]
    @[0x00 0x0c 0x18 0x24 0x2d 0x35 0x3b 0x3e 0x40]
    @[0x00 0x0e 0x1b 0x28 0x32 0x3b 0x42 0x46 0x48]
    @[0x00 0x0f 0x1f 0x2d 0x38 0x42 0x4a 0x4e 0x50]
    @[0x00 0x11 0x22 0x31 0x3e 0x49 0x51 0x56 0x58]])

(defn- firebar-collision!
  [ram x y]
  (when (and (not (and (not= (read8 ram addr-star-timer) 0)
                       (not= (read8 ram addr-timer-control) 0)))
             (= (read8 ram player/addr-player-y-high) 1))
    (var index 0)
    (var collided false)
    (while (and (< index 3) (not collided))
      (unless (and (< index 2)
                   (or (not= (read8 ram 0x0754) 0)
                       (not= (read8 ram addr-crouching) 0)))
        (when (< x 0xf0)
          (def player-x (+ (read8 ram 0x0207) 4))
          (def player-y
            (+ (read8 ram player/addr-player-y) (get @[0 12 24] index)))
          (when (and (< (math/abs (bytes/i8 (- player-x x))) 8)
                     (< (math/abs (bytes/i8 (- player-y y))) 8))
            (slot-write! ram addr-enemy-moving-dir 0
                         (if (>= player-x x) 1 2))
            (actors/injure-player! ram)
            (set collided true))))
      (++ index))))

(defn- firebar-position
  [angle segment]
  (var first (% angle 16))
  (when (> first 8) (set first (- 16 first)))
  (var second (% (+ angle 8) 16))
  (when (> second 8) (set second (- 16 second)))
  [(get-in firebar-position-table [segment first])
   (get-in firebar-position-table [segment second])
   (get @[1 3 2 0] (brshift angle 3))])

(defn- firebar!
  [ram slot id]
  (offscreen-bits! ram (inc slot) 1)
  (unless (not= (band (read8 ram 0x03d1) 8) 0)
    (when (zero? (read8 ram addr-timer-control))
      (def state
        (bytes/pack-u16 (slot-read ram addr-enemy-y-speed slot)
                        (slot-read ram addr-enemy-x-speed slot)))
      (def moved
        (band (+ state
                 (if (zero? (slot-read ram 0x0034 slot))
                   (slot-read ram 0x0388 slot)
                   (- (slot-read ram 0x0388 slot))))
              0x1fff))
      (slot-write! ram addr-enemy-y-speed slot (bytes/high-u16 moved))
      (slot-write! ram addr-enemy-x-speed slot (bytes/low-u16 moved)))
    (var angle (slot-read ram addr-enemy-y-speed slot))
    (when (and (>= id 31) (or (= angle 8) (= angle 0x18)))
      (++ angle)
      (slot-write! ram addr-enemy-y-speed slot angle))
    (relative-position! ram (inc slot) 1)
    (def center-x (read8 ram 0x03ae))
    (def center-y (read8 ram 0x03b9))
    (firebar-collision! ram center-x center-y)
    (def segment-count (if (>= id 31) 11 5))
    (loop [segment :range [0 segment-count]]
      (def position (firebar-position angle segment))
      (def x
        (+ center-x
           (if (not= (band (get position 2) 1) 0)
             (get position 0)
             (- (get position 0)))))
      (def y
        (if (> (math/abs (bytes/i8 (- x center-x))) 0x58)
          0xf8
          (+ center-y
             (if (not= (band (get position 2) 2) 0)
               (get position 1)
               (- (get position 1))))))
      (firebar-collision! ram (bytes/u8 x) (bytes/u8 y)))))

(defn- bowser-flame!
  [world slot]
  (def ram (world :ram))
  (when (zero? (read8 ram addr-timer-control))
    (def amount
      (if (zero? (read8 ram addr-secondary-hard-mode)) 0x40 0x60))
    (def borrow (< (slot-read ram addr-enemy-x-force slot) amount))
    (slot-write! ram addr-enemy-x-force slot
                 (- (slot-read ram addr-enemy-x-force slot) amount))
    (def old-x (slot-read ram addr-enemy-x slot))
    (slot-write! ram addr-enemy-x slot (- old-x 1 (if borrow 1 0)))
    (when (if borrow (< old-x 2) (= old-x 0))
      (slot-write! ram addr-enemy-page slot
                   (dec (slot-read ram addr-enemy-page slot))))
    (def target
      (rom/read-cpu (world :rom)
                    (+ 0xc59d (slot-read ram 0x0417 slot))))
    (when (not= (slot-read ram addr-enemy-y slot) target)
      (slot-write! ram addr-enemy-y slot
                   (+ (slot-read ram addr-enemy-y slot)
                      (slot-read ram addr-enemy-y-force slot)))))
  (relative-position! ram (inc slot) 1)
  (when (zero? (slot-read ram addr-enemy-state slot))
    (sprites/bowser-flame! world slot))
  (offscreen-bits! ram (inc slot) 1)
  (relative-position! ram (inc slot) 1)
  (when (zero? (slot-read ram addr-enemy-state slot))
    (sprites/clip-bowser-flame! world slot))
  (enemy-bounding-box! ram slot 0x44 0x48)
  (actors/player-collision! world slot)
  (offscreen-bounds! ram slot))
(defn- power-up!
  [world slot]
  (def ram (world :ram))
  (def state (slot-read ram addr-enemy-state slot))
  (when (not= state 0)
    (var process true)
    (if (>= state 0x80)
      (when (zero? (read8 ram addr-timer-control))
        (case (read8 ram 0x0039)
          0 (do
              (actors/move-normal! world slot)
              (actors/background-collision! world slot))
          2 (do
              (actors/move-jumping! ram slot)
              (actors/enemy-jump! ram slot))
          3 (do
              (actors/move-normal! world slot)
              (actors/background-collision! world slot))
          nil))
      (do
        (when (zero? (band (read8 ram addr-frame-counter) 3))
          (slot-write! ram addr-enemy-y slot
                       (dec (slot-read ram addr-enemy-y slot)))
          (def old-state (slot-read ram addr-enemy-state slot))
          (slot-write! ram addr-enemy-state slot (inc old-state))
          (when (> old-state 0x10)
            (slot-write! ram addr-enemy-x-speed slot 0x10)
            (slot-write! ram addr-enemy-state slot 0x80)
            (slot-write! ram 0x03c5 slot 0)
            (slot-write! ram addr-enemy-moving-dir slot 1)))
        (when (< (slot-read ram addr-enemy-state slot) 6)
          (set process false))))
    (when process
      (relative-position! ram (inc slot) 1)
      (offscreen-bits! ram (inc slot) 1)
      (enemy-bounding-box! ram slot 0x44 0x48)
      (sprites/power-up! world slot)
      (actors/player-collision! world slot)
      (offscreen-bounds! ram slot))))

(defn- vine!
  [ram slot]
  (when (= slot 5)
    (def flag-offset (read8 ram 0x0398))
    (def check-height (if (= flag-offset 1) 0x30 0x60))
    (when (and (not= (read8 ram 0x0399) check-height)
               (not= (band (read8 ram addr-frame-counter) 2) 0))
      (slot-write! ram addr-enemy-y 5 (dec (slot-read ram addr-enemy-y 5)))
      (write8! ram 0x0399 (inc (read8 ram 0x0399))))
    (when (>= (read8 ram 0x0399) 8)
      (relative-position! ram 6 1)
      (offscreen-bits! ram 6 1)
      (when (not= (band (read8 ram 0x03d1) 0x0c) 0)
        (when (= flag-offset 2)
          (erase-actor! ram (read8 ram 0x039b)))
        (erase-actor! ram (read8 ram 0x039a))
        (write8! ram 0x0399 0)
        (write8! ram 0x0398 0))
      (when (>= (read8 ram 0x0399) 0x20)
        (def position
          (bytes/pack-u16 (slot-read ram addr-enemy-page 5)
                          (slot-read ram addr-enemy-x 5)))
        (def mt-x (div (+ position 4) 16))
        (def mt-y (- (div (+ (slot-read ram addr-enemy-y 5) 0x10) 16) 2))
        (when (and (< mt-y 13) (= (get-metatile ram mt-x mt-y) 0))
          (set-metatile! ram mt-x mt-y 0x26))))))

(defn- jumpspring!
  [ram slot]
  (offscreen-bits! ram (inc slot) 1)
  (def animation (read8 ram 0x070e))
  (when (and (zero? (read8 ram addr-timer-control))
             (not= animation 0))
    (write8! ram player/addr-player-y
             (+ (read8 ram player/addr-player-y)
                (if (<= animation 2) 2 -2)))
    (slot-write! ram addr-enemy-y slot
                 (+ (slot-read ram addr-enemy-x-speed slot)
                    (get @[8 16 8 0] (dec animation))))
    (when (and (not= animation 1)
               (not= (band (read8 ram addr-a-b-buttons) player/button-a) 0)
               (zero? (band (read8 ram addr-a-b-buttons)
                            player/button-a
                            (read8 ram addr-previous-buttons))))
      (write8! ram 0x06db 0xf4))
    (when (= animation 4)
      (write8! ram player/addr-player-y-speed (read8 ram 0x06db))
      (write8! ram 0x070e 0)))
  (relative-position! ram (inc slot) 1)
  (offscreen-bounds! ram slot)
  (when (and (not= (read8 ram 0x070e) 0)
             (zero? (read8 ram 0x0786)))
    (write8! ram 0x0786 4)
    (write8! ram 0x070e (inc (read8 ram 0x070e)))))

(defn- bowser-hammer!
  [ram slot]
  (var misc-slot (band (slot-read ram addr-random 1) 7))
  (when (zero? misc-slot)
    (set misc-slot (band (slot-read ram addr-random 1) 8)))
  (def actor-slot (+ 4 (div misc-slot 3)))
  (when (and (zero? (slot-read ram addr-misc-state misc-slot))
             (zero? (slot-read ram addr-enemy-flag actor-slot)))
    (slot-write! ram addr-hammer-enemy-offset misc-slot slot)
    (slot-write! ram addr-misc-state misc-slot 0x90)
    (write8! ram (+ addr-bounding-control misc-slot 9) 7)))

(defn- kill-normal-actors!
  [ram]
  (loop [slot :range [0 5]]
    (erase-actor! ram slot))
  (write8! ram addr-enemy-frenzy-buffer 0))

(defn- bowser-presentation-collisions!
  [world slot]
  (def ram (world :ram))
  (offscreen-bits! ram (inc slot) 1)
  (relative-position! ram (inc slot) 1)
  (when (zero? (slot-read ram addr-enemy-state slot))
    (write8! ram (+ addr-bounding-control slot 1) 10)
    (enemy-bounding-box! ram slot 0x44 0x48)
    (actors/player-collision! world slot))
  (def duplicate (read8 ram 0x06cf))
  (slot-write! ram addr-enemy-x duplicate
               (+ (slot-read ram addr-enemy-x slot)
                  (if (not= (band (slot-read ram addr-enemy-moving-dir slot) 1)
                            0)
                    -0x10 0x10)))
  (slot-write! ram addr-enemy-y duplicate
               (+ (slot-read ram addr-enemy-y slot) 8))
  (slot-write! ram addr-enemy-state duplicate
               (slot-read ram addr-enemy-state slot))
  (slot-write! ram addr-enemy-moving-dir duplicate
               (slot-read ram addr-enemy-moving-dir slot))
  (slot-write! ram addr-enemy-id duplicate actors/actor-bowser)
  (offscreen-bits! ram (inc duplicate) 1)
  (relative-position! ram (inc duplicate) 1)
  (when (zero? (slot-read ram addr-enemy-state duplicate))
    (write8! ram (+ addr-bounding-control duplicate 1) 10)
    (enemy-bounding-box! ram duplicate 0x44 0x48)
    (actors/player-collision! world duplicate)))

(defn bowser-presentation!
  [world slot]
  (bowser-presentation-collisions! world slot)
  world)

(def bowser-random-timers @[0x21 0x41 0x11 0x31])
(def bowser-flame-timers @[0xbf 0x40 0xbf 0xbf 0xbf 0x40 0x40 0xbf])

(defn- bowser!
  [world slot]
  (def ram (world :ram))
  (if (not= (band (slot-read ram addr-enemy-state slot) 0x20) 0)
    (if (>= (slot-read ram addr-enemy-y slot) 0xe0)
      (kill-normal-actors! ram)
      (do
        (movement/impose-gravity! ram false (inc slot) 0x0f 0 2)
        (bowser-presentation-collisions! world slot)))
    (do
      (write8! ram addr-enemy-frenzy-buffer 0)
      (when (zero? (read8 ram addr-timer-control))
        (when (< (read8 ram 0x0363) 0x80)
          (write8! ram 0x0364 (dec (read8 ram 0x0364)))
          (when (zero? (read8 ram 0x0364))
            (write8! ram 0x0364 0x20)
            (write8! ram 0x0363 (bxor (read8 ram 0x0363) 1)))
          (when (zero? (band (read8 ram addr-frame-counter) 0x0f))
            (slot-write! ram addr-enemy-moving-dir slot 2))
          (when (not= (slot-read ram 0x078a slot) 0)
            (def enemy-position
              (bytes/pack-u16 (slot-read ram addr-enemy-page slot)
                              (slot-read ram addr-enemy-x slot)))
            (def player-position
              (bytes/pack-u16 (read8 ram player/addr-player-page)
                              (read8 ram player/addr-player-x)))
            (when (< enemy-position player-position)
              (slot-write! ram addr-enemy-moving-dir slot 1)
              (write8! ram 0x0365 2)
              (slot-write! ram 0x078a slot 0x20)
              (write8! ram 0x0790 0x20)))
          (when (zero? (band (read8 ram addr-frame-counter) 3))
            (when (= (slot-read ram addr-enemy-x slot) (read8 ram 0x0366))
              (write8! ram 0x06dc
                       (get bowser-random-timers
                            (band (slot-read ram addr-random slot) 3))))
            (def moved
              (bytes/u8 (+ (slot-read ram addr-enemy-x slot)
                           (read8 ram 0x0365))))
            (slot-write! ram addr-enemy-x slot moved)
            (when (not= (slot-read ram addr-enemy-moving-dir slot) 1)
              (var distance (bytes/u8 (- moved (read8 ram 0x0366))))
              (var speed 0xff)
              (when (>= distance 0x80)
                (set distance (bytes/u8 (- distance)))
                (set speed 1))
              (when (<= (read8 ram 0x06dc) distance)
                (write8! ram 0x0365 speed)))))
        (if (zero? (slot-read ram 0x078a slot))
          (do
            (movement/impose-gravity! ram false (inc slot) 0x0f 0 2)
            (when (and (>= (read8 ram 0x075f) 5)
                       (zero? (band (read8 ram addr-frame-counter) 3)))
              (bowser-hammer! ram slot))
            (when (>= (slot-read ram addr-enemy-y slot) 0x80)
              (slot-write! ram 0x078a slot
                           (get bowser-random-timers
                                (band (slot-read ram addr-random slot) 3)))))
          (when (= (slot-read ram 0x078a slot) 1)
            (slot-write! ram addr-enemy-y slot
                         (dec (slot-read ram addr-enemy-y slot)))
            (slot-write! ram addr-enemy-y-speed slot 0)
            (slot-write! ram addr-enemy-y-force slot 0)
            (slot-write! ram addr-enemy-y-speed slot 0xfe))))
      (when (or (and (not= (read8 ram 0x075f) 7)
                     (>= (read8 ram 0x075f) 5))
                (not= (read8 ram 0x0790) 0))
        (bowser-presentation-collisions! world slot))
      (when (and (or (= (read8 ram 0x075f) 7)
                     (< (read8 ram 0x075f) 5))
                 (zero? (read8 ram 0x0790)))
        (write8! ram 0x0790 0x20)
        (write8! ram 0x0363 (bxor (read8 ram 0x0363) 0x80))
        (when (not= (band (read8 ram 0x0363) 0x80) 0)
          (def control (read8 ram 0x0367))
          (write8! ram 0x0367 (band (inc control) 7))
          (write8! ram 0x0790
                   (- (get bowser-flame-timers control)
                      (if (zero? (read8 ram addr-secondary-hard-mode))
                        0 0x10)))
          (write8! ram addr-enemy-frenzy-buffer actors/actor-bowser-flame))
        (bowser-presentation-collisions! world slot))))
  world)

(defn- decrement-game-timer!
  [ram]
  (def time (+ (* (read8 ram addr-game-timer-display) 100)
               (* (read8 ram (inc addr-game-timer-display)) 10)
               (read8 ram (+ addr-game-timer-display 2))))
  (when (pos? time)
    (def next-time (dec time))
    (write8! ram addr-game-timer-display (% (div next-time 100) 10))
    (write8! ram (inc addr-game-timer-display) (% (div next-time 10) 10))
    (write8! ram (+ addr-game-timer-display 2) (% next-time 10))))

(defn- star-flag!
  [world slot]
  (def ram (world :ram))
  (write8! ram addr-enemy-frenzy-buffer 0)
  (case (read8 ram addr-star-flag-task)
    0 nil
    1 (do
        (def last-digit (read8 ram (+ addr-game-timer-display 2)))
        (slot-write! ram addr-enemy-state slot 0)
        (write8! ram addr-fireworks-counter 0xff)
        (case last-digit
          1 (do (slot-write! ram addr-enemy-state slot 5)
                (write8! ram addr-fireworks-counter 1))
          3 (do (slot-write! ram addr-enemy-state slot 3)
                (write8! ram addr-fireworks-counter 3))
          6 (write8! ram addr-fireworks-counter 6)
          nil)
        (write8! ram addr-star-flag-task 2))
    2 (if (not= (bor (read8 ram addr-game-timer-display)
                     (read8 ram (inc addr-game-timer-display))
                     (read8 ram (+ addr-game-timer-display 2)))
                0)
        (do
          (when (not= (band (read8 ram addr-frame-counter) 4) 0)
            (write8! ram addr-square2-sound 0x10))
          (write8! ram (+ addr-digit-modifier 5) 0xff)
          (decrement-game-timer! ram)
          (write8! ram (+ addr-digit-modifier 5) 5)
          (player/digits-math!
            ram (if (zero? (read8 ram player/addr-current-player)) 11 17)))
        (write8! ram addr-star-flag-task 3))
    3 (do
        (if (>= (slot-read ram addr-enemy-y slot) 0x72)
          (slot-write! ram addr-enemy-y slot
                       (dec (slot-read ram addr-enemy-y slot)))
          (if (and (not= (read8 ram addr-fireworks-counter) 0)
                   (< (read8 ram addr-fireworks-counter) 0x80))
            (write8! ram addr-enemy-frenzy-buffer actors/actor-fireworks)
            (do
              (slot-write! ram addr-enemy-interval-timer slot 6)
              (write8! ram addr-star-flag-task 4))))
        (relative-position! ram (inc slot) 1)
        (sprites/star-flag! world slot))
    4 (do
        (relative-position! ram (inc slot) 1)
        (sprites/star-flag! world slot)
        (when (and (= (slot-read ram addr-enemy-interval-timer slot) 0)
                   (= (read8 ram addr-event-music-buffer) 0))
          (write8! ram addr-star-flag-task 5)))
    5 nil)
  world)

(defn- fireworks!
  [world slot]
  (def ram (world :ram))
  (def timer (bytes/u8 (dec (slot-read ram addr-enemy-y-speed slot))))
  (slot-write! ram addr-enemy-y-speed slot timer)
  (if (= timer 0)
    (do
      (slot-write! ram addr-enemy-y-speed slot 8)
      (def frame (inc (slot-read ram addr-enemy-x-speed slot)))
      (slot-write! ram addr-enemy-x-speed slot frame)
      (if (> frame 2)
        (do
          (slot-write! ram addr-enemy-flag slot 0)
          (write8! ram addr-square2-sound 8)
          (write8! ram (+ addr-digit-modifier 4) 5)
          (player/digits-math!
            ram (if (zero? (read8 ram player/addr-current-player)) 11 17)))
        (do
          (relative-position! ram (inc slot) 1)
          (sprites/fireworks! world slot frame))))
    (do
      (relative-position! ram (inc slot) 1)
      (sprites/fireworks! world slot
                          (slot-read ram addr-enemy-x-speed slot))))
  world)

(defn actor-slot!
  [world slot]
  (def ram (world :ram))
  (def id (slot-read ram addr-enemy-id slot))

  (cond
    (<= id actors/actor-flying-cheep)
    (do
      (slot-write! ram 0x03c5 slot 0)
      (offscreen-bits! ram (inc slot) 1)
      (relative-position! ram (inc slot) 1)
      (sprites/enemy! world slot)
      (enemy-bounding-box! ram slot 0x44 0x48)
      (actors/background-collision! world slot)
      (actors/enemy-collision! world slot)
      (actors/player-collision! world slot)
      (when (zero? (read8 ram addr-timer-control))
        (actors/movement! world slot))
      (offscreen-bounds! ram slot))
    (= id actors/actor-bowser-flame)
    (bowser-flame! world slot)
    (= id actors/actor-fireworks)
    (fireworks! world slot)
    (actors/actor-firebar? id)
    (do
      (firebar! ram slot id)
      (offscreen-bounds! ram slot))
    (= id actors/actor-bowser)
    (bowser! world slot)
    (= id actors/actor-power-up)
    (power-up! world slot)
    (= id actors/actor-star-flag)
    (star-flag! world slot)
    (= id actors/actor-vine)
    (vine! ram slot)
    (= id actors/actor-jumpspring)
    (jumpspring! ram slot)
    (= id actors/actor-warp-zone)
    (when (and (not= (read8 ram player/addr-scroll-lock) 0)
               (zero? (band (read8 ram player/addr-player-y)
                            (read8 ram player/addr-player-y-high))))
      (write8! ram 0x06d6 (inc (read8 ram 0x06d6)))
      (write8! ram player/addr-scroll-lock 0)
      (erase-actor! ram slot))
    (and (>= id actors/actor-large-platform-balance)
         (<= id actors/actor-small-lift-down))
    (do
      (offscreen-bits! ram (inc slot) 1)
      (relative-position! ram (inc slot) 1)
      (def small (>= id actors/actor-small-lift-up))
      (platform-bounding-box! ram slot small)
      (if small
        (do
          (small-platform-collision! ram slot)
          (relative-position! ram (inc slot) 1)
          (sprites/small-platform! world slot)
          (when (zero? (read8 ram addr-timer-control))
            (platform! world slot)))
        (do
          (large-platform-collision! ram slot)
          (when (zero? (read8 ram addr-timer-control))
            (platform! world slot))
          (relative-position! ram (inc slot) 1)
          (sprites/large-platform! world slot
                                   (x-offscreen-bits ram (inc slot)))))
      (offscreen-bounds! ram slot))
    (= id actors/actor-retainer)
    (do
      (offscreen-bits! ram (inc slot) 1)
      (relative-position! ram (inc slot) 1))
    (or (= id actors/actor-flagpole)
        (= id actors/actor-cannon-bullet)
        (= id actors/actor-stop-frenzy)) nil
    true
    (error (string "actor behavior is not ported: " id)))
  world)

(defn flagpole!
  [world]
  (def ram (world :ram))
  (when (= (slot-read ram addr-enemy-id 5) actors/actor-flagpole)
    (when (and (= (read8 ram player/addr-game-routine) 4)
               (= (read8 ram player/addr-player-state) player/state-climbing))
      (if (or (>= (slot-read ram addr-enemy-y 5) 0xaa)
              (>= (read8 ram player/addr-player-y) 0xa2))
        (do
          (write8! ram (+ addr-digit-modifier
                          (get @[3 3 4 4 4]
                               (read8 ram addr-flagpole-score)))
                   (get @[5 2 8 4 1]
                        (read8 ram addr-flagpole-score)))
          (player/digits-math!
            ram (if (zero? (read8 ram player/addr-current-player)) 11 17))
          (write8! ram player/addr-game-routine 5))
        (do
          (def high (>= (read8 ram player/addr-player-y) 0xa2))
          (def force
            (bytes/u8 (+ (dec (slot-read ram 0x0417 5)) (if high 1 0))))
          (slot-write! ram addr-enemy-y 5
                       (+ (slot-read ram addr-enemy-y 5) 1
                          (if (or (not= (slot-read ram 0x0417 5) 0)
                                  (and high (zero? force)))
                            1 0)))
          (write8! ram addr-flagpole-number-y
                   (- (read8 ram addr-flagpole-number-y) 1
                      (if (not= (read8 ram addr-flagpole-number-force) 0xff)
                        1 0)))
          (write8! ram addr-flagpole-number-force
                   (inc (read8 ram addr-flagpole-number-force)))
          (slot-write! ram 0x0417 5 force))))
    (offscreen-bits! ram 6 1)
    (relative-position! ram 6 1)
    (sprites/flagpole! world 5))
  world)

(defn floatey!
  [world slot]
  (def ram (world :ram))
  (var control (slot-read ram addr-floatey-control slot))
  (when (not= control 0)
    (when (>= control 0x0b)
      (set control 0x0b)
      (slot-write! ram addr-floatey-control slot control))
    (def timer (slot-read ram addr-floatey-timer slot))
    (if (zero? timer)
      (slot-write! ram addr-floatey-control slot 0)
      (do
        (slot-write! ram addr-floatey-timer slot (dec timer))
        (sprites/floatey! world slot))))
  world)

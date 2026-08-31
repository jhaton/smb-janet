(import ./bytes)
(import ./area)
(import ./movement)
(import ./modes)
(import ./oam)
(import ./rom)
(import ./scroll)

(def button-a 0x80)
(def button-b 0x40)
(def button-up 0x08)
(def button-down 0x04)
(def button-left 0x02)
(def button-right 0x01)

(def routine-entrance-setup 0)
(def routine-vine-auto-climb 1)
(def routine-side-pipe 2)
(def routine-vertical-pipe 3)
(def routine-flagpole-slide 4)
(def routine-player-end-level 5)
(def routine-lose-life 6)
(def routine-player-entrance 7)
(def routine-player-control 8)
(def routine-change-size 9)
(def routine-injury 10)
(def routine-player-death 11)
(def routine-fire-flower 12)

(def state-on-ground 0)
(def state-jump-swim 1)
(def state-falling 2)
(def state-climbing 3)

(def addr-frame-counter 0x0009)
(def addr-a-b-buttons 0x000a)
(def addr-up-down-buttons 0x000b)
(def addr-left-right-buttons 0x000c)
(def addr-previous-a-b-buttons 0x000d)
(def addr-game-routine 0x000e)
(def addr-enemy-flag 0x000f)
(def addr-enemy-id 0x0016)
(def addr-enemy-state 0x001e)
(def addr-block-state 0x0026)
(def addr-misc-state 0x002a)
(def addr-power-up-type 0x0039)
(def addr-player-state 0x001d)
(def addr-player-facing 0x0033)
(def addr-player-moving 0x0045)
(def addr-player-x-speed 0x0057)
(def addr-block-x-speed 0x0060)
(def addr-player-page 0x006d)
(def addr-enemy-page 0x006e)
(def addr-block-page 0x0076)
(def addr-misc-page 0x007a)
(def addr-player-x 0x0086)
(def addr-enemy-x 0x0087)
(def addr-block-x 0x008f)
(def addr-misc-x 0x0093)
(def addr-player-y-speed 0x009f)
(def addr-block-y-speed 0x00a8)
(def addr-misc-y-speed 0x00ac)
(def addr-player-y-high 0x00b5)
(def addr-enemy-y-high 0x00b6)
(def addr-block-y-high 0x00be)
(def addr-misc-y-high 0x00c2)
(def addr-player-y 0x00ce)
(def addr-enemy-y 0x00cf)
(def addr-block-y 0x00d7)
(def addr-misc-y 0x00db)
(def addr-square1-sound 0x00ff)
(def addr-square2-sound 0x00fe)
(def addr-noise-sound 0x00fd)
(def addr-area-music 0x00fb)
(def addr-event-music 0x00fc)
(def addr-vram-buffer-offset 0x0300)
(def addr-horizontal-platform-scroll 0x03a1)
(def addr-relative-x 0x03ad)
(def addr-relative-y 0x03b8)
(def addr-player-sprite-attribute 0x03c4)
(def addr-enemy-sprite-attribute 0x03c5)
(def addr-offscreen-bits 0x03d0)
(def addr-block-origin-y 0x03e4)
(def addr-block-buffer-low 0x03e6)
(def addr-block-metatile 0x03e8)
(def addr-block-page2 0x03ea)
(def addr-block-replace 0x03ec)
(def addr-block-toggle 0x03ee)
(def addr-block-origin-x 0x03f1)
(def addr-player-y-fraction 0x0416)
(def addr-player-y-force 0x0433)
(def addr-block-y-force 0x043c)
(def addr-max-left-speed 0x0450)
(def addr-max-right-speed 0x0456)
(def addr-collision-bits 0x0490)
(def addr-bounding-box-control 0x0499)
(def addr-enemy-bounding-box-control 0x049a)
(def addr-block-buffer1 0x0500)
(def addr-block-buffer2 0x05d0)
(def addr-jump-coin-misc-offset 0x06b7)
(def addr-brick-coin-timer-flag 0x06bc)
(def addr-player-gfx-offset 0x06d5)
(def addr-sprite-data-offset 0x06e4)
(def addr-warp-zone-control 0x06d6)
(def addr-jump-spring-force 0x06db)
(def addr-change-area-timer 0x06de)
(def addr-player-scroll 0x06ff)
(def addr-player-x-absolute 0x0700)
(def addr-friction-high 0x0701)
(def addr-friction-low 0x0702)
(def addr-running-speed 0x0703)
(def addr-swimming 0x0704)
(def addr-player-x-fraction 0x0705)
(def addr-diff-to-halt-jump 0x0706)
(def addr-jump-origin-y-high 0x0707)
(def addr-jump-origin-y 0x0708)
(def addr-vertical-force 0x0709)
(def addr-vertical-force-down 0x070a)
(def addr-change-size-flag 0x070b)
(def addr-animation-set 0x070c)
(def addr-animation-control 0x070d)
(def addr-jump-spring-animation 0x070e)
(def addr-fireball-throwing-timer 0x0711)
(def addr-player-entrance-control 0x0710)
(def addr-player-death-music 0x0712)
(def addr-flagpole-sound 0x0713)
(def addr-player-crouching 0x0714)
(def addr-whirlpool-flag 0x047d)
(def addr-disable-collision 0x0716)
(def addr-screen-left-page 0x071a)
(def addr-screen-right-page 0x071b)
(def addr-screen-left-x 0x071c)
(def addr-screen-right-x 0x071d)
(def addr-sprite-zero-hit 0x0722)
(def addr-scroll-lock 0x0723)
(def addr-star-flag-task 0x0746)
(def addr-star-flag-timer 0x0747)
(def addr-area-type 0x074e)
(def addr-player-entrance 0x0751)
(def addr-alt-entrance 0x0752)
(def addr-current-player 0x0753)
(def addr-player-size 0x0754)
(def addr-player-position-for-scroll 0x0755)
(def addr-primary-mode 0x0770)
(def addr-mode-task 0x0772)
(def addr-vram-address-control 0x0773)
(def addr-disable-screen 0x0774)
(def addr-player-status 0x0756)
(def addr-joypad-override 0x0758)
(def addr-game-timer-expired 0x0759)
(def addr-lives 0x075a)
(def addr-animation-timer 0x0781)
(def addr-jump-swim-timer 0x0782)
(def addr-running-timer 0x0783)
(def addr-block-bounce-timer 0x0784)
(def addr-side-collision-timer 0x0785)
(def addr-jump-spring-timer 0x0786)
(def addr-climb-side-timer 0x0789)
(def addr-injury-timer 0x079e)
(def addr-brick-coin-timer 0x079d)
(def addr-event-music-buffer 0x07b1)
(def addr-coin-tally 0x075e)
(def addr-digit-modifier-minus-one 0x0133)
(def addr-score-digits 0x07d7)

(def jump-y-speeds @[-4 -4 -4 -5 -5 -2 -1])
(def jump-forces @[0x20 0x20 0x1e 0x28 0x28 0x0d 0x04])
(def jump-down-forces @[0x70 0x70 0x60 0x90 0x90 0x0a 0x09])
(def jump-initial-forces @[0 0 0 0 0 0x80 0])
(def max-left-speeds @[0xd8 0xe8 0xf0])
(def max-right-speeds @[0x28 0x18 0x10])
(def friction-values @[0xe4 0x98 0xd0])
(def climb-x-adders @[-118 -7 7 -1])
(def climb-page-adders @[7 -1 0 24])
(def collision-x-adders @[8 3 12 2 2 13 13
                          8 3 12 2 2 13 13
                          8 3 12 2 2 13 13
                          8 0 16 4 20 4 4])
(def movement-climb-adders @[14 4 -4 -14])
(def collision-y-adders @[4 32 32 8 24 8 24
                          2 32 32 8 24 8 24
                          18 32 32 24 24 24 24
                          24 20 20 6 6 8 16])
(def bounding-boxes @[@[2 8 14 32] @[3 20 13 32] @[2 20 14 32]
                      @[2 9 14 21] @[0 0 24 6] @[0 0 32 13]
                      @[0 0 48 13] @[0 0 8 8] @[6 4 10 8]
                      @[3 14 13 20] @[0 2 16 21] @[4 4 12 28]])

(defn- read8 [ram address] (get ram address))
(defn- write8! [ram address value] (put ram address (bytes/u8 value)))
(defn- bit? [value mask] (not= 0 (band value mask)))

(defn- set-player-x-position!
  [ram position]
  (write8! ram addr-player-page (bytes/high-u16 position))
  (write8! ram addr-player-x (bytes/low-u16 position)))

(defn- add-player-x-position!
  [ram amount]
  (set-player-x-position!
    ram
    (bytes/u16 (+ (bytes/pack-u16 (read8 ram addr-player-page)
                                  (read8 ram addr-player-x))
                  amount))))

(defn- set-player-y-position!
  [ram position]
  (write8! ram addr-player-y-high (bytes/high-u16 position))
  (write8! ram addr-player-y (bytes/low-u16 position)))

(defn- add-player-y-position!
  [ram amount]
  (set-player-y-position!
    ram
    (bytes/u16 (+ (bytes/pack-u16 (read8 ram addr-player-y-high)
                                  (read8 ram addr-player-y))
                  amount))))

(defn- get-player-animation-speed!
  [ram]
  (def speed (read8 ram addr-player-x-absolute))
  (if (< speed 0x1c)
    (do
      (write8! ram addr-animation-set (if (< speed 0x0e) 7 4))
      (when (not= 0 (band (read8 ram 0x06fc) (bnot button-a)))
        (if (= (band (read8 ram 0x06fc) (bor button-left button-right))
               (read8 ram addr-player-moving))
          (write8! ram addr-running-speed 0)
          (when (< speed 0x0b)
            (write8! ram addr-player-moving (read8 ram addr-player-facing))
            (write8! ram addr-player-x-speed 0)
            (write8! ram addr-player-x-fraction 0)))))
    (do
      (write8! ram addr-animation-set 2)
      (write8! ram addr-running-speed speed))))

(defn impose-friction!
  [ram]
  (def collision (read8 ram addr-collision-bits))
  (def direction (band (read8 ram addr-left-right-buttons) collision))
  (def speed (read8 ram addr-player-x-speed))
  (def go-left
    (if (= direction 0)
      (if (= speed 0) nil (>= speed 0x80))
      (bit? direction button-right)))
  (when (not= nil go-left)
    (def friction (bytes/pack-u16 (read8 ram addr-friction-high)
                                  (read8 ram addr-friction-low)))
    (var velocity (bytes/pack-u16 speed (read8 ram addr-player-x-fraction)))
    (if go-left
      (do
        (set velocity (bytes/u16 (+ velocity friction)))
        (write8! ram addr-player-x-speed (bytes/high-u16 velocity))
        (write8! ram addr-player-x-fraction (bytes/low-u16 velocity))
        (when (< (bytes/u8 (- (read8 ram addr-player-x-speed)
                              (read8 ram addr-max-right-speed)))
                 0x80)
          (write8! ram addr-player-x-speed (read8 ram addr-max-right-speed))))
      (do
        (set velocity (bytes/u16 (- velocity friction)))
        (write8! ram addr-player-x-speed (bytes/high-u16 velocity))
        (write8! ram addr-player-x-fraction (bytes/low-u16 velocity))
        (when (>= (bytes/u8 (- (read8 ram addr-player-x-speed)
                               (read8 ram addr-max-left-speed)))
                  0x80)
          (write8! ram addr-player-x-speed (read8 ram addr-max-left-speed)))))
    (write8! ram addr-player-x-absolute
             (if (< (read8 ram addr-player-x-speed) 0x80)
               (read8 ram addr-player-x-speed)
               (bytes/u8 (- 0 (read8 ram addr-player-x-speed))))))
  ram)

(defn physics!
  [world]
  (def ram (world :ram))
  (if (= (read8 ram addr-player-state) state-climbing)
    (do
      (if (not= 0 (band (read8 ram addr-up-down-buttons)
                        (read8 ram addr-collision-bits)))
        (if (bit? (read8 ram addr-up-down-buttons) button-down)
          (do
            (write8! ram addr-player-y-force 0xff)
            (write8! ram addr-player-y-speed 1)
            (write8! ram addr-animation-set 4))
          (do
            (write8! ram addr-player-y-force 0x20)
            (write8! ram addr-player-y-speed 0xff)
            (write8! ram addr-animation-set 8)))
        (do
          (write8! ram addr-player-y-force 0)
          (write8! ram addr-player-y-speed 0)
          (write8! ram addr-animation-set 4)))
      ram)
    (do
      (def newly-pressed-a
        (and (bit? (read8 ram addr-a-b-buttons) button-a)
             (not (bit? (read8 ram addr-previous-a-b-buttons) button-a))))
      (when (and newly-pressed-a
                 (= (read8 ram addr-jump-spring-animation) 0)
                 (or (= (read8 ram addr-player-state) state-on-ground)
                     (and (not= (read8 ram addr-swimming) 0)
                          (or (not= (read8 ram addr-jump-swim-timer) 0)
                              (< (read8 ram addr-player-y-speed) 0x80)))))
        (write8! ram addr-jump-swim-timer 0x20)
        (write8! ram addr-player-y-fraction 0)
        (write8! ram addr-jump-origin-y-high (read8 ram addr-player-y-high))
        (write8! ram addr-jump-origin-y (read8 ram addr-player-y))
        (write8! ram addr-player-state state-jump-swim)
        (def absolute-speed (read8 ram addr-player-x-absolute))
        (def jump-index
          (if (not= (read8 ram addr-swimming) 0)
            (if (= (read8 ram addr-whirlpool-flag) 0) 5 6)
            (if (<= absolute-speed 8)
              0
              (if (< absolute-speed 16)
                1
                (if (<= absolute-speed 24)
                  2
                  (if (< absolute-speed 28) 3 4))))))
        (write8! ram addr-player-y-force (get jump-initial-forces jump-index))
        (write8! ram addr-player-y-speed (get jump-y-speeds jump-index))
        (write8! ram addr-vertical-force (get jump-forces jump-index))
        (write8! ram addr-vertical-force-down (get jump-down-forces jump-index))
        (write8! ram addr-diff-to-halt-jump 1)
        (if (not= (read8 ram addr-swimming) 0)
          (do
            (write8! ram addr-square1-sound 4)
            (when (< (read8 ram addr-player-y) 0x14)
              (write8! ram addr-player-y-speed 0)))
          (write8! ram addr-square1-sound
                   (if (= (read8 ram addr-player-size) 0) 1 0x80))))

      (def matching-direction
        (= (read8 ram addr-left-right-buttons)
           (read8 ram addr-player-moving)))
      (def running
        (and matching-direction
             (bit? (read8 ram addr-a-b-buttons) button-b)))
      (var physics-index 1)
      (if (= (read8 ram addr-player-state) state-on-ground)
        (when (not= (read8 ram addr-area-type) 0)
          (when running
            (write8! ram addr-running-timer 0x0a))
          (when (and matching-direction
                     (not= (read8 ram addr-running-timer) 0))
            (set physics-index 0)))
        (when (> (read8 ram addr-player-x-absolute) 0x18)
          (set physics-index 0)))
      (var speed-index
        (if (and (= (read8 ram addr-player-state) state-on-ground)
                 (= (read8 ram addr-area-type) 0))
          1
          0))
      (when (not= physics-index 0)
        (set speed-index (inc speed-index))
        (when (or (not= (read8 ram addr-running-speed) 0)
                  (> (read8 ram addr-player-x-absolute) 0x20))
          (set physics-index 2)))
      (write8! ram addr-max-left-speed (get max-left-speeds speed-index))
      (write8! ram addr-max-right-speed
               (if (= (read8 ram addr-game-routine) routine-player-entrance)
                 0x0c
                 (get max-right-speeds speed-index)))
      (var friction (get friction-values physics-index))
      (when (not= (read8 ram addr-player-facing)
                  (read8 ram addr-player-moving))
        (set friction (* friction 2)))
      (write8! ram addr-friction-high (bytes/high-u16 friction))
      (write8! ram addr-friction-low (bytes/low-u16 friction))
      ram)))

(defn- move-player-horizontally!
  [ram]
  (if (= (read8 ram addr-jump-spring-animation) 0)
    (movement/move-object-horizontally! ram 0)
    (read8 ram addr-jump-spring-animation)))

(defn- move-player-vertically!
  [ram]
  (when (or (not= (read8 ram 0x0747) 0)
            (= (read8 ram addr-jump-spring-animation) 0))
    (movement/impose-gravity! ram false 0
                              (read8 ram addr-vertical-force)
                              0
                              4)))

(defn- left-right-air!
  [ram]
  (when (not= (read8 ram addr-left-right-buttons) 0)
    (impose-friction! ram))
  (write8! ram addr-player-scroll (move-player-horizontally! ram))
  (when (= (read8 ram addr-game-routine) routine-player-death)
    (write8! ram addr-vertical-force 0x28))
  (move-player-vertically! ram))

(defn- climbing-state!
  [ram]
  (def position
    (bytes/add-signed-u24-u16
      (read8 ram addr-player-y-high)
      (read8 ram addr-player-y)
      (read8 ram addr-player-y-fraction)
      (read8 ram addr-player-y-speed)
      (read8 ram addr-player-y-force)))
  (write8! ram addr-player-y-high (bytes/high-u24 position))
  (write8! ram addr-player-y (bytes/middle-u24 position))
  (write8! ram addr-player-y-fraction (bytes/low-u24 position))
  (def direction
    (band (read8 ram addr-left-right-buttons)
          (read8 ram addr-collision-bits)))
  (if (= direction 0)
    (write8! ram addr-climb-side-timer 0)
    (when (= (read8 ram addr-climb-side-timer) 0)
      (write8! ram addr-climb-side-timer 0x18)
      (var index (if (= (band direction button-right) 0) 2 0))
      (when (not= (read8 ram addr-player-facing) button-right)
        (set index (inc index)))
      (add-player-x-position! ram (get movement-climb-adders index))
      (write8! ram addr-player-facing
               (bxor (read8 ram addr-left-right-buttons) 3)))))

(defn movement!
  [world]
  (def ram (world :ram))
  (var crouching 0)
  (when (= (read8 ram addr-player-size) 0)
    (set crouching (read8 ram addr-player-crouching))
    (when (= (read8 ram addr-player-state) state-on-ground)
      (set crouching (band (read8 ram addr-up-down-buttons) button-down))))
  (write8! ram addr-player-crouching crouching)
  (physics! world)
  (when (= (read8 ram addr-change-size-flag) 0)
    (when (not= (read8 ram addr-player-state) state-climbing)
      (write8! ram addr-climb-side-timer 0x18))
    (case (read8 ram addr-player-state)
      0 (do
          (get-player-animation-speed! ram)
          (when (not= (read8 ram addr-left-right-buttons) 0)
            (write8! ram addr-player-facing (read8 ram addr-left-right-buttons)))
          (impose-friction! ram)
          (write8! ram addr-player-scroll (move-player-horizontally! ram)))
      1 (do
          (when (or (< (read8 ram addr-player-y-speed) 0x80)
                    (and (= (band (read8 ram addr-a-b-buttons)
                                  button-a
                                  (read8 ram addr-previous-a-b-buttons))
                            0)
                         (<= (read8 ram addr-diff-to-halt-jump)
                             (bytes/u8 (- (read8 ram addr-jump-origin-y)
                                          (read8 ram addr-player-y))))))
            (write8! ram addr-vertical-force
                     (read8 ram addr-vertical-force-down)))
          (when (not= (read8 ram addr-swimming) 0)
            (get-player-animation-speed! ram)
            (when (< (read8 ram addr-player-y) 0x14)
              (write8! ram addr-vertical-force 0x18))
            (when (not= (read8 ram addr-left-right-buttons) 0)
              (write8! ram addr-player-facing
                       (read8 ram addr-left-right-buttons))))
          (left-right-air! ram))
      2 (do
          (write8! ram addr-vertical-force
                   (read8 ram addr-vertical-force-down))
          (left-right-air! ram))
      3 (climbing-state! ram)))
  ram)

(defn- get-metatile
  [ram mt-x mt-y]
  (if (or (< mt-y 0) (>= mt-y 13))
    0
    (get ram (+ (if (< (% mt-x 32) 16)
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

(defn- collision-probe
  [ram use-x index]
  (def object-x-position
    (bytes/pack-u16 (read8 ram addr-player-page)
                    (read8 ram addr-player-x)))
  (def x-position (+ object-x-position (get collision-x-adders index)))
  (def y-position (+ (read8 ram addr-player-y)
                     (get collision-y-adders index)))
  (def mt-x (div x-position 16))
  (def mt-y (- (div y-position 16) 2))
  @[(get-metatile ram mt-x mt-y)
    (band (if use-x object-x-position (read8 ram addr-player-y)) 0x0f)
    mt-x
    mt-y])

(defn- solid-metatile?
  [tile]
  (or (and (>= tile 0x10) (<= tile 0x3f))
      (and (>= tile 0x61) (<= tile 0x7f))
      (and (>= tile 0x88) (<= tile 0xbf))
      (>= tile 0xc4)))

(defn- climb-metatile?
  [tile]
  (or (and (>= tile 0x24) (< tile 0x40))
      (and (>= tile 0x6d) (< tile 0x80))
      (and (>= tile 0x8a) (< tile 0xc0))
      (>= tile 0xc6)))

(defn- item-block?
  [tile]
  (or (= tile 0xc0) (= tile 0xc1) (= tile 0x5f) (= tile 0x60)
      (= tile 0x55) (= tile 0x56) (= tile 0x57) (= tile 0x58)
      (= tile 0x59) (= tile 0x5a) (= tile 0x5b) (= tile 0x5c)
      (= tile 0x5d) (= tile 0x5e)))

(defn digits-math!
  [ram digit-offset]
  (when (not= (read8 ram addr-primary-mode) 0)
    (loop [step :range [0 6]]
      (def index (- 6 step))
      (def modifier-address (+ addr-digit-modifier-minus-one index))
      (def digit-address (+ addr-score-digits digit-offset index -6))
      (var value
        (bytes/u8 (+ (read8 ram modifier-address)
                     (read8 ram digit-address))))
      (if (< value 0x80)
        (do
          (when (>= value 10)
            (set value (- value 10))
            (write8! ram (dec modifier-address)
                     (inc (read8 ram (dec modifier-address)))))
          (write8! ram digit-address value))
        (do
          (write8! ram (dec modifier-address)
                   (dec (read8 ram (dec modifier-address))))
          (write8! ram digit-address 9)))))
  (for i 0 7
    (write8! ram (+ addr-digit-modifier-minus-one i) 0)))

(defn- output-number!
  [ram parameter]
  (def kind (band (inc parameter) 0x0f))
  (when (< kind 6)
    (def x-positions @[16 2 2 13 13 26])
    (def y-positions @[23 3 3 3 3 3])
    (def lengths @[6 6 6 2 2 3])
    (def digit-offsets @[0x06 0x0c 0x12 0x18 0x1e 0x24])
    (def length (get lengths kind))
    (var offset (read8 ram addr-vram-buffer-offset))
    (def address (bor 0x2000
                      (* (get y-positions kind) 32)
                      (get x-positions kind)))
    (write8! ram (+ 0x0301 offset) (bytes/high-u16 address))
    (write8! ram (+ 0x0302 offset) (bytes/low-u16 address))
    (write8! ram (+ 0x0303 offset) length)
    (loop [step :range [0 length]]
      (def index (- length step))
      (write8! ram (+ 0x0304 offset)
               (read8 ram (+ addr-score-digits
                             (get digit-offsets kind)
                             (- index))))
      (++ offset))
    (write8! ram (+ 0x0304 offset) 0)
    (write8! ram addr-vram-buffer-offset (+ offset 3))))

(defn- write-score-and-coin!
  [ram]
  (def parameter (if (= (read8 ram addr-current-player) 0) 2 0x13))
  (output-number! ram parameter)
  (output-number! ram (brshift parameter 4))
  (def address (+ 0x0301 (read8 ram addr-vram-buffer-offset) -6))
  (when (= (read8 ram address) 0)
    (write8! ram address 0x24)))

(defn- give-one-coin!
  [ram]
  (write8! ram (+ addr-digit-modifier-minus-one 6) 1)
  (digits-math! ram (if (= (read8 ram addr-current-player) 0) 0x17 0x1d))
  (write8! ram addr-coin-tally (inc (read8 ram addr-coin-tally)))
  (when (= (read8 ram addr-coin-tally) 100)
    (write8! ram addr-coin-tally 0)
    (write8! ram addr-lives (inc (read8 ram addr-lives)))
    (write8! ram addr-square2-sound 0x40))
  (write8! ram (+ addr-digit-modifier-minus-one 5) 2)
  (digits-math! ram (if (= (read8 ram addr-current-player) 0) 11 17))
  (write-score-and-coin! ram))

(defn- remove-coin!
  [ram mt-x mt-y]
  (def x (* (% mt-x 16) 2))
  (def y (* (+ mt-y 2) 2))
  (def nametable (if (< (% mt-x 32) 16) 0x20 0x24))
  (def address (bor (blshift nametable 8) (* y 32) x))
  (write8! ram 0x0341 (bytes/high-u16 address))
  (write8! ram 0x0342 (bytes/low-u16 address))
  (write8! ram 0x0343 2)
  (def tiles (if (= (read8 ram addr-area-type) 0) 0x26 0x24))
  (write8! ram 0x0344 tiles)
  (write8! ram 0x0345 tiles)
  (write8! ram 0x0346 (bytes/high-u16 (+ address 32)))
  (write8! ram 0x0347 (bytes/low-u16 (+ address 32)))
  (write8! ram 0x0348 2)
  (write8! ram 0x0349 tiles)
  (write8! ram 0x034a tiles)
  (write8! ram 0x034b 0)
  (write8! ram addr-vram-address-control 6))

(defn- handle-coin!
  [ram mt-x mt-y]
  (set-metatile! ram mt-x mt-y 0)
  (remove-coin! ram mt-x mt-y)
  (write8! ram 0x0748 (inc (read8 ram 0x0748)))
  (give-one-coin! ram)
  (write8! ram addr-square2-sound 1))

(defn- handle-axe!
  [ram mt-x mt-y]
  (write8! ram modes/oper-mode-address modes/victory)
  (write8! ram modes/oper-mode-task-address modes/victory-bridge-collapse)
  (write8! ram addr-player-x-speed 0x18)
  (set-metatile! ram mt-x mt-y 0)
  (remove-coin! ram mt-x mt-y))

(defn- draw-blank-block!
  [ram mt-x mt-y]
  (def offset (inc (read8 ram addr-vram-buffer-offset)))
  (def tile-x (* (% mt-x 16) 2))
  (def tile-y (* (+ mt-y 2) 2))
  (def nametable (if (< (% mt-x 32) 16) 0x20 0x24))
  (def address (bor (blshift nametable 8) (* tile-y 32) tile-x))
  (write8! ram (+ addr-vram-buffer-offset offset) (bytes/high-u16 address))
  (write8! ram (+ addr-vram-buffer-offset offset 1) (bytes/low-u16 address))
  (write8! ram (+ addr-vram-buffer-offset offset 2) 2)
  (write8! ram (+ addr-vram-buffer-offset offset 3) 0x24)
  (write8! ram (+ addr-vram-buffer-offset offset 4) 0x24)
  (write8! ram (+ addr-vram-buffer-offset offset 5) (bytes/high-u16 (+ address 32)))
  (write8! ram (+ addr-vram-buffer-offset offset 6) (bytes/low-u16 (+ address 32)))
  (write8! ram (+ addr-vram-buffer-offset offset 7) 2)
  (write8! ram (+ addr-vram-buffer-offset offset 8) 0x24)
  (write8! ram (+ addr-vram-buffer-offset offset 9) 0x24)
  (write8! ram (+ addr-vram-buffer-offset offset 10) 0)
  (write8! ram addr-vram-buffer-offset (+ (read8 ram addr-vram-buffer-offset) 10)))

(defn- find-empty-jump-coin-slot!
  [ram]
  (var slot 8)
  (while (and (>= slot 6)
              (not= (read8 ram (+ addr-misc-state slot)) 0))
    (-- slot))
  (when (< slot 6)
    (set slot 8))
  (write8! ram addr-jump-coin-misc-offset slot)
  slot)

(defn- setup-jumping-coin!
  [ram slot]
  (write8! ram (+ addr-misc-y-speed slot) 0xfb)
  (write8! ram (+ addr-misc-y-high slot) 1)
  (write8! ram (+ addr-misc-state slot) 1)
  (write8! ram addr-square2-sound 1)
  (give-one-coin! ram)
  (write8! ram 0x0748 (inc (read8 ram 0x0748))))

(defn- coin-block!
  [ram block-slot]
  (def misc-slot (find-empty-jump-coin-slot! ram))
  (write8! ram (+ addr-misc-page misc-slot)
           (read8 ram (+ addr-block-page block-slot)))
  (write8! ram (+ addr-misc-x misc-slot)
           (bor (read8 ram (+ addr-block-x block-slot)) 5))
  (write8! ram (+ addr-misc-y misc-slot)
           (- (read8 ram (+ addr-block-y block-slot)) 0x10))
  (when (= (read8 ram (+ addr-misc-state 8)) 0)
    (write8! ram (+ addr-misc-y misc-slot)
             (dec (read8 ram (+ addr-misc-y misc-slot)))))
  (setup-jumping-coin! ram misc-slot))

(defn- check-top-of-block!
  [ram block-slot mt-x mt-y]
  (if (and (> mt-y 0) (= (get-metatile ram mt-x (dec mt-y)) 0xc2))
    (do
      (def above-y (dec mt-y))
      (set-metatile! ram mt-x above-y 0)
      (remove-coin! ram mt-x above-y)
      (def misc-slot (find-empty-jump-coin-slot! ram))
      (write8! ram (+ addr-misc-page misc-slot)
               (read8 ram (+ addr-block-page2 block-slot)))
      (write8! ram (+ addr-misc-x misc-slot) (+ (* mt-x 16) 5))
      (write8! ram (+ addr-misc-y misc-slot)
               (+ (* above-y 16) 32 (if (zero? (band mt-x 0x10)) 0 1)))
      (setup-jumping-coin! ram misc-slot)
      true)
    false))

(defn- setup-power-up!
  [ram block-slot type]
  (write8! ram addr-power-up-type type)
  (write8! ram (+ addr-enemy-id 5) 0x2e)
  (write8! ram (+ addr-enemy-page 5)
           (read8 ram (+ addr-block-page block-slot)))
  (write8! ram (+ addr-enemy-x 5)
           (read8 ram (+ addr-block-x block-slot)))
  (write8! ram (+ addr-enemy-y-high 5) 1)
  (write8! ram (+ addr-enemy-y 5)
           (- (read8 ram (+ addr-block-y block-slot)) 8))
  (write8! ram (+ addr-enemy-state 5) 1)
  (write8! ram (+ addr-enemy-flag 5) 1)
  (write8! ram (+ addr-enemy-bounding-box-control 5) 3)
  (when (or (= type 0) (= type 1))
    (write8! ram addr-power-up-type
             (if (zero? (read8 ram addr-player-status)) 0 1)))
  (write8! ram (+ addr-enemy-sprite-attribute 5) 0x20)
  (write8! ram addr-square2-sound 2))

(defn- setup-vine!
  [ram block-slot]
  (write8! ram (+ addr-enemy-id 5) 0x2f)
  (write8! ram (+ addr-enemy-flag 5) 1)
  (write8! ram (+ addr-enemy-page 5)
           (read8 ram (+ addr-block-page block-slot)))
  (write8! ram (+ addr-enemy-x 5)
           (read8 ram (+ addr-block-x block-slot)))
  (write8! ram (+ addr-enemy-y 5)
           (read8 ram (+ addr-block-y block-slot)))
  (def vine-offset (read8 ram 0x0398))
  (when (zero? vine-offset)
    (write8! ram 0x039d (read8 ram (+ addr-enemy-y 5))))
  (write8! ram (+ 0x039a vine-offset) 5)
  (write8! ram 0x0398 (inc vine-offset))
  (write8! ram addr-square2-sound 4))

(defn- setup-block-item!
  [ram block-slot tile]
  (case tile
    0xc1 (setup-power-up! ram block-slot 0)
    0x55 (setup-power-up! ram block-slot 0)
    0x5a (setup-power-up! ram block-slot 0)
    0xc0 (coin-block! ram block-slot)
    0x5f (coin-block! ram block-slot)
    0x58 (coin-block! ram block-slot)
    0x5d (coin-block! ram block-slot)
    0x60 (setup-power-up! ram block-slot 3)
    0x59 (setup-power-up! ram block-slot 3)
    0x5e (setup-power-up! ram block-slot 3)
    0x56 (setup-vine! ram block-slot)
    0x5b (setup-vine! ram block-slot)
    0x57 (setup-power-up! ram block-slot 2)
    0x5c (setup-power-up! ram block-slot 2)
    nil))

(defn- player-head-collision!
  [ram mt-x mt-y]
  (def block-slot (read8 ram addr-block-toggle))
  (write8! ram (+ addr-block-state block-slot)
           (if (= (read8 ram addr-player-size) 0) 0x12 0x11))
  (draw-blank-block! ram mt-x mt-y)
  (write8! ram (+ addr-block-origin-y block-slot) (* mt-y 16))
  (write8! ram (+ addr-block-buffer-low block-slot)
           (+ (if (< (% mt-x 32) 16) 0 0xd0) (% mt-x 16)))
  (def tile (get-metatile ram mt-x mt-y))
  (if (item-block? tile)
    (do
      (write8! ram (+ addr-block-state block-slot) 0x11)
      (if (or (= tile 0x58) (= tile 0x5d))
        (do
          (when (zero? (read8 ram addr-brick-coin-timer-flag))
            (write8! ram addr-brick-coin-timer 0x0b)
            (write8! ram addr-brick-coin-timer-flag 1))
          (write8! ram (+ addr-block-metatile block-slot)
                   (if (zero? (read8 ram addr-brick-coin-timer))
                     0xc4 tile)))
        (write8! ram (+ addr-block-metatile block-slot) 0xc4)))
    (write8! ram (+ addr-block-metatile block-slot)
             (if (= (read8 ram addr-player-size) 0) 0 tile)))
  (def block-position
    (bytes/add-u16 (read8 ram addr-player-page)
                   (read8 ram addr-player-x) 0 8))
  (write8! ram (+ addr-block-page block-slot)
           (bytes/high-u16 block-position))
  (write8! ram (+ addr-block-x block-slot)
           (band (bytes/low-u16 block-position) 0xf0))
  (write8! ram (+ addr-block-page2 block-slot)
           (read8 ram (+ addr-block-page block-slot)))
  (write8! ram (+ addr-block-y-high block-slot)
           (read8 ram addr-player-y-high))
  (set-metatile! ram mt-x mt-y 0x23)
  (write8! ram addr-block-bounce-timer 0x10)
  (write8! ram (+ addr-block-y block-slot)
           (band (+ (read8 ram addr-player-y)
                    (if (and (zero? (read8 ram addr-player-crouching))
                             (zero? (read8 ram addr-player-size)))
                      4 0x12))
                 0xf0))
  (def coin-above?
    (check-top-of-block! ram block-slot mt-x mt-y))
  (if (= (read8 ram (+ addr-block-state block-slot)) 0x11)
    (do
      (write8! ram addr-square1-sound 2)
      (write8! ram (+ addr-block-x-speed block-slot) 0)
      (write8! ram (+ addr-block-y-force block-slot) 0)
      (write8! ram addr-player-y-speed 0)
      (write8! ram (+ addr-block-y-speed block-slot) 0xfe)
      (unless coin-above?
        (setup-block-item! ram block-slot tile)))
    (do
      (write8! ram (+ addr-block-replace block-slot) 1)
      (write8! ram addr-noise-sound 1)
      (write8! ram (+ addr-block-origin-x block-slot)
               (read8 ram (+ addr-block-x block-slot)))
      (write8! ram (+ addr-block-x-speed block-slot) 0xf0)
      (write8! ram (+ addr-block-x-speed block-slot 2) 0xf0)
      (write8! ram (+ addr-block-y-speed block-slot) 0xfa)
      (write8! ram (+ addr-block-y-speed block-slot 2) 0xfc)
      (write8! ram (+ addr-block-y-force block-slot) 0)
      (write8! ram (+ addr-block-y-force block-slot 2) 0)
      (write8! ram (+ addr-block-page block-slot 2)
               (read8 ram (+ addr-block-page block-slot)))
      (write8! ram (+ addr-block-x block-slot 2)
               (read8 ram (+ addr-block-x block-slot)))
      (write8! ram (+ addr-block-y block-slot 2)
               (+ (read8 ram (+ addr-block-y block-slot)) 8))
      (write8! ram addr-player-y-speed 0xfe)
      (write8! ram (+ addr-digit-modifier-minus-one 6) 5)
      (digits-math! ram (if (= (read8 ram addr-current-player) 0) 11 17))
      (write-score-and-coin! ram)))
  (write8! ram addr-block-toggle (bxor block-slot 1)))

(defn impede-player!
  [ram direction]
  (def speed (read8 ram addr-player-x-speed))
  (def move?
    (if (= direction button-right)
      (< speed 0x80)
      (>= (bytes/u8 (- speed 1)) 0x80)))
  (when move?
    (write8! ram addr-side-collision-timer 0x10)
    (write8! ram addr-player-x-speed 0)
    (add-player-x-position! ram (if (= direction button-right) -1 1)))
  (write8! ram addr-collision-bits
           (band (read8 ram addr-collision-bits) (bnot direction))))

(defn- handle-climbing!
  [ram tile fraction mt-x]
  (when (and (>= fraction 6) (< fraction 10))
    (when (or (= tile 0x24) (= tile 0x25))
      (when (not= (read8 ram addr-game-routine) 5)
        (write8! ram addr-player-facing button-right)
        (write8! ram addr-scroll-lock (inc (read8 ram addr-scroll-lock)))
        (when (not= (read8 ram addr-game-routine) 4)
          (loop [slot :range [0 5]]
            (when (= (read8 ram (+ 0x0016 slot)) 0x33)
              (write8! ram (+ 0x000f slot) 0)))
          (write8! ram addr-event-music 0x80)
          (write8! ram addr-flagpole-sound 0x40)
          (write8! ram 0x070f (read8 ram addr-player-y))
          (var score 0)
          (def score-heights @[24 34 80 104 144])
          (loop [step :range [0 4]
                 :while (= score 0)]
            (def index (- 4 step))
            (when (<= (get score-heights index) (read8 ram addr-player-y))
              (set score index)))
          (write8! ram 0x010f score))
        (write8! ram addr-game-routine 4)))
    (when (and (= tile 0x26) (< (read8 ram addr-player-y) 0x20))
      (write8! ram addr-game-routine routine-vine-auto-climb))
    (write8! ram addr-player-state state-climbing)
    (write8! ram addr-player-x-speed 0)
    (write8! ram addr-player-x-fraction 0)
    (when (< (bytes/u8 (- (read8 ram addr-player-x)
                          (read8 ram addr-screen-left-x)))
             0x10)
      (write8! ram addr-player-facing button-left))
    (def facing (read8 ram addr-player-facing))
    (write8! ram addr-player-x
             (+ (* (% mt-x 16) 16) (get climb-x-adders facing)))
    (when (= (% mt-x 32) 0)
      (write8! ram addr-player-page
               (+ (read8 ram addr-screen-right-page)
                  (get climb-page-adders facing))))))

(defn- handle-side-metatile!
  [ram tile fraction mt-x mt-y direction]
  (cond
    (or (= tile 0x5f) (= tile 0x60))
    nil

    (climb-metatile? tile)
    (handle-climbing! ram tile fraction mt-x)

    (or (= tile 0xc2) (= tile 0xc3))
    (handle-coin! ram mt-x mt-y)

    (or (= tile 0x67) (= tile 0x68))
    (when (= (read8 ram addr-jump-spring-animation) 0)
      (impede-player! ram direction))

    (and (or (= tile 0x1f) (= tile 0x6c))
         (= (read8 ram addr-player-state) state-on-ground)
         (= (read8 ram addr-player-facing) button-right))
    (do
      (when (= (read8 ram addr-player-sprite-attribute) 0)
        (write8! ram addr-square1-sound 0x10))
      (write8! ram addr-player-sprite-attribute
               (bor (read8 ram addr-player-sprite-attribute) 0x20))
      (when (not= (band (read8 ram addr-player-x) 0x0f) 0)
        (write8! ram addr-change-area-timer
                 (if (= (read8 ram addr-screen-left-page) 0) 0xa0 0x34)))
      (when (= (read8 ram addr-game-routine) routine-player-control)
        (write8! ram addr-game-routine routine-side-pipe)))

    true
    (impede-player! ram direction)))

(defn- handle-pipe-entry!
  [world left-tile right-tile]
  (def ram (world :ram))
  (when (and (= left-tile 0x10)
             (= right-tile 0x11)
             (bit? (read8 ram addr-up-down-buttons) button-down))
    (when (not= (read8 ram addr-warp-zone-control) 0)
      (def x (read8 ram addr-player-x))
      (def warp-offset
        (+ (* (band (read8 ram addr-warp-zone-control) 3) 4)
           (cond
             (< x 0x60) 0
             (< x 0xa0) 1
             true 2)))
      (write8! ram area/world-number-address
               (dec (rom/read-cpu (world :rom) (+ 0x87f2 warp-offset))))
      (write8! ram area/area-pointer-address
               (rom/read-cpu (world :rom)
                             (+ 0x9cbc
                                (rom/read-cpu (world :rom)
                                              (+ 0x9cb4
                                                 (read8 ram
                                                        area/world-number-address))))))
      (write8! ram addr-event-music 0x80)
      (write8! ram area/entrance-page-address 0)
      (write8! ram area/area-number-address 0)
      (write8! ram area/level-number-address 0)
      (write8! ram area/alternate-entrance-address 0)
      (write8! ram area/hidden-one-up-address
               (inc (read8 ram area/hidden-one-up-address)))
      (write8! ram 0x0757 (inc (read8 ram 0x0757))))
    (write8! ram addr-change-area-timer 0x30)
    (write8! ram addr-game-routine routine-vertical-pipe)
    (write8! ram addr-square1-sound 0x10)
    (write8! ram addr-player-sprite-attribute 0x20)))

(defn background-collision!
  [world]
  (def ram (world :ram))
  (unless (or (not= (read8 ram addr-disable-collision) 0)
              (= (read8 ram addr-game-routine) routine-entrance-setup)
              (= (read8 ram addr-game-routine) routine-vine-auto-climb)
              (= (read8 ram addr-game-routine) routine-side-pipe)
              (= (read8 ram addr-game-routine) routine-vertical-pipe)
              (= (read8 ram addr-game-routine) routine-player-death))
    (if (= (read8 ram addr-swimming) 0)
      (when (or (= (read8 ram addr-player-state) state-on-ground)
                (= (read8 ram addr-player-state) state-climbing))
        (write8! ram addr-player-state state-falling))
      (write8! ram addr-player-state state-jump-swim))
    (when (= (read8 ram addr-player-y-high) 1)
      (write8! ram addr-collision-bits 0xff)
      (when (<= (read8 ram addr-player-y) 0xce)
        (def probe-offset
          (if (and (= (read8 ram addr-player-crouching) 0)
                   (= (read8 ram addr-player-size) 0))
            (if (= (read8 ram addr-swimming) 0) 0 7)
            14))
        (def upper-extent
          (if (or (not= (read8 ram addr-player-size) 0)
                  (not= (read8 ram addr-player-crouching) 0))
            0x10
            0x20))
        (var finished false)
        (when (>= (read8 ram addr-player-y) upper-extent)
          (def head (collision-probe ram false probe-offset))
          (def tile (get head 0))
          (when (or (= tile 0xc2) (= tile 0xc3))
            (handle-coin! ram (get head 2) (get head 3))
            (set finished true))
          (when (and (not finished)
                     (not= tile 0)
                     (>= (read8 ram addr-player-y-speed) 0x80)
                     (>= (get head 1) 4))
            (if (solid-metatile? tile)
              (do
                (when (not= tile 0x26)
                  (write8! ram addr-square1-sound 2))
                (write8! ram addr-player-y-speed 1))
              (if (and (not= (read8 ram addr-area-type) 0)
                       (= (read8 ram addr-block-bounce-timer) 0))
                (player-head-collision! ram (get head 2) (get head 3))
                (write8! ram addr-player-y-speed 1)))))

        (when (and (not finished) (< (read8 ram addr-player-y) 0xcf))
          (def left-foot (collision-probe ram false (inc probe-offset)))
          (when (or (= (get left-foot 0) 0xc2) (= (get left-foot 0) 0xc3))
            (handle-coin! ram (get left-foot 2) (get left-foot 3))
            (set finished true))
          (unless finished
            (def right-foot (collision-probe ram false (+ probe-offset 2)))
            (def left-tile (get left-foot 0))
            (def right-tile (get right-foot 0))
            (when (and (= left-tile 0)
                       (or (= right-tile 0xc2) (= right-tile 0xc3)))
              (handle-coin! ram (get right-foot 2) (get right-foot 3))
              (set finished true))
            (unless finished
              (def landing-tile (if (= left-tile 0) right-tile left-tile))
              (when (and (not= landing-tile 0)
                         (not (climb-metatile? landing-tile))
                         (< (read8 ram addr-player-y-speed) 0x80)
                         (not (or (= landing-tile 0x5f)
                                  (= landing-tile 0x60))))
                (if (= landing-tile 0xc5)
                  (do
                    (handle-axe! ram (get right-foot 2) (get right-foot 3))
                    (set finished true))
                  (if (>= (get right-foot 1) 5)
                    (do
                      (impede-player! ram (read8 ram addr-player-moving))
                      (set finished true))
                    (do
                      (when (or (= landing-tile 0x67) (= landing-tile 0x68))
                        (write8! ram addr-vertical-force 0x70)
                        (write8! ram addr-jump-spring-force 0xf9)
                        (write8! ram addr-jump-spring-timer 3)
                        (write8! ram addr-jump-spring-animation 1))
                      (write8! ram addr-player-y
                               (band (read8 ram addr-player-y) 0xf0))
                      (handle-pipe-entry! world left-tile right-tile)
                      (write8! ram addr-player-y-speed 0)
                      (write8! ram addr-player-y-force 0)
                      (write8! ram 0x0484 0)
                      (write8! ram addr-player-state state-on-ground))))))))

        (def y (read8 ram addr-player-y))
        (when (and (not finished) (>= y 8) (< y 0xe4))
          (when (>= y 0x20)
            (def probe (collision-probe ram true (+ probe-offset 3)))
            (def tile (get probe 0))
            (unless (or (= tile 0) (= tile 0x1c) (= tile 0x6b)
                        (climb-metatile? tile))
              (handle-side-metatile! ram tile (get probe 1) (get probe 2)
                                     (get probe 3) button-left)
              (set finished true)))
          (when (and (not finished) (< y 0xd0))
            (def probe (collision-probe ram true (+ probe-offset 4)))
            (when (not= (get probe 0) 0)
              (handle-side-metatile! ram (get probe 0) (get probe 1)
                                     (get probe 2) (get probe 3) button-left)
              (set finished true)))
          (when (and (not finished) (>= y 0x20) (< y 0xd0))
            (def probe (collision-probe ram true (+ probe-offset 5)))
            (def tile (get probe 0))
            (unless (or (= tile 0) (= tile 0x1c) (= tile 0x6b)
                        (climb-metatile? tile))
              (handle-side-metatile! ram tile (get probe 1) (get probe 2)
                                     (get probe 3) button-right)
              (set finished true)))
          (when (and (not finished) (< y 0xd0))
            (def probe (collision-probe ram true (+ probe-offset 6)))
            (when (not= (get probe 0) 0)
              (handle-side-metatile! ram (get probe 0) (get probe 1)
                                     (get probe 2) (get probe 3)
                                     button-right)))))))
  ram)

(defn- scroll-handler!
  [ram]
  (scroll/handle! ram))

(defn- xoff-value [ram right]
  (def page (if right (read8 ram addr-screen-right-page)
              (read8 ram addr-screen-left-page)))
  (def x (if right (read8 ram addr-screen-right-x)
           (read8 ram addr-screen-left-x)))
  (var z (bytes/i16 (- page (read8 ram addr-player-page))))
  (set z (+ (- x (read8 ram addr-player-x)) (* z 256)))
  (def value (if (< z 0) 7 (if (< z 56) (+ (div z 8) 8) 15)))
  (if right (% (+ value 8) 16) value))

(defn- player-offscreen-bits!
  [ram]
  (def x-lookup @[0x7f 0x3f 0x1f 0x0f 0x07 0x03 0x01 0
                  0x80 0xc0 0xe0 0xf0 0xf8 0xfc 0xfe 0xff])
  (def right (get x-lookup (xoff-value ram true)))
  (def xbits (if (not= right 0) right (get x-lookup (xoff-value ram false))))
  (defn y-value [second]
    (var z (- 256 (* (read8 ram addr-player-y-high) 256)
              (read8 ram addr-player-y)))
    (unless second (set z (+ z 255)))
    (def value (if (< z 0) 4 (if (< z 32) (+ (div z 8) 4) 0)))
    (if second (% (+ value 4) 8) value))
  (def y-lookup @[0 8 12 14 15 7 3 1 0])
  (def upper (get y-lookup (y-value true)))
  (def ybits (if (not= upper 0) upper (get y-lookup (y-value false))))
  (write8! ram addr-offscreen-bits
           (bor (blshift ybits 4) (brshift xbits 4))))

(defn- relative-position!
  [ram]
  (write8! ram addr-relative-y (read8 ram addr-player-y))
  (write8! ram addr-relative-x
           (- (read8 ram addr-player-x) (read8 ram addr-screen-left-x))))

(defn- relative-and-box!
  [ram]
  (relative-position! ram)
  (def control (read8 ram addr-bounding-box-control))
  (def box (get bounding-boxes control))
  (write8! ram 0x04ac (+ (read8 ram addr-relative-x) (get box 0)))
  (write8! ram 0x04ad (+ (read8 ram addr-relative-y) (get box 1)))
  (write8! ram 0x04ae (+ (read8 ram addr-relative-x) (get box 2)))
  (write8! ram 0x04af (+ (read8 ram addr-relative-y) (get box 3))))

(defn presentation-position!
  "Refresh Mario's post-object offscreen and relative position before drawing."
  [world]
  (def ram (world :ram))
  (player-offscreen-bits! ram)
  (relative-position! ram)
  world)
(defn- change-area-mode!
  [ram]
  (write8! ram addr-disable-screen (inc (read8 ram addr-disable-screen)))
  (write8! ram addr-mode-task 0)
  (write8! ram addr-sprite-zero-hit 0))
(defn control!
  [world]
  (def ram (world :ram))
  (when (not= (read8 ram addr-game-routine) routine-player-death)
    (when (and (= (read8 ram addr-area-type) 0)
               (or (not= (read8 ram addr-player-y-high) 1)
                   (>= (read8 ram addr-player-y) 0xd0)))
      (write8! ram 0x06fc 0))
    (def joypad (read8 ram 0x06fc))
    (write8! ram addr-a-b-buttons (band joypad (bor button-a button-b)))
    (write8! ram addr-up-down-buttons (band joypad (bor button-up button-down)))
    (write8! ram addr-left-right-buttons (band joypad (bor button-left button-right)))
    (when (and (bit? joypad button-down)
               (= (read8 ram addr-player-state) state-on-ground)
               (not= (read8 ram addr-left-right-buttons) 0))
      (write8! ram addr-left-right-buttons 0)
      (write8! ram addr-up-down-buttons 0)))
  (movement! world)
  (write8! ram addr-bounding-box-control 1)
  (when (= (read8 ram addr-player-size) 0)
    (write8! ram addr-bounding-box-control
             (if (= (read8 ram addr-player-crouching) 0) 0 2)))
  (when (not= (read8 ram addr-player-x-speed) 0)
    (write8! ram addr-player-moving
             (if (< (read8 ram addr-player-x-speed) 0x80)
               button-right
               button-left)))
  (scroll-handler! ram)
  (player-offscreen-bits! ram)
  (relative-and-box! ram)
  (background-collision! world)
  (def current-routine (read8 ram addr-game-routine))
  (when (and (>= (read8 ram addr-player-y) 0x40)
             (or (= current-routine routine-flagpole-slide)
                 (= current-routine routine-lose-life)
                 (= current-routine routine-player-control)
                 (= current-routine routine-change-size)
                 (= current-routine routine-injury)
                 (= current-routine routine-player-death)
                 (= current-routine routine-fire-flower)))
    (write8! ram addr-player-sprite-attribute
             (band (read8 ram addr-player-sprite-attribute) 0xdf)))
  (when (< (bytes/u8 (- (read8 ram addr-player-y-high) 2)) 0x80)
    (write8! ram addr-scroll-lock 1)
    (var threshold 4)
    (var lose-life 0)
    (when (or (not= (read8 ram addr-game-timer-expired) 0)
              (= (read8 ram 0x07c4) 0))
      (set lose-life 1)
      (when (not= (read8 ram addr-game-routine) routine-player-death)
        (when (= (read8 ram addr-player-death-music) 0)
          (write8! ram addr-event-music 1)
          (write8! ram addr-player-death-music 1))
        (set threshold 6)))
    (when (< (bytes/u8 (- (read8 ram addr-player-y-high) threshold)) 0x80)
      (if (= lose-life 0)
        (do
          (write8! ram addr-joypad-override 0)
          (write8! ram addr-alt-entrance 2)
          (change-area-mode! ram)
          (write8! ram addr-alt-entrance
                   (inc (read8 ram addr-alt-entrance))))
        (when (= (read8 ram addr-event-music-buffer) 0)
          (write8! ram addr-game-routine routine-lose-life)))))
  ram)

(defn- auto-control!
  [world joypad]
  (write8! (world :ram) 0x06fc joypad)
  (control! world))

(defn auto-control-player!
  [world joypad]
  (auto-control! world joypad))


(defn vertical-pipe-entry!
  [world]
  (def ram (world :ram))
  (write8! ram addr-player-y (inc (read8 ram addr-player-y)))
  (scroll-handler! ram)
  (write8! ram addr-change-area-timer
           (dec (read8 ram addr-change-area-timer)))
  (when (= (read8 ram addr-change-area-timer) 0)
    (write8! ram addr-alt-entrance
             (if (not= (read8 ram addr-warp-zone-control) 0)
               0
               (if (not= (read8 ram addr-area-type) 3) 1 2)))
    (change-area-mode! ram))
  ram)

(defn side-pipe-entry!
  [world]
  (def ram (world :ram))
  (write8! ram addr-player-x-speed 8)
  (def aligned (= (band (read8 ram addr-player-x) 0x0f) 0))
  (when aligned
    (write8! ram addr-player-x-speed 0))
  (auto-control! world (if aligned 0 button-right))
  (write8! ram addr-change-area-timer
           (dec (read8 ram addr-change-area-timer)))
  (when (= (read8 ram addr-change-area-timer) 0)
    (write8! ram addr-alt-entrance 2)
    (change-area-mode! ram))
  ram)

(defn vine-auto-climb!
  [world]
  (def ram (world :ram))
  (if (and (= (read8 ram addr-player-y-high) 0)
           (< (read8 ram addr-player-y) 0xe4))
    (do
      (write8! ram addr-alt-entrance 2)
      (change-area-mode! ram))
    (do
      (write8! ram addr-joypad-override button-up)
      (write8! ram addr-player-state state-climbing)
      (auto-control! world button-up)))
  ram)

(defn- initialize-size-change!
  [ram]
  (when (= (read8 ram addr-change-size-flag) 0)
    (write8! ram addr-animation-control 0)
    (write8! ram addr-change-size-flag 1)
    (write8! ram addr-player-size (bxor (read8 ram addr-player-size) 1))))

(defn- finish-player-task!
  [ram]
  (write8! ram addr-star-flag-timer 0)
  (write8! ram addr-game-routine routine-player-control))

(defn change-size!
  [world]
  (def ram (world :ram))
  (cond
    (= (read8 ram addr-star-flag-timer) 0xf8)
    (initialize-size-change! ram)

    (= (read8 ram addr-star-flag-timer) 0xc4)
    (finish-player-task! ram))
  ram)

(defn injury!
  [world]
  (def ram (world :ram))
  (def timer (read8 ram addr-star-flag-timer))
  (cond
    (>= timer 0xf0)
    (when (= timer 0xf0)
      (initialize-size-change! ram))

    (= timer 0xc8)
    (finish-player-task! ram)

    true
    (control! world))
  ram)

(defn death!
  [world]
  (def ram (world :ram))
  (when (< (read8 ram addr-star-flag-timer) 0xf0)
    (control! world))
  ram)

(defn fire-flower!
  [world]
  (def ram (world :ram))
  (if (not= (read8 ram addr-star-flag-timer) 0xc0)
    (write8! ram addr-player-sprite-attribute
             (bor (band (read8 ram addr-player-sprite-attribute) 0xfc)
                  (band (brshift (read8 ram addr-frame-counter) 2) 3)))
    (do
      (finish-player-task! ram)
      (write8! ram addr-player-sprite-attribute
               (band (read8 ram addr-player-sprite-attribute) 0xfc))))
  ram)


(defn- gfx-table
  [world index]
  (rom/read-cpu (world :rom) (+ 0xee07 index)))

(defn- offset-from-animation
  [world control index]
  (bytes/u8 (+ (* control 8)
               (gfx-table world index)
               (if (bit? control 0x20) 1 0))))

(defn- animation-control!
  [world extent index]
  (def ram (world :ram))
  (def result
    (offset-from-animation world (read8 ram addr-animation-control) index))
  (when (= (read8 ram addr-animation-timer) 0)
    (write8! ram addr-animation-timer (read8 ram addr-animation-set))
    (write8! ram addr-animation-control
             (inc (read8 ram addr-animation-control)))
    (when (<= extent (read8 ram addr-animation-control))
      (write8! ram addr-animation-control 0)))
  result)

(defn action!
  [world]
  (def ram (world :ram))
  (defn adder [index]
    (+ index (if (= (read8 ram addr-player-size) 0) 0 8)))
  (def state (read8 ram addr-player-state))
  (cond
    (= state state-climbing)
    (if (not= (read8 ram addr-player-y-speed) 0)
      (animation-control! world 2 (adder 5))
      (do
        (write8! ram addr-animation-control 0)
        (gfx-table world (adder 5))))

    (= state state-falling)
    (offset-from-animation world (read8 ram addr-animation-control) (adder 4))

    (= state state-jump-swim)
    (if (not= (read8 ram addr-swimming) 0)
      (do
        (def adder-index (adder 1))
        (if (or (not= 0 (bor (read8 ram addr-jump-swim-timer)
                             (read8 ram addr-animation-control)))
                (bit? (read8 ram addr-a-b-buttons) button-a))
          (animation-control! world 3 adder-index)
          (offset-from-animation world
                                 (read8 ram addr-animation-control)
                                 adder-index)))
      (do
        (write8! ram addr-animation-control 0)
        (gfx-table world
                   (adder (if (= (read8 ram addr-player-crouching) 0) 0 6)))))

    true
    (if (= (read8 ram addr-player-crouching) 0)
      (if (not= 0 (bor (read8 ram addr-player-x-speed)
                       (read8 ram addr-left-right-buttons)))
        (if (or (< (read8 ram addr-player-x-absolute) 9)
                (not= 0 (band (read8 ram addr-player-moving)
                              (read8 ram addr-player-facing))))
          (animation-control! world 3 (adder 4))
          (do
            (write8! ram addr-animation-control 0)
            (gfx-table world (adder 3))))
        (do
          (write8! ram addr-animation-control 0)
          (gfx-table world (adder 2))))
      (do
        (write8! ram addr-animation-control 0)
        (gfx-table world (adder 6))))))

(defn change-animation!
  [world]
  (def ram (world :ram))
  (when (= (band (read8 ram addr-frame-counter) 3) 0)
    (write8! ram addr-animation-control
             (inc (read8 ram addr-animation-control)))
    (when (>= (read8 ram addr-animation-control) 0x0a)
      (write8! ram addr-animation-control 0)
      (write8! ram addr-change-size-flag 0)))
  (def lookup-big @[0 1 0 1 0 1 2 0 1 2])
  (def lookup-small @[2 0 2 0 2 0 2 0 2 0])
  (if (not= (read8 ram addr-player-size) 0)
    (gfx-table world
               (if (= (get lookup-small (read8 ram addr-animation-control)) 0)
                 1
                 9))
    (offset-from-animation world
                           (get lookup-big (read8 ram addr-animation-control))
                           0x0f)))


(defn- draw-player-row!
  [ram image row sprite-offset table-offset x y attributes flip-horizontal]
  (oam/draw-row! ram row sprite-offset
                  (rom/read-cpu image (+ 0xee17 table-offset))
                  (rom/read-cpu image (+ 0xee18 table-offset))
                  x y attributes flip-horizontal))

(defn- render-player!
  [world rows]
  (def ram (world :ram))
  (def image (world :rom))
  (def sprite-offset (read8 ram addr-sprite-data-offset))
  (def table-offset (read8 ram addr-player-gfx-offset))
  (def x (read8 ram addr-relative-x))
  (def y (read8 ram addr-relative-y))
  (def attributes (read8 ram addr-player-sprite-attribute))
  (def flip-horizontal (not= (band (read8 ram addr-player-facing) 2) 0))
  (write8! ram addr-player-position-for-scroll x)
  (loop [row :range [0 rows]]
    (draw-player-row! ram image row sprite-offset (+ table-offset (* row 2))
                      x y attributes flip-horizontal)))

(defn- check-player-attributes!
  [ram]
  (def offset (read8 ram addr-player-gfx-offset))
  (def death (= (read8 ram addr-game-routine) routine-player-death))
  (def lower-only (or (= offset 0x50) (= offset 0xb8) (= offset 0xc0)))
  (when (or death lower-only (= offset 0xc8))
    (def sprite-offset (read8 ram addr-sprite-data-offset))
    (unless lower-only
      (oam/write! ram sprite-offset 4 2
                  (band (oam/read ram sprite-offset 4 2) 0x3f))
      (oam/write! ram sprite-offset 5 2
                  (bor (band (oam/read ram sprite-offset 5 2) 0x3f) 0x40)))
    (oam/write! ram sprite-offset 6 2
                (band (oam/read ram sprite-offset 6 2) 0x3f))
    (oam/write! ram sprite-offset 7 2
                (bor (band (oam/read ram sprite-offset 7 2) 0x3f) 0x40))))


(defn- process-player-graphics!
  [world offset]
  (def ram (world :ram))
  (write8! ram addr-player-gfx-offset offset)
  (render-player! world 4)
  (check-player-attributes! ram)

  (when (not= (read8 ram addr-fireball-throwing-timer) 0)
    (if (< (read8 ram addr-animation-timer)
           (read8 ram addr-fireball-throwing-timer))
      (do
        (write8! ram addr-fireball-throwing-timer
                 (read8 ram addr-animation-timer))
        (write8! ram addr-player-gfx-offset (gfx-table world 7))
        (render-player! world
                        (if (not= (bor (read8 ram addr-player-x-speed)
                                      (read8 ram addr-left-right-buttons))
                                  0)
                          3
                          4)))
      (write8! ram addr-fireball-throwing-timer 0)))

  (def sprite-offset (read8 ram addr-sprite-data-offset))
  (def offscreen (read8 ram addr-offscreen-bits))
  (when (not= (band offscreen 0x10) 0) (oam/hide-row! ram sprite-offset 3))
  (when (not= (band offscreen 0x20) 0) (oam/hide-row! ram sprite-offset 2))
  (when (not= (band offscreen 0x40) 0) (oam/hide-row! ram sprite-offset 1))
  (when (not= (band offscreen 0x80) 0) (oam/hide-row! ram sprite-offset 0)))

(defn- update-swimming-kick!
  [world]
  (def ram (world :ram))
  (def sprite-offset
    (+ (read8 ram addr-sprite-data-offset)
       (if (= (band (read8 ram addr-player-facing) 1) 0) 4 0)))
  (if (= (read8 ram addr-player-size) 0)
    (oam/write! ram sprite-offset 6 1 0x31)
    (unless (= (oam/read ram sprite-offset 6 1)
               (rom/read-cpu (world :rom) (+ 0xee17 158)))
      (oam/write! ram sprite-offset 6 1 0x46))))

(defn graphics-step!
  [world]
  (def ram (world :ram))
  (when (or (= (read8 ram addr-injury-timer) 0)
            (= (band (read8 ram addr-frame-counter) 1) 0))
    (var normal-action false)
    (def offset
      (cond
        (= (read8 ram addr-game-routine) routine-player-death)
        (gfx-table world 14)

        (not= (read8 ram addr-change-size-flag) 0)
        (change-animation! world)

        true
        (do
          (set normal-action true)
          (action! world))))
    (process-player-graphics! world offset)
    (when (and normal-action
               (not= (read8 ram addr-swimming) 0)
               (not= (read8 ram addr-player-state) state-on-ground)
               (= (band (read8 ram addr-frame-counter) 4) 0))
      (update-swimming-kick! world)))
  world)

(defn entrance-setup!
  "Initialize Mario's area entrance and game timer."
  [world]
  (def ram (world :ram))
  (put ram addr-player-page (get ram addr-screen-left-page))
  (put ram addr-vertical-force-down 0x28)
  (put ram addr-player-facing button-right)
  (put ram addr-player-y-high 1)
  (put ram addr-player-state state-on-ground)
  (put ram addr-collision-bits
       (bytes/u8 (dec (get ram addr-collision-bits))))
  (put ram 0x075b 0)
  (put ram addr-swimming (if (= (get ram addr-area-type) 0) 1 0))
  (def entrance (get ram addr-player-entrance-control))
  (def alternate (get ram addr-alt-entrance))
  (case alternate
    0 (do
        (put ram addr-player-x 0x28)
        (put ram addr-player-y
             (get @[0x00 0x20 0xb0 0x50 0x00 0x00 0xb0 0xb0] entrance))
        (put ram addr-player-sprite-attribute
             (if (= entrance 1) 0x20 0)))
    1 (do
        (put ram addr-player-x 0x18)
        (put ram addr-player-y
             (get @[0x00 0x20 0xb0 0x50 0x00 0x00 0xb0 0xb0] entrance))
        (put ram addr-player-sprite-attribute
             (if (= entrance 1) 0x20 0)))
    2 (do
        (put ram addr-player-x 0x38)
        (put ram addr-player-y 0xf0)
        (put ram addr-player-sprite-attribute 0x20))
    3 (do
        (put ram addr-player-x 0x28)
        (put ram addr-player-y 0)
        (put ram addr-player-sprite-attribute 0)))
  (def timer-setting (get ram 0x0715))
  (when (and (not= timer-setting 0)
             (not= (get ram 0x0757) 0))
    (def time (get @[0 401 301 201] timer-setting))
    (put ram 0x07f8 (% (div time 100) 10))
    (put ram 0x07f9 (% (div time 10) 10))
    (put ram 0x07fa (% time 10))
    (put ram 0x0757 0)
    (put ram 0x079f 0))
  (put ram addr-game-routine routine-player-entrance)
  world)

(defn- next-area!
  [world]
  (def ram (world :ram))
  (write8! ram 0x0760 (inc (read8 ram 0x0760)))
  (area/load-pointer! world)
  (write8! ram 0x0757 (inc (read8 ram 0x0757)))
  (change-area-mode! ram)
  (write8! ram 0x075b 0)
  (write8! ram addr-event-music 0x80)
  world)
(defn entrance!
  "Run pipe, vine, and ordinary player entrances until control can be released."
  [world]
  (def ram (world :ram))
  (var release-control true)
  (if (= (read8 ram addr-alt-entrance) 2)
    (if (zero? (read8 ram addr-joypad-override))
      (do
        (write8! ram addr-player-y (dec (read8 ram addr-player-y)))
        (when (> (read8 ram addr-player-y) 0x90)
          (set release-control false)))
      (if (not= (read8 ram 0x0399) 0x60)
        (set release-control false)
        (do
          (def climbing? (> (read8 ram addr-player-y) 0x98))
          (write8! ram addr-disable-collision (if climbing? 1 0))
          (when climbing?
            (write8! ram addr-player-state state-climbing)
            (set-metatile! ram 4 11 7))
          (auto-control! world (if climbing? button-up button-right))
          (when (< (read8 ram addr-player-x) 0x48)
            (set release-control false)))))
    (cond
      (< (read8 ram addr-player-y) 0x30)
      (do
        (auto-control! world 0)
        (set release-control false))

      (or (= (read8 ram addr-player-entrance-control) 6)
          (= (read8 ram addr-player-entrance-control) 7))
      (if (zero? (read8 ram addr-player-sprite-attribute))
        (do
          (auto-control! world button-right)
          (set release-control false))
        (do
          (write8! ram addr-player-x-speed 8)
          (def aligned? (zero? (band (read8 ram addr-player-x) 0x0f)))
          (when aligned?
            (write8! ram addr-player-x-speed 0))
          (auto-control! world (if aligned? 0 button-right))
          (write8! ram addr-change-area-timer
                   (dec (read8 ram addr-change-area-timer)))
          (if (zero? (read8 ram addr-change-area-timer))
            (do
              (write8! ram 0x0769 (inc (read8 ram 0x0769)))
              (next-area! world))
            (set release-control false))
          (set release-control false)))
      true nil))
  (when release-control
    (write8! ram addr-joypad-override 0)
    (write8! ram addr-alt-entrance 0)
    (write8! ram addr-disable-collision 0)
    (write8! ram addr-player-facing button-right)
    (write8! ram addr-game-routine routine-player-control))
  world)

(defn flagpole-slide!
  "Auto-control Mario down the flagpole until the flag object releases him."
  [world]
  (def ram (world :ram))
  (if (= (read8 ram (+ 0x0016 5)) 0x30)
    (do
      (write8! ram addr-square1-sound (read8 ram addr-flagpole-sound))
      (write8! ram addr-flagpole-sound 0)
      (auto-control! world
                     (if (< (read8 ram addr-player-y) 0x9e)
                       button-down
                       0)))
    (write8! ram addr-game-routine routine-player-end-level))
  world)


(defn end-level!
  "Walk Mario into the castle, complete the star-flag sequence, and load the next area."
  [world]
  (def ram (world :ram))
  (auto-control! world button-right)
  (when (and (>= (read8 ram addr-player-y) 0xae)
             (not= (read8 ram addr-scroll-lock) 0))
    (write8! ram addr-event-music 0x20)
    (write8! ram addr-scroll-lock 0))
  (when (= (band (read8 ram addr-collision-bits) 1) 0)
    (when (= (read8 ram addr-star-flag-task) 0)
      (write8! ram addr-star-flag-task 1))
    (write8! ram addr-player-sprite-attribute 0x20))
  (when (= (read8 ram addr-star-flag-task) 5)
    (write8! ram 0x075c (inc (read8 ram 0x075c)))
    (when (and (= (read8 ram 0x075c) 3)
               (>= (read8 ram 0x0748)
                   (rom/read-cpu (world :rom)
                                 (+ 0xb2c2 (read8 ram 0x075f)))))
      (write8! ram 0x075d (inc (read8 ram 0x075d))))
    (next-area! world))
  world)

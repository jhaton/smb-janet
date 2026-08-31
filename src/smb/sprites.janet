(import ./actors)
(import ./bytes)
(import ./oam)
(import ./player)
(import ./rom)

(def enemy-graphics-table 0xe73e)
(def addr-enemy-sprite-offset 0x06e5)
(def addr-enemy-interval-timer 0x0796)
(def addr-enemy-offscreen-bits 0x03d1)
(def addr-fireball-relative-x 0x03af)
(def addr-fireball-relative-y 0x03ba)
(def addr-bubble-relative-x 0x03b0)
(def addr-bubble-relative-y 0x03bb)
(def addr-bubble-offscreen-bits 0x03d3)
(def addr-alt-sprite-offset 0x06ec)
(def addr-bubble-sprite-offset 0x06ee)
(def addr-fireball-sprite-offset 0x06f1)
(def addr-block-relative-x 0x03b1)
(def addr-block-relative-x-2 0x03b2)
(def addr-block-relative-y 0x03bc)
(def addr-block-relative-y-2 0x03bd)
(def addr-block-offscreen-bits 0x03d4)
(def addr-block-metatile 0x03e8)
(def addr-block-original-x 0x03f1)
(def addr-area-type 0x074e)
(def addr-game-engine-subroutine 0x000e)
(def addr-misc-state 0x002a)
(def addr-misc-y 0x00db)
(def addr-misc-relative-x 0x03b3)
(def addr-misc-relative-y 0x03be)
(def addr-misc-offscreen-bits 0x03d6)
(def addr-misc-sprite-offset 0x06f3)
(def addr-timer-control 0x0747)
(def addr-flagpole-number-y 0x010d)
(def addr-flagpole-score 0x010f)
(def addr-flagpole-collision-y 0x070f)
(def star-flag-x-offsets [0 8 0 8])
(def star-flag-y-offsets [0 0 8 8])
(def star-flag-tiles [0x54 0x55 0x56 0x57])
(def fireworks-tiles [0x68 0x67 0x66])
(def fireworks-attributes [2 0x82 0x42 0xc2])
(def power-up-tiles
  @[@[0x76 0x77 0x78 0x79]
    @[0xd6 0xd6 0xd9 0xd9]
    @[0x8d 0x8d 0xe4 0xe4]
    @[0x76 0x77 0x78 0x79]])
(def power-up-palettes @[2 1 2 1])

(defn flagpole!
  [world slot]
  (def ram (world :ram))
  (def sprite-offset (get ram (+ addr-enemy-sprite-offset slot)))
  (def x (get ram actors/addr-enemy-relative-x))
  (def y (get ram (+ actors/addr-enemy-y slot)))
  (def carry-bug (and (>= x 236) (< x 248)))
  (oam/write! ram sprite-offset 0 3 x)
  (oam/write! ram sprite-offset 1 3 (+ x 8))
  (oam/write! ram sprite-offset 2 3 (+ x 8))
  (oam/write! ram sprite-offset 0 0 y)
  (oam/write! ram sprite-offset 1 0 y)
  (oam/write! ram sprite-offset 2 0 (+ y 8 (if carry-bug 1 0)))
  (loop [sprite :range [0 3]]
    (oam/write! ram sprite-offset sprite 2 1))
  (oam/write! ram sprite-offset 0 1 0x7e)
  (oam/write! ram sprite-offset 1 1 0x7f)
  (oam/write! ram sprite-offset 2 1 0x7e)
  (when (not= (get ram addr-flagpole-collision-y) 0)
    (def score (get ram addr-flagpole-score))
    (def tiles
      (get @[@[0xf9 0x50] @[0xf7 0x50] @[0xfa 0xfb]
             @[0xf8 0xfb] @[0xf6 0xfb]]
           score))
    (oam/draw-row! ram 0 (+ sprite-offset 12)
                   (get tiles 0) (get tiles 1)
                   (+ x 20) (get ram addr-flagpole-number-y) 1 false))
  (when (not= (band (get ram addr-enemy-offscreen-bits) 0x0e) 0)
    (loop [sprite :range [0 6]]
      (oam/write! ram sprite-offset sprite 0 oam/offscreen-y))))

(defn star-flag!
  [world slot]
  (def ram (world :ram))
  (def sprite-offset (get ram (+ addr-enemy-sprite-offset slot)))
  (def x (get ram actors/addr-enemy-relative-x))
  (def y (get ram actors/addr-enemy-relative-y))
  (loop [index :range [0 4]]
    (def sprite (- 3 index))
    (oam/write! ram sprite-offset sprite 3
                (+ x (get star-flag-x-offsets index)))
    (oam/write! ram sprite-offset sprite 0
                (+ y (get star-flag-y-offsets index)))
    (oam/write! ram sprite-offset sprite 1 (get star-flag-tiles index))
    (oam/write! ram sprite-offset sprite 2 0x22))
  world)

(defn fireworks!
  [world slot frame]
  (def ram (world :ram))
  (def sprite-offset (get ram (+ addr-enemy-sprite-offset slot)))
  (def x (get ram actors/addr-enemy-relative-x))
  (def y (get ram actors/addr-enemy-relative-y))
  (def tile (get fireworks-tiles frame))
  (loop [sprite :range [0 4]]
    (oam/write! ram sprite-offset sprite 1 tile))
  (oam/write! ram sprite-offset 0 0 (- y 4))
  (oam/write! ram sprite-offset 2 0 (- y 4))
  (oam/write! ram sprite-offset 1 0 (+ y 4))
  (oam/write! ram sprite-offset 3 0 (+ y 4))
  (oam/write! ram sprite-offset 0 3 (- x 4))
  (oam/write! ram sprite-offset 1 3 (- x 4))
  (oam/write! ram sprite-offset 2 3 (+ x 4))
  (oam/write! ram sprite-offset 3 3 (+ x 4))
  (eachp [sprite attributes] fireworks-attributes
    (oam/write! ram sprite-offset sprite 2 attributes))
  world)
(defn large-platform!
  [world slot x-offscreen-bits]
  (def ram (world :ram))
  (def sprite-offset (get ram (+ addr-enemy-sprite-offset slot)))
  (def x (get ram actors/addr-enemy-relative-x))
  (def y (get ram (+ actors/addr-enemy-y slot)))
  (loop [sprite :range [0 6]]
    (oam/write! ram sprite-offset sprite 3 (+ x (* sprite 8)))
    (oam/write! ram sprite-offset sprite 1
                (if (zero? (get ram 0x0743)) 0x5b 0x75))
    (oam/write! ram sprite-offset sprite 2 2)
    (oam/write! ram sprite-offset sprite 0
                (if (and (>= sprite 4)
                         (or (= (get ram addr-area-type) 3)
                             (not= (get ram actors/addr-secondary-hard-mode) 0)))
                  oam/offscreen-y
                  y))
    (when (not= (band x-offscreen-bits (brshift 0x80 sprite)) 0)
      (oam/write! ram sprite-offset sprite 0 oam/offscreen-y)))
  (when (not= (band (get ram addr-enemy-offscreen-bits) 0x80) 0)
    (loop [sprite :range [0 6]]
      (oam/write! ram sprite-offset sprite 0 oam/offscreen-y))))

(defn small-platform!
  [world slot]
  (def ram (world :ram))
  (def sprite-offset (get ram (+ addr-enemy-sprite-offset slot)))
  (def x (get ram actors/addr-enemy-relative-x))
  (loop [sprite :range [0 6]]
    (oam/write! ram sprite-offset sprite 1 0x5b)
    (oam/write! ram sprite-offset sprite 2 2))
  (loop [column :range [0 3]]
    (oam/write! ram sprite-offset column 3 (+ x (* column 8)))
    (oam/write! ram sprite-offset (+ column 3) 3 (+ x (* column 8))))
  (def y (get ram (+ actors/addr-enemy-y slot)))
  (loop [column :range [0 3]]
    (oam/write! ram sprite-offset column 0
                (if (< y 0x20) oam/offscreen-y y)))
  (def lower-y (bytes/u8 (+ y 0x80)))
  (loop [column :range [0 3]]
    (oam/write! ram sprite-offset (+ column 3) 0
                (if (< lower-y 0x20) oam/offscreen-y lower-y)))
  (def bits (get ram addr-enemy-offscreen-bits))
  (eachp [column mask] @[8 4 2]
    (when (not= (band bits mask) 0)
      (oam/write! ram sprite-offset column 0 oam/offscreen-y)
      (oam/write! ram sprite-offset (+ column 3) 0 oam/offscreen-y))))
(defn floatey!
  [world slot]
  (def ram (world :ram))
  (def id (get ram (+ actors/addr-enemy-id slot)))
  (def state (get ram (+ actors/addr-enemy-state slot)))
  (def alternate?
    (cond
      (or (= id 0) (= id 1) (= id 2) (= id 3)
          (= id 5) (= id 6) (= id 7)) (< state 2)
      (= id 4) true
      (or (= id 9) (= id 10) (= id 13) (= id 18)) false
      true true))
  (def sprite-offset
    (if alternate?
      (get ram (+ addr-alt-sprite-offset (get ram 0x03ee)))
      (get ram (+ addr-enemy-sprite-offset slot))))
  (def y (get ram (+ 0x011e slot)))
  (when (>= y 0x18)
    (put ram (+ 0x011e slot) (bytes/u8 (dec y))))
  (oam/write! ram sprite-offset 0 0 (- y 9))
  (oam/write! ram sprite-offset 1 0 (- y 9))
  (def x (get ram (+ 0x0117 slot)))
  (oam/write! ram sprite-offset 0 3 x)
  (oam/write! ram sprite-offset 1 3 (+ x 8))
  (oam/write! ram sprite-offset 0 2 2)
  (oam/write! ram sprite-offset 1 2 2)
  (def control (get ram (+ 0x0110 slot)))
  (def tiles
    @[@[0xff 0xff] @[0xf6 0xfb] @[0xf7 0xfb] @[0xf8 0xfb]
      @[0xf9 0xfb] @[0xfa 0xfb] @[0xf6 0x50] @[0xf7 0x50]
      @[0xf8 0x50] @[0xf9 0x50] @[0xfa 0x50] @[0xfd 0xfe]])
  (oam/write! ram sprite-offset 0 1 (get (get tiles control) 0))
  (oam/write! ram sprite-offset 1 1 (get (get tiles control) 1)))

(defn hammer!
  [world slot]
  (def ram (world :ram))
  (def sprite-offset (get ram (+ addr-misc-sprite-offset slot)))
  (def state (get ram (+ addr-misc-state slot)))
  (def frame
    (if (and (zero? (get ram addr-timer-control))
             (= (band state 0x7f) 1))
      (band (brshift (get ram actors/addr-frame-counter) 2) 3)
      0))
  (def x1 (get @[4 0 4 0] frame))
  (def y1 (get @[0 4 0 4] frame))
  (def x2 (get @[0 8 0 8] frame))
  (def y2 (get @[8 0 8 0] frame))
  (def attributes (get @[3 3 0xc3 0xc3] frame))
  (oam/write! ram sprite-offset 0 0 (+ (get ram addr-misc-relative-y) y1))
  (oam/write! ram sprite-offset 1 0 (+ (get ram addr-misc-relative-y) y1 y2))
  (oam/write! ram sprite-offset 0 3 (+ (get ram addr-misc-relative-x) x1))
  (oam/write! ram sprite-offset 1 3 (+ (get ram addr-misc-relative-x) x1 x2))
  (oam/write! ram sprite-offset 0 1 (get @[0x80 0x82 0x81 0x83] frame))
  (oam/write! ram sprite-offset 1 1 (get @[0x81 0x83 0x80 0x82] frame))
  (oam/write! ram sprite-offset 0 2 attributes)
  (oam/write! ram sprite-offset 1 2 attributes)
  (when (not= (band (get ram addr-misc-offscreen-bits) 0xfc) 0)
    (put ram (+ addr-misc-state slot) 0)
    (oam/write! ram sprite-offset 0 0 oam/offscreen-y)
    (oam/write! ram sprite-offset 1 0 oam/offscreen-y)))

(defn jumping-coin!
  [world slot]
  (def ram (world :ram))
  (def sprite-offset (get ram (+ addr-misc-sprite-offset slot)))
  (def state (get ram (+ addr-misc-state slot)))
  (if (< state 2)
    (do
      (def y (get ram (+ addr-misc-y slot)))
      (oam/write! ram sprite-offset 0 0 y)
      (oam/write! ram sprite-offset 1 0 (+ y 8))
      (oam/write! ram sprite-offset 0 3 (get ram addr-misc-relative-x))
      (oam/write! ram sprite-offset 1 3 (get ram addr-misc-relative-x))
      (def tile
        (get @[0x60 0x61 0x62 0x63]
             (band (brshift (get ram actors/addr-frame-counter) 1) 3)))
      (oam/write! ram sprite-offset 0 1 tile)
      (oam/write! ram sprite-offset 1 1 tile)
      (oam/write! ram sprite-offset 0 2 2)
      (oam/write! ram sprite-offset 1 2 0x82))
    (do
      (when (zero? (band (get ram actors/addr-frame-counter) 1))
        (put ram (+ addr-misc-y slot)
             (bytes/u8 (dec (get ram (+ addr-misc-y slot))))))
      (def y (get ram (+ addr-misc-y slot)))
      (oam/write! ram sprite-offset 0 0 y)
      (oam/write! ram sprite-offset 1 0 y)
      (oam/write! ram sprite-offset 0 3 (get ram addr-misc-relative-x))
      (oam/write! ram sprite-offset 1 3 (+ (get ram addr-misc-relative-x) 8))
      (oam/write! ram sprite-offset 0 2 2)
      (oam/write! ram sprite-offset 1 2 2)
      (oam/write! ram sprite-offset 0 1 0xf7)
      (oam/write! ram sprite-offset 1 1 0xfb))))

(defn block!
  [world slot]
  (def ram (world :ram))
  (def sprite-offset (get ram (+ addr-alt-sprite-offset slot)))
  (def x (get ram addr-block-relative-x))
  (def y (get ram addr-block-relative-y))
  (oam/draw-row! ram 0 sprite-offset 0x85 0x85 x y 3 false)
  (oam/draw-row! ram 1 sprite-offset 0x86 0x86 x y 3 false)
  (when (not= (get ram addr-area-type) 1)
    (oam/write! ram sprite-offset 0 1 0x86)
    (oam/write! ram sprite-offset 1 1 0x86))
  (when (= (get ram (+ addr-block-metatile slot)) 0xc4)
    (eachp [sprite attributes] @[3 0x43 0x83 0xc3]
      (oam/write! ram sprite-offset sprite 1 0x87)
      (oam/write! ram sprite-offset sprite 2
                  (if (= (get ram addr-area-type) 1)
                    attributes
                    (bor 1 (band attributes 0xc0))))))
  (when (not= (band (get ram addr-block-offscreen-bits) 4) 0)
    (oam/write! ram sprite-offset 1 0 oam/offscreen-y)
    (oam/write! ram sprite-offset 3 0 oam/offscreen-y))
  (when (not= (band (get ram addr-block-offscreen-bits) 8) 0)
    (oam/write! ram sprite-offset 0 0 oam/offscreen-y)
    (oam/write! ram sprite-offset 2 0 oam/offscreen-y)))

(defn brick-chunks!
  [world slot]
  (def ram (world :ram))
  (def sprite-offset (get ram (+ addr-alt-sprite-offset slot)))
  (def end-level? (= (get ram addr-game-engine-subroutine) 5))
  (def tile (if end-level? 0x75 0x84))
  (def attributes (bor (if end-level? 2 3)
                       (blshift (band (get ram actors/addr-frame-counter) 0x0c) 4)))
  (loop [sprite :range [0 4]]
    (oam/write! ram sprite-offset sprite 1 tile)
    (oam/write! ram sprite-offset sprite 2 attributes))
  (oam/write! ram sprite-offset 0 0 (get ram addr-block-relative-y))
  (oam/write! ram sprite-offset 1 0 (get ram addr-block-relative-y))
  (def x1 (get ram addr-block-relative-x))
  (def x2 (get ram addr-block-relative-x-2))
  (def b (bytes/u8 (- (get ram (+ addr-block-original-x slot))
                       (get ram player/addr-screen-left-x))))
  (def right-x1 (bytes/u8 (- (+ 6 (* 2 b)) x1)))
  (def right-x2 (bytes/u8 (- (+ 6 (* 2 b)) x2)))
  (def carry-x1 (if (>= b x1) 1 0))
  (def carry-x2 (if (>= b x2) 1 0))
  (oam/write! ram sprite-offset 0 3 x1)
  (oam/write! ram sprite-offset 1 3
              (+ right-x1 carry-x1
                 (if (>= (+ (* 2 b) (- x1) carry-x1) 0x100) 1 0)))
  (oam/write! ram sprite-offset 2 3 x2)
  (oam/write! ram sprite-offset 3 3
              (+ right-x2 carry-x2
                 (if (>= (+ (* 2 b) (- x2) carry-x2) 0x100) 1 0)))
  (oam/write! ram sprite-offset 2 0 (get ram addr-block-relative-y-2))
  (oam/write! ram sprite-offset 3 0 (get ram addr-block-relative-y-2))
  (when (not= (band (get ram addr-block-offscreen-bits) 8) 0)
    (oam/write! ram sprite-offset 0 0 oam/offscreen-y)
    (oam/write! ram sprite-offset 2 0 oam/offscreen-y))
  (when (not= (band (get ram addr-block-offscreen-bits) 0x80) 0)
    (oam/write! ram sprite-offset 0 0 oam/offscreen-y)
    (oam/write! ram sprite-offset 1 0 oam/offscreen-y))
  (when (and (>= b 0x80)
             (<= (oam/read ram sprite-offset 1 3)
                 (oam/read ram sprite-offset 0 3)))
    (oam/write! ram sprite-offset 1 0 oam/offscreen-y)
    (oam/write! ram sprite-offset 3 0 oam/offscreen-y)))

(defn explosion!
  [world phase sprite-offset]
  (def ram (world :ram))
  (def tile (get @[0x68 0x67 0x66] phase))
  (def x (get ram addr-fireball-relative-x))
  (def y (get ram addr-fireball-relative-y))
  (loop [sprite :range [0 4]]
    (oam/write! ram sprite-offset sprite 1 tile))
  (oam/write! ram sprite-offset 0 0 (- y 4))
  (oam/write! ram sprite-offset 2 0 (- y 4))
  (oam/write! ram sprite-offset 1 0 (+ y 4))
  (oam/write! ram sprite-offset 3 0 (+ y 4))
  (oam/write! ram sprite-offset 0 3 (- x 4))
  (oam/write! ram sprite-offset 1 3 (- x 4))
  (oam/write! ram sprite-offset 2 3 (+ x 4))
  (oam/write! ram sprite-offset 3 3 (+ x 4))
  (eachp [sprite attributes] @[2 0x82 0x42 0xc2]
    (oam/write! ram sprite-offset sprite 2 attributes)))

(defn fireball!
  [world slot]
  (def ram (world :ram))
  (def sprite-offset (get ram (+ addr-fireball-sprite-offset slot)))
  (oam/write! ram sprite-offset 0 0 (get ram addr-fireball-relative-y))
  (oam/write! ram sprite-offset 0 3 (get ram addr-fireball-relative-x))
  (oam/write! ram sprite-offset 0 1
               (bxor (band (brshift (get ram actors/addr-frame-counter) 2) 1)
                      0x64))
  (oam/write! ram sprite-offset 0 2
               (if (not= (band (brshift (get ram actors/addr-frame-counter) 3) 1) 0)
                 0xc2 2)))

(defn bubble!
  [world slot]
  (def ram (world :ram))
  (when (and (= (get ram player/addr-player-y-high) 1)
             (zero? (band (get ram addr-bubble-offscreen-bits) 8)))
    (def sprite-offset (get ram (+ addr-bubble-sprite-offset slot)))
    (oam/write! ram sprite-offset 0 3 (get ram addr-bubble-relative-x))
    (oam/write! ram sprite-offset 0 0 (get ram addr-bubble-relative-y))
    (oam/write! ram sprite-offset 0 1 0x74)
    (oam/write! ram sprite-offset 0 2 2)))

(defn- slot-read [ram base slot] (get ram (+ base slot)))
(defn- slot-write! [ram base slot value] (put ram (+ base slot) (bytes/u8 value)))

(defn- swap-tiles!
  [ram sprite-offset left right]
  (def value (oam/read ram sprite-offset left 1))
  (oam/write! ram sprite-offset left 1 (oam/read ram sprite-offset right 1))
  (oam/write! ram sprite-offset right 1 value))

(defn- draw-enemy-2x3!
  [world table-offset sprite-offset x y palette draw-behind
   flip-horizontal flip-vertical tall mirror-horizontal]
  (def ram (world :ram))
  (def image (world :rom))
  (def attributes (bor (if draw-behind 0x20 0) palette))
  (loop [row :range [0 3]]
    (def source (+ enemy-graphics-table table-offset (* row 2)))
    (oam/draw-row! ram row sprite-offset
                    (rom/read-cpu image source)
                    (rom/read-cpu image (inc source))
                    x y attributes flip-horizontal))

  (when flip-vertical
    (def flipped (bor (oam/read ram sprite-offset 0 2) 0x80))
    (loop [sprite :range [0 6]]
      (oam/write! ram sprite-offset sprite 2 flipped))
    (if tall
      (do
        (swap-tiles! ram sprite-offset 0 4)
        (swap-tiles! ram sprite-offset 1 5))
      (do
        (swap-tiles! ram sprite-offset 2 4)
        (swap-tiles! ram sprite-offset 3 5))))

  (when mirror-horizontal
    (def left-attributes (band (oam/read ram sprite-offset 0 2) 0xbf))
    (each sprite @[0 2 4]
      (oam/write! ram sprite-offset sprite 2 left-attributes))
    (each sprite @[1 3 5]
      (oam/write! ram sprite-offset sprite 2 (bor left-attributes 0x40)))))

(defn- flip-bottom-rows-vertical!
  [ram sprite-offset]
  (each sprite @[2 3 4 5]
    (oam/write! ram sprite-offset sprite 2
                 (bor (oam/read ram sprite-offset sprite 2) 0x80))))

(defn- clip-enemy!
  [world ram slot id sprite-offset]
  (def bits (get ram addr-enemy-offscreen-bits))
  (when (not= (band bits 4) 0)
    (each sprite @[1 3 5]
      (oam/write! ram sprite-offset sprite 0 oam/offscreen-y)))
  (when (not= (band bits 8) 0)
    (each sprite @[0 2 4]
      (oam/write! ram sprite-offset sprite 0 oam/offscreen-y)))
  (when (not= (band bits 0x20) 0) (oam/hide-row! ram sprite-offset 2))
  (when (not= (band bits 0x40) 0) (oam/hide-row! ram sprite-offset 1))
  (when (not= (band bits 0x80) 0)
    (oam/hide-row! ram sprite-offset 0)
    (when (and (not= id actors/actor-podoboo)
               (= (slot-read ram actors/addr-enemy-y-high slot) 2))
      (actors/erase! world slot))))

(defn enemy!
  "Render one normal fixed-slot enemy into OAM exactly as EnemyGfxHandler."
  [world slot]
  (def ram (world :ram))
  (def id (slot-read ram actors/addr-enemy-id slot))
  (def state (slot-read ram actors/addr-enemy-state slot))
  (def st (band state 0x1f))
  (def interval (slot-read ram addr-enemy-interval-timer slot))
  (def sprite-offset (slot-read ram addr-enemy-sprite-offset slot))
  (def x (get ram actors/addr-enemy-relative-x))
  (var y (slot-read ram actors/addr-enemy-y slot))
  (var flip-horizontal
    (not= (band (slot-read ram actors/addr-enemy-moving-dir slot) 2) 0))
  (var flip-vertical (not= (band state 0x20) 0))
  (var draw-behind false)
  (var mirror-horizontal false)
  (var palette 1)
  (var tall false)
  (var table-offset 0)
  (var next-offset nil)
  (var post nil)
  (def animated
    (and (zero? (band state 0xa0))
         (zero? (get ram actors/addr-timer-control))))

  (def skip
    (and (= id actors/actor-piranha)
         (< (slot-read ram actors/addr-enemy-x-speed slot) 0x80)
         (not= (slot-read ram actors/addr-enemy-frame-timer slot) 0)))

  (unless skip
  (put ram 0x00ef id)
  (case (cond
          (= id actors/actor-cannon-bullet) 8
          (or (= id 0) (= id 1) (= id 3)) :koopa
          (or (= id 10) (= id 11) (= id 20)) :cheep
          (or (= id 9) (= id 14) (= id 15) (= id 16)) :paratroopa
          true id)
    17
    (do
      (set tall true)
      (set table-offset
           (if (or flip-vertical
                   (>= (get ram actors/addr-frenzy-enemy-timer) 16))
             0x90 0x96))
      (set post :lakitu))

    18
    (do
      (set palette 2)
      (if (= st 5)
        (do
          (set table-offset 0x30)
          (set next-offset 0x36)
          (set flip-horizontal true)
          (set mirror-horizontal true)
          (set post :spiny-egg))
        (do
          (set table-offset 0x24)
          (set next-offset 0x2a))))

    :koopa
    (do
      (set palette (if (or (= id 1) (= id 3)) 2 1))
      (set table-offset 0x0c)
      (set next-offset 0x12)
      (when (> st 1)
        (set table-offset 0x5a)
        (set next-offset 0x60)
        (set mirror-horizontal true))
      (when (= st 4)
        (set table-offset 0x66)
        (set next-offset 0x6c)
        (set y (+ y 2))
        (set post :shell))
      (set flip-vertical false)
      (when (>= interval 5) (set next-offset nil)))

    4
    (do
      (set table-offset 0x0c)
      (set next-offset 0x12)
      (when (= st 4)
        (set table-offset 0x66)
        (set next-offset 0x6c)
        (set y (+ y 2))
        (unless flip-vertical (set post :shell)))
      (when (and (not flip-vertical) (> st 1))
        (set mirror-horizontal true))
      (when (>= interval 5) (set next-offset nil)))

    2
    (do
      (set palette 3)
      (set table-offset 0x00)
      (set next-offset 0x06)
      (when (> st 1)
        (set table-offset 0x7e)
        (set next-offset 0x84)
        (set y (inc y))
        (set mirror-horizontal true))
      (when (= st 4)
        (set table-offset 0x72)
        (set next-offset 0x78)
        (set y (inc y))
        (set post :shell))
      (set flip-vertical false)
      (when (>= interval 5) (set next-offset nil)))

    6
    (do
      (set palette 3)
      (set table-offset 0x54)
      (if flip-vertical
        (set y (+ y 2))
        (do
          (when (and (zero? (get ram actors/addr-timer-control))
                     (zero? (band (get ram actors/addr-frame-counter) 8)))
            (set flip-horizontal (not flip-horizontal)))
          (when (> state 1)
            (set table-offset 0x8a)
            (set y (inc y))
            (set mirror-horizontal true))))
      (when (> state 1) (set post :shell)))

    5
    (do
      (set tall true)
      (set table-offset 0xa8)
      (set next-offset 0xae)
      (when (not= (band state 8) 0)
        (set table-offset 0xb4)
        (set next-offset 0xba))
      (unless (or (= state 0) (not= (band state 8) 0))
        (set next-offset nil)))

    :cheep
    (do
      (set palette (if (= id 10) 1 2))
      (set table-offset 0x48)
      (set next-offset 0x4e))

    7
    (do
      (set palette 3)
      (set table-offset 0x3c)
      (set next-offset 0x42)
      (when (and (not= interval 1) (< interval 5))
        (set y (+ y 3))
        (when animated (set table-offset next-offset))
        (set next-offset nil))
      (set mirror-horizontal true))

    8
    (do
      (set palette 3)
      (set table-offset 0xea)
      (set flip-vertical false)
      (when (= id actors/actor-cannon-bullet)
        (put ram 0x00ef 8)
        (set y (dec y))
        (set draw-behind
             (not= (slot-read ram actors/addr-enemy-frame-timer slot) 0))))

    12
    (do
      (set palette 2)
      (set table-offset 0xcc)
      (set mirror-horizontal true)
      (set flip-vertical
           (< (slot-read ram actors/addr-enemy-y-speed slot) 0x80)))

    13
    (do
      (set table-offset 0xc0)
      (set next-offset 0xc6)
      (set draw-behind true)
      (set mirror-horizontal true))

    :paratroopa
    (do
      (set table-offset 0x18)
      (set next-offset 0x1e)
      (set palette (if (= id 15) 2 1))
      (when (= st 4)
        (set table-offset 0x66)
        (set next-offset 0x6c)
        (set y (+ y 2)))
      (when (> st 1) (set mirror-horizontal true)))

    19
    (do
      (set table-offset 0xff)
      (set next-offset 0x05)
      (set draw-behind true)
      (set palette 0xff)
      (when (= st 4)
        (set table-offset 0x66)
        (set next-offset 0x6c)
        (set y (+ y 2)))
      (when (and (not flip-vertical) (> st 1))
        (set mirror-horizontal true))
      (when (>= interval 5) (set next-offset nil)))

    (error (string "unsupported normal enemy graphics id " id)))

  (when (and next-offset animated
             (zero? (band (get ram actors/addr-frame-counter) 8)))
    (set table-offset next-offset))

  (draw-enemy-2x3! world table-offset sprite-offset x y palette draw-behind
                    flip-horizontal flip-vertical tall mirror-horizontal)

  (case post
    :lakitu
    (if flip-vertical
      (do
        (oam/write! ram sprite-offset 0 2
                    (band (oam/read ram sprite-offset 0 2) 0xbf))
        (oam/write! ram sprite-offset 1 2
                    (bor (oam/read ram sprite-offset 1 2) 0x40)))
      (do
        (oam/write! ram sprite-offset 4 2
                    (band (oam/read ram sprite-offset 4 2) 0xbf))
        (oam/write! ram sprite-offset 5 2
                    (bor (oam/read ram sprite-offset 5 2) 0x40))
        (when (< (get ram actors/addr-frenzy-enemy-timer) 16)
          (def attributes (oam/read ram sprite-offset 5 2))
          (oam/write! ram sprite-offset 2 2 (band attributes 0xbf))
          (oam/write! ram sprite-offset 3 2 attributes))))
    :spiny-egg
    (each sprite @[1 3 5]
      (oam/write! ram sprite-offset sprite 2
                   (bor (oam/read ram sprite-offset sprite 2) 0x80)))
    :shell (flip-bottom-rows-vertical! ram sprite-offset)
    nil nil)

    (clip-enemy! world ram slot id sprite-offset))
  world)

(defn bowser-flame!
  [world slot]
  (def ram (world :ram))
  (def sprite-offset (get ram (+ addr-enemy-sprite-offset slot)))
  (def x (get ram actors/addr-enemy-relative-x))
  (def y (get ram actors/addr-enemy-relative-y))
  (def attributes
    (if (zero? (band (get ram actors/addr-frame-counter) 2)) 2 0x82))
  (loop [sprite :range [0 3]]
    (oam/write! ram sprite-offset sprite 0 y)
    (oam/write! ram sprite-offset sprite 1 (+ 0x51 sprite))
    (oam/write! ram sprite-offset sprite 2 attributes)
    (oam/write! ram sprite-offset sprite 3 (+ x (* sprite 8))))
  world)

(defn clip-bowser-flame!
  [world slot]
  (def ram (world :ram))
  (def sprite-offset (get ram (+ addr-enemy-sprite-offset slot)))
  (def bits (get ram addr-enemy-offscreen-bits))
  (loop [index :range [0 4]]
    (when (not= (band bits (blshift 1 index)) 0)
      (oam/write! ram sprite-offset (- 3 index) 0 oam/offscreen-y)))
  world)

(defn power-up!
  [world slot]
  (def ram (world :ram))
  (def type (get ram actors/addr-power-up-type))
  (def tiles (get power-up-tiles type))
  (def sprite-offset (get ram (+ addr-enemy-sprite-offset slot)))
  (def x (get ram actors/addr-enemy-relative-x))
  (def y (+ (get ram actors/addr-enemy-relative-y) 8))
  (def base-attributes
    (bor (get power-up-palettes type)
         (get ram (+ actors/addr-enemy-attribute slot))))
  (oam/draw-row! ram 0 sprite-offset
                 (get tiles 0) (get tiles 1) x y base-attributes false)
  (oam/draw-row! ram 1 sprite-offset
                 (get tiles 2) (get tiles 3) x y base-attributes false)
  (when (or (= type 1) (= type 2))
    (def animated-attributes
      (bor (band (brshift (get ram actors/addr-frame-counter) 1) 3)
           (get ram (+ actors/addr-enemy-attribute slot))))
    (def limit (if (= type 1) 2 4))
    (loop [sprite :range [0 limit]]
      (oam/write! ram sprite-offset sprite 2 animated-attributes))
    (each sprite @[1 3]
      (oam/write! ram sprite-offset sprite 2
                  (bor (oam/read ram sprite-offset sprite 2) 0x40))))
  (clip-enemy! world ram slot actors/actor-power-up sprite-offset)
  world)

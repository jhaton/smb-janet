(import ./area)
(import ./bytes)
(import ./rom)
(import ./tiles)


(def block-buffer-base 0x0500)
(def block-buffer-size 0x01a0)
(def column-height 13)
(def scroll-lock-address 0x0723)

(def background-scenery
  [[[0x93 0 0 0x11 0x12 0x12 0x13 0 0 0x51 0x52 0x53 0 0 0 0]
    [0 0 0x01 0x02 0x02 0x03 0 0 0 0 0 0 0x91 0x92 0x93 0]
    [0 0 0 0x51 0x52 0x53 0x41 0x42 0x43 0 0 0 0 0 0x91 0x92]]
   [[0x97 0x87 0x88 0x89 0x99 0 0 0 0x11 0x12 0x13 0xa4 0xa5 0xa5 0xa5 0xa6]
    [0x97 0x98 0x99 0x01 0x02 0x03 0 0xa4 0xa5 0xa6 0 0x11 0x12 0x12 0x12 0x13]
    [0 0 0 0 0x01 0x02 0x02 0x03 0 0xa4 0xa5 0xa5 0xa6 0 0 0]]
   [[0x11 0x12 0x12 0x13 0 0 0 0 0 0 0 0x9c 0 0x8b 0xaa 0xaa]
    [0xaa 0xaa 0x11 0x12 0x13 0x8b 0 0x9c 0x9c 0 0 0x01 0x02 0x03 0x11 0x12]
    [0x12 0x13 0 0 0 0 0xaa 0xaa 0x9c 0xaa 0 0x8b 0 0x01 0x02 0x03]]])

(def background-metatiles
  [[tiles/cloud-top-left tiles/cloud-bottom-left tiles/empty]
   [tiles/cloud-top-middle tiles/cloud-bottom-middle tiles/empty]
   [tiles/cloud-top-right tiles/cloud-bottom-right tiles/empty]
   [tiles/bush-left tiles/empty tiles/empty]
   [tiles/bush-middle tiles/empty tiles/empty]
   [tiles/bush-right tiles/empty tiles/empty]
   [tiles/empty tiles/mountain-left tiles/mountain-dots-one]
   [tiles/mountain-top tiles/mountain-dots-one tiles/mountain-green]
   [tiles/empty tiles/mountain-right tiles/mountain-dots-two]
   [tiles/fence tiles/empty tiles/empty]
   [tiles/tree-tall-one tiles/tree-tall-two tiles/tree-trunk]
   [tiles/tree-short tiles/tree-trunk tiles/tree-trunk]])

(def foreground-metatiles
  [[tiles/water-top
    tiles/water-blank tiles/water-blank tiles/water-blank tiles/water-blank
    tiles/water-blank tiles/water-blank tiles/water-blank tiles/water-blank
    tiles/water-blank tiles/water-blank tiles/underwater-ground tiles/underwater-ground]
   [tiles/empty tiles/empty tiles/empty tiles/empty tiles/empty tiles/castle-top
    tiles/castle-brick tiles/castle-brick tiles/castle-brick tiles/castle-brick
    tiles/castle-brick tiles/empty tiles/empty]
   [tiles/empty tiles/empty tiles/empty tiles/empty tiles/empty tiles/empty
    tiles/empty tiles/empty tiles/empty tiles/empty tiles/empty
    tiles/water-top tiles/water-blank]])

(def terrain-metatiles
  [tiles/underwater-ground tiles/stone tiles/brick tiles/castle-inside-wall])
(def terrain-render-bits
  [0x0000 0x1800 0x1801 0x1807 0x180f 0x18ff 0x1f01 0x1f07
   0x1f0f 0x1f81 0x0001 0x1f8f 0x1ff1 0x18f9 0x18f1 0x1fff])

(defn block-offset
  [column row]
  (+ (if (< (% column 32) 16) 0 0xd0)
     (% column 16)
     (* (band row 0x0f) 16)))

(defn get-metatile
  [ram column row]
  (get ram (+ block-buffer-base (block-offset column row))))

(defn set-metatile!
  [ram column row metatile]
  (put ram (+ block-buffer-base (block-offset column row)) (bytes/u8 metatile))
  ram)

(defn- column-get
  [ram row]
  (get ram (+ area/metatile-buffer-base row)))

(defn- column-put!
  [ram row value]
  (put ram (+ area/metatile-buffer-base row) (bytes/u8 value)))

(defn- clear-column!
  [ram]
  (loop [row :range [0 column-height]]
    (column-put! ram row tiles/empty)))

(defn- render-background!
  [ram]
  (def scenery (get ram area/background-scenery-address))
  (when (not= scenery 0)
    (def encoded
      (get (get (get background-scenery (dec scenery))
                (% (get ram area/current-page-address) 3))
           (get ram area/current-column-address)))
    (when (not= encoded 0)
      (def kind (band encoded 0x0f))
      (def start-row (brshift encoded 4))
      (loop [offset :range [0 3]
             :while (not= (+ start-row offset) 11)]
        (column-put! ram (+ start-row offset)
                     (get (get background-metatiles (dec kind)) offset))))))

(defn- render-foreground!
  [ram]
  (def scenery (get ram area/foreground-scenery-address))
  (when (not= scenery 0)
    (def source (get foreground-metatiles (dec scenery)))
    (loop [row :range [0 column-height]]
      (def metatile (get source row))
      (when (not= metatile 0)
        (column-put! ram row metatile)))))

(defn- render-terrain!
  [ram]
  (def area-type (get ram area/area-type-address))
  (var metatile (get terrain-metatiles area-type))
  (def cloud (get ram area/cloud-override-address))
  (when (not= cloud 0)
    (set metatile tiles/cloud-block))
  (when (and (= area-type 0) (= (get ram area/world-number-address) 7))
    (set metatile tiles/castle-inside-wall))
  (var bits (get terrain-render-bits (get ram area/terrain-control-address)))
  (when (not= cloud 0)
    (set bits (band bits 0x08ff)))
  (loop [row :range [0 column-height]]
    (when (and (= area-type 2) (>= row 11))
      (set metatile tiles/stone))
    (when (not= (band bits (blshift 1 row)) 0)
      (column-put! ram row metatile))))


(def row-brick-tiles
  [tiles/coral tiles/brick-two tiles/brick tiles/brick tiles/cloud-block])
(def row-solid-tiles
  [tiles/underwater-ground tiles/stair-block tiles/stair-block tiles/castle-inside-wall])
(def column-brick-tiles
  [tiles/coral tiles/brick-two tiles/brick tiles/brick])
(def staircase-heights-address 0x9aa5)
(def staircase-rows-address 0x9aae)
(def castle-metatiles
  [[tiles/empty tiles/castle-top tiles/castle-top tiles/castle-top tiles/empty]
   [tiles/empty tiles/castle-window-right tiles/castle-brick tiles/castle-window-left tiles/empty]
   [tiles/castle-top tiles/castle-notch tiles/castle-notch tiles/castle-notch tiles/castle-top]
   [tiles/castle-brick tiles/castle-brick tiles/castle-door-top tiles/castle-brick tiles/castle-brick]
   [tiles/castle-brick tiles/castle-brick tiles/castle-door-bottom tiles/castle-brick tiles/castle-brick]
   [tiles/castle-notch tiles/castle-notch tiles/castle-notch tiles/castle-notch tiles/castle-notch]
   [tiles/castle-brick tiles/castle-door-top tiles/castle-brick tiles/castle-door-top tiles/castle-brick]
   [tiles/castle-brick tiles/castle-door-bottom tiles/castle-brick tiles/castle-door-bottom tiles/castle-brick]
   [tiles/castle-brick tiles/castle-brick tiles/castle-brick tiles/castle-brick tiles/castle-brick]
   [tiles/castle-door-top tiles/castle-brick tiles/castle-door-top tiles/castle-brick tiles/castle-door-top]
   [tiles/castle-door-bottom tiles/castle-brick tiles/castle-door-bottom tiles/castle-brick tiles/castle-door-bottom]])

(def enemy-flag-base 0x000f)
(def enemy-id-base 0x0016)
(def enemy-state-base 0x001e)
(def enemy-x-speed-base 0x0058)
(def enemy-bound-box-base 0x049a)
(def enemy-page-base 0x006e)
(def enemy-x-base 0x0087)
(def enemy-y-high-base 0x00b5)
(def enemy-y-base 0x00ce)
(def piranha-move-base 0x03d1)
(def piranha-down-y-base 0x0417)
(def piranha-up-y-base 0x0434)
(def flagpole-y-address 0x010d)
(def cannon-offset-address 0x046a)
(def cannon-page-base 0x046b)
(def cannon-x-base 0x0471)
(def cannon-y-base 0x0477)
(def brick-coin-timer-flag-address 0x06bc)
(def enemy-frenzy-queue-address 0x06cd)
(def warp-zone-control-address 0x06d6)
(def vram-address-control-address 0x0773)
(def staircase-control-address 0x0734)
(def mushroom-half-length-base 0x0736)

(def actor-piranha-plant 0x0d)
(def actor-flying-cheep-cheep 0x14)
(def actor-bullet-cheep-frenzy 0x17)
(def actor-stop-frenzy 0x18)
(def actor-flagpole 0x30)
(def actor-star-flag 0x31)
(def actor-jumpspring 0x32)

(defn- object-attributes
  [world slot]
  (def ram (world :ram))
  (def offset (get ram (+ area/area-object-offset-base slot)))
  [(band (area/data-byte world (+ offset 1)) 0x0f)
   (band (area/data-byte world offset) 0x0f)])

(defn- fixed-length!
  [ram slot length]
  (when (>= (get ram (+ area/area-object-length-base slot)) 0x80)
    (put ram (+ area/area-object-length-base slot) length)))

(defn- checked-length!
  [world slot]
  (def ram (world :ram))
  (def attrs (object-attributes world slot))
  (def fresh (>= (get ram (+ area/area-object-length-base slot)) 0x80))
  (fixed-length! ram slot (get attrs 0))
  [(get attrs 0) fresh (get attrs 1)])

(defn- render-under!
  [ram metatile row height]
  (def count (if (> height 0x80) 1 (inc height)))
  (loop [i :range [0 count]
         :let [target (+ row i)]
         :while (< target column-height)]
    (def existing (column-get ram target))
    (unless (or (= existing tiles/tree-ledge-middle)
                (= existing tiles/mushroom-ledge-middle)
                (and (= metatile tiles/mushroom-stem-under) (= existing tiles/stone))
                (> existing 0xc0))
      (column-put! ram target metatile))))

(defn- area-x
  [ram]
  (blshift (get ram area/current-column-address) 4))

(defn- area-y
  [row]
  (+ (blshift row 4) 0x20))

(defn- find-empty-enemy-slot
  [ram]
  (var slot 0)
  (while (and (< slot 5) (not= (get ram (+ enemy-flag-base slot)) 0))
    (++ slot))
  slot)

(defn- spawn-object!
  [ram slot actor-id x page y]
  (put ram (+ enemy-x-base slot) (bytes/u8 x))
  (put ram (+ enemy-page-base slot) (bytes/u8 page))
  (put ram (+ enemy-y-high-base slot) 1)
  (put ram (+ enemy-y-base slot) (bytes/u8 y))
  (put ram (+ enemy-id-base slot) actor-id)
  (put ram (+ enemy-flag-base slot) 1))

(defn- tree-ledge!
  [world slot]
  (def ram (world :ram))
  (def attrs (object-attributes world slot))
  (def row (get attrs 1))
  (def remaining (get ram (+ area/area-object-length-base slot)))
  (cond
    (= remaining 0)
    (render-under! ram tiles/tree-ledge-right row 0)
    (>= remaining 0x80)
    (do
      (put ram (+ area/area-object-length-base slot) (get attrs 0))
      (if (not= (bor (get ram area/current-page-address)
                     (get ram area/current-column-address)) 0)
        (render-under! ram tiles/tree-ledge-left row 0)
        (do
          (column-put! ram row tiles/tree-ledge-middle)
          (render-under! ram tiles/tree-ledge-trunk (inc row) 0x0f))))
    true
    (do
      (column-put! ram row tiles/tree-ledge-middle)
      (render-under! ram tiles/tree-ledge-trunk (inc row) 0x0f))))

(defn- mushroom-ledge!
  [world slot]
  (def ram (world :ram))
  (def checked (checked-length! world slot))
  (def row (get checked 2))
  (def remaining (get ram (+ area/area-object-length-base slot)))
  (cond
    (get checked 1)
    (do
      (put ram (+ mushroom-half-length-base slot) (brshift remaining 1))
      (render-under! ram tiles/mushroom-ledge-left row 0))
    (= remaining 0)
    (render-under! ram tiles/mushroom-ledge-right row 0)
    true
    (do
      (column-put! ram row tiles/mushroom-ledge-middle)
      (when (= remaining (get ram (+ mushroom-half-length-base slot)))
        (column-put! ram (inc row) tiles/mushroom-stem-top)
        (when (not= (+ row 2) 13)
          (render-under! ram tiles/mushroom-stem-under (+ row 2) 0x0f))))))

(defn- pulley-rope!
  [world slot]
  (def ram (world :ram))
  (def checked (checked-length! world slot))
  (column-put! ram 0
               (if (get checked 1)
                 tiles/pulley-rope-top-left
                 (if (not= (get ram (+ area/area-object-length-base slot)) 0)
                   tiles/pulley-rope-horizontal
                   tiles/pulley-rope-top-right))))

(defn- castle!
  [world slot]
  (def ram (world :ram))
  (def attrs (object-attributes world slot))
  (def start-row (get attrs 0))
  (fixed-length! ram slot 4)
  (def column (get ram (+ area/area-object-length-base slot)))
  (loop [row :range [start-row 11]]
    (column-put! ram row (get (get castle-metatiles (- row start-row)) column)))
  (when (not= (get ram area/current-page-address) 0)
    (cond
      (or (= column 1) (and (= start-row 0) (= column 3)))
      (column-put! ram 10 tiles/brick)
      (= column 2)
      (do
        (def enemy-slot (find-empty-enemy-slot ram))
        (spawn-object! ram enemy-slot actor-star-flag (area-x ram)
                       (get ram area/current-page-address) 0x90)))))

(defn- pipe-height
  [world slot]
  (def ram (world :ram))
  (fixed-length! ram slot 1)
  (def attrs (object-attributes world slot))
  [(get ram (+ area/area-object-length-base slot))
   (band (get attrs 0) 7)
   (get attrs 1)])

(defn- vertical-pipe!
  [world slot decorative]
  (def ram (world :ram))
  (def values (pipe-height world slot))
  (def side (not= (get values 0) 0))
  (def height (get values 1))
  (def row (get values 2))
  (var spawn (not= (get ram (+ area/area-object-length-base slot)) 0))
  (when (and (= (get ram area/area-number-address) 0)
             (= (get ram area/world-number-address) 0))
    (set spawn false))
  (when spawn
    (def enemy-slot (find-empty-enemy-slot ram))
    (when (< enemy-slot 5)
      (def x (+ (area-x ram) 8))
      (def page (+ (get ram area/current-page-address) (if (> x 0xff) 1 0)))
      (spawn-object! ram enemy-slot actor-piranha-plant x page (area-y row))
      (put ram (+ enemy-x-speed-base enemy-slot) 1)
      (put ram (+ enemy-state-base enemy-slot) 0)
      (put ram (+ piranha-move-base enemy-slot) 0)
      (put ram (+ piranha-down-y-base enemy-slot) (area-y row))
      (put ram (+ piranha-up-y-base enemy-slot) (bytes/u8 (- (area-y row) 0x18)))
      (put ram (+ enemy-bound-box-base enemy-slot) 9)))
  (column-put! ram row
               (if decorative
                 (if side tiles/pipe-decorative-top-left tiles/pipe-decorative-top-right)
                 (if side tiles/pipe-warp-top-left tiles/pipe-warp-top-right)))
  (render-under! ram
                 (if side tiles/pipe-under-left tiles/pipe-under-right)
                 (inc row) (dec height)))

(defn- sideways-pipe!
  [world slot intro]
  (def ram (world :ram))
  (fixed-length! ram slot 3)
  (def remaining (get ram (+ area/area-object-length-base slot)))
  (def left-side (not= (% remaining 2) 0))
  (def row (if intro 10 (get (object-attributes world slot) 0)))
  (if (< remaining 2)
    (do
      (def under (if left-side tiles/pipe-under-left tiles/pipe-under-right))
      (render-under! ram under 0 (if intro 8 (bytes/u8 (- row 2))))
      (when intro
        (loop [i :range [0 7]] (column-put! ram i tiles/empty))
        (column-put! ram 7
                     (if left-side tiles/pipe-warp-top-left tiles/pipe-warp-top-right)))
      (column-put! ram (dec row)
                   (if left-side tiles/pipe-connected-top tiles/pipe-under-right))
      (column-put! ram row
                   (if left-side tiles/pipe-connected-bottom tiles/pipe-under-right)))
    (do
      (column-put! ram (dec row)
                   (if left-side tiles/pipe-sideways-top-left tiles/pipe-sideways-middle-top))
      (column-put! ram row
                   (if left-side tiles/pipe-sideways-bottom-left tiles/pipe-sideways-middle-bottom)))))

(defn- flagpole!
  [ram]
  (column-put! ram 0 tiles/flagpole-top)
  (render-under! ram tiles/flagpole-middle 1 8)
  (column-put! ram 10 tiles/stair-block)
  (def x (area-x ram))
  (def flag-address (+ enemy-flag-base 5))
  (def flag (get ram flag-address))
  (spawn-object! ram 5 actor-flagpole (- x 8)
                 (- (get ram area/current-page-address) (if (< x 8) 1 0))
                 0x30)
  (put ram flag-address (bytes/u8 (inc flag)))
  (put ram flagpole-y-address 0xb0))

(defn- bullet-cannon!
  [world slot]
  (def ram (world :ram))
  (def attrs (object-attributes world slot))
  (def height (get attrs 0))
  (def row (get attrs 1))
  (column-put! ram row tiles/cannon-top)
  (when (< (bytes/u8 (dec height)) 0x80)
    (column-put! ram (inc row) tiles/cannon-body)
    (when (< (bytes/u8 (- height 2)) 0x80)
      (render-under! ram tiles/cannon-bottom (+ row 2) (- height 2))))
  (def offset (get ram cannon-offset-address))
  (put ram (+ cannon-y-base offset) (area-y row))
  (put ram (+ cannon-page-base offset) (get ram area/current-page-address))
  (put ram (+ cannon-x-base offset) (area-x ram))
  (put ram cannon-offset-address (if (> (inc offset) 5) 0 (inc offset))))

(defn- hole-empty!
  [world slot]
  (def ram (world :ram))
  (def checked (checked-length! world slot))
  (when (and (get checked 1) (= (get ram area/area-type-address) 0))
    (def offset (get ram cannon-offset-address))
    (def x (area-x ram))
    (put ram (+ cannon-x-base offset) (bytes/u8 (- x 0x10)))
    (put ram (+ cannon-page-base offset)
         (bytes/u8 (- (get ram area/current-page-address) (if (< x 0x10) 1 0))))
    (put ram (+ cannon-y-base offset) (bytes/u8 (* (+ (get checked 0) 2) 0x10)))
    (put ram cannon-offset-address (if (>= (inc offset) 5) 0 (inc offset))))
  (render-under! ram
                 (if (= (get ram area/area-type-address) 0) tiles/water-blank tiles/empty)
                 8 0x0f))

(defn- jumpspring!
  [world slot]
  (def ram (world :ram))
  (def row (get (object-attributes world slot) 1))
  (def enemy-slot (find-empty-enemy-slot ram))
  (def flag-address (+ enemy-flag-base enemy-slot))
  (def flag (get ram flag-address))
  (def y (area-y row))
  (spawn-object! ram enemy-slot actor-jumpspring (area-x ram)
                 (get ram area/current-page-address) y)
  (put ram flag-address (bytes/u8 (inc flag)))
  (put ram (+ enemy-x-speed-base enemy-slot) y)
  (column-put! ram row tiles/jumpspring-top)
  (column-put! ram (inc row) tiles/jumpspring-bottom))

(defn- row-object!
  [world slot metatiles]
  (def ram (world :ram))
  (def checked (checked-length! world slot))
  (render-under! ram (get metatiles (get ram area/area-type-address))
                 (get checked 2) 0))

(defn- special-block!
  [world slot ground-tile other-tile]
  (def ram (world :ram))
  (def row (get (object-attributes world slot) 1))
  (render-under! ram
                 (if (= (get ram area/area-type-address) 1) ground-tile other-tile)
                 row 0))

(defn- set-frenzy!
  [ram actor-id]
  (var present false)
  (loop [slot :range [0 5]]
    (when (= (get ram (+ enemy-id-base slot)) actor-id)
      (set present true)))
  (put ram enemy-frenzy-queue-address (if present 0 actor-id)))

(defn dispatch-object!
  [world slot object-index]
  (def ram (world :ram))
  (case object-index
    0 (vertical-pipe! world slot false)
    1 (case (get ram area/area-style-address)
        0 (tree-ledge! world slot)
        1 (mushroom-ledge! world slot)
        2 (bullet-cannon! world slot))
    2 (do
        (def checked (checked-length! world slot))
        (def kind (if (not= (get ram area/cloud-override-address) 0)
                    4 (get ram area/area-type-address)))
        (render-under! ram (get row-brick-tiles kind) (get checked 2) 0))
    3 (row-object! world slot row-solid-tiles)
    4 (do
        (def checked (checked-length! world slot))
        (render-under! ram
                       (if (= (get ram area/area-type-address) 0)
                         tiles/coin-underwater tiles/coin)
                       (get checked 2) 0))
    5 (do
        (def attrs (object-attributes world slot))
        (render-under! ram (get column-brick-tiles (get ram area/area-type-address))
                       (get attrs 1) (get attrs 0)))
    6 (do
        (def attrs (object-attributes world slot))
        (render-under! ram (get row-solid-tiles (get ram area/area-type-address))
                       (get attrs 1) (get attrs 0)))
    7 (vertical-pipe! world slot true)
    8 (hole-empty! world slot)
    9 (pulley-rope! world slot)
    10 (do (checked-length! world slot)
         (column-put! ram 6 tiles/bridge-railing)
         (render-under! ram tiles/bridge-block 7 0))
    11 (do (checked-length! world slot)
         (column-put! ram 7 tiles/bridge-railing)
         (render-under! ram tiles/bridge-block 8 0))
    12 (do (checked-length! world slot)
         (column-put! ram 9 tiles/bridge-railing)
         (render-under! ram tiles/bridge-block 10 0))
    13 (do (checked-length! world slot)
         (column-put! ram 10 tiles/water-top)
         (render-under! ram tiles/water-blank 11 1))
    14 (do (checked-length! world slot) (column-put! ram 3 tiles/question-coin))
    15 (do (checked-length! world slot) (column-put! ram 7 tiles/question-coin))
    16 (render-under! ram tiles/rope-vertical 0 0x0f)
    17 (do
         (render-under! ram tiles/rope-none 1 0x0f)
         (render-under! ram tiles/rope-vertical 1 (get (object-attributes world slot) 0)))
    18 (castle! world slot)
    19 (do
         (def checked (checked-length! world slot))
         (when (get checked 1) (put ram staircase-control-address 9))
         (def control (dec (get ram staircase-control-address)))
         (put ram staircase-control-address control)
         (render-under! ram tiles/stair-block
                        (rom/read-cpu (world :rom) (+ staircase-rows-address control))
                        (rom/read-cpu (world :rom) (+ staircase-heights-address control))))
    20 (sideways-pipe! world slot false)
    21 (render-under! ram tiles/flag-ball 2 (get (object-attributes world slot) 0))
    22 (render-under! ram tiles/question-powerup (get (object-attributes world slot) 1) 0)
    23 (render-under! ram tiles/question-coin (get (object-attributes world slot) 1) 0)
    24 (render-under! ram tiles/hidden-one-coin (get (object-attributes world slot) 1) 0)
    25 (when (not= (get ram area/hidden-one-up-address) 0)
         (put ram area/hidden-one-up-address 0)
         (special-block! world slot tiles/hidden-one-up tiles/brick-two-one-up))
    26 (special-block! world slot tiles/brick-two-powerup tiles/brick-powerup)
    27 (special-block! world slot tiles/brick-two-vine tiles/brick-vine)
    28 (special-block! world slot tiles/brick-two-star tiles/brick-star)
    29 (do
         (put ram brick-coin-timer-flag-address 0)
         (special-block! world slot tiles/brick-two-coins tiles/brick-coins))
    30 (special-block! world slot tiles/brick-two-one-up tiles/brick-one-up)
    31 (do
         (def row (get (object-attributes world slot) 1))
         (column-put! ram row tiles/water-pipe-top)
         (column-put! ram (inc row) tiles/water-pipe-bottom))
    32 (render-under! ram tiles/block-empty (get (object-attributes world slot) 1) 0)
    33 (jumpspring! world slot)
    34 (sideways-pipe! world slot true)
    35 (flagpole! ram)
    36 (do (put ram vram-address-control-address 8)
         (render-under! ram tiles/axe 6 0))
    37 (render-under! ram tiles/bowser-bridge-chain 7 0)
    38 (do (fixed-length! ram slot 0x0c)
         (render-under! ram tiles/bowser-bridge-block 8 0))
    39 (do
         (put ram warp-zone-control-address
              (if (= (get ram area/world-number-address) 0)
                4
                (if (not= (get ram area/area-type-address) 1) 5 6)))
         (loop [enemy-slot :range [0 5]]
           (when (= (get ram (+ enemy-id-base enemy-slot)) actor-piranha-plant)
             (put ram (+ enemy-flag-base enemy-slot) 0)))
         (put ram scroll-lock-address
              (bxor (get ram scroll-lock-address) 1)))
    40 (put ram scroll-lock-address
            (bxor (get ram scroll-lock-address) 1))
    41 (put ram scroll-lock-address
            (bxor (get ram scroll-lock-address) 1))
    42 (set-frenzy! ram actor-flying-cheep-cheep)
    43 (set-frenzy! ram actor-bullet-cheep-frenzy)
    44 (set-frenzy! ram actor-stop-frenzy)
    45 nil
    46 (do
         (def value (area/data-byte world
                                    (inc (get ram (+ area/area-object-offset-base slot)))))
         (if (= (band value 0x40) 0)
           (do
             (put ram area/terrain-control-address (band value 0x0f))
             (put ram area/background-scenery-address
                  (brshift (band value 0x30) 4)))
           (do
             (def scenery (band value 7))
             (put ram area/foreground-scenery-address (if (>= scenery 4) 0 scenery))
             (when (>= scenery 4)
               (put ram area/background-color-address scenery)))))
    (error (string "unsupported SMB1 area object " object-index)))
  world)
(defn render-column!
  "Construct one reference metatile column, dispatch its area objects, and update the collision buffer."
  [world]
  (def ram (world :ram))
  (when (not= (get ram area/backloading-address) 0)
    (area/process-objects! world dispatch-object!))
  (clear-column! ram)
  (render-background! ram)
  (render-foreground! ram)
  (render-terrain! ram)
  (area/process-objects! world dispatch-object!)

  (def column (get ram area/block-buffer-column-address))
  (loop [row :range [0 column-height]]
    (def metatile (column-get ram row))
    (set-metatile! ram column row
                   (if (or (< metatile tiles/pipe-warp-top-left)
                           (and (>= metatile tiles/rope-vertical) (< metatile tiles/brick-two))
                           (and (>= metatile tiles/cloud-top-left) (< metatile tiles/cloud-block)))
                     tiles/empty
                     metatile)))
  world)

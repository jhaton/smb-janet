(import ./bytes)
(import ./reset)
(import ./rom)
(import ./scroll)
(import ./timers)

(def world-offsets-address 0x9cb4)
(def area-offsets-address 0x9cbc)
(def enemy-high-offsets-address 0x9ce0)
(def enemy-address-low-address 0x9ce4)
(def enemy-address-high-address 0x9d06)
(def area-high-offsets-address 0x9d28)
(def area-address-low-address 0x9d2c)
(def area-address-high-address 0x9d4e)

(def area-data-low-address 0x00e7)
(def area-data-high-address 0x00e8)
(def enemy-data-low-address 0x00e9)
(def enemy-data-high-address 0x00ea)
(def player-entrance-address 0x0710)
(def game-timer-setting-address 0x0715)
(def screen-left-page-address 0x071a)
(def column-sets-address 0x071e)
(def area-parser-task-address 0x071f)
(def current-name-table-high-address 0x0720)
(def current-name-table-low-address 0x0721)
(def current-page-address 0x0725)
(def current-column-address 0x0726)
(def terrain-control-address 0x0727)
(def backloading-address 0x0728)
(def area-object-page-address 0x072a)
(def area-object-page-select-address 0x072b)
(def area-data-offset-address 0x072c)
(def area-object-offset-base 0x072d)
(def area-object-length-base 0x0730)
(def area-style-address 0x0733)
(def enemy-data-offset-address 0x0739)
(def enemy-object-page-address 0x073a)
(def enemy-object-page-select-address 0x073b)
(def foreground-scenery-address 0x0741)
(def background-scenery-address 0x0742)
(def cloud-override-address 0x0743)
(def background-color-address 0x0744)
(def loop-command-address 0x0745)
(def area-type-address 0x074e)
(def area-low-offset-address 0x074f)
(def area-pointer-address 0x0750)
(def entrance-page-address 0x0751)
(def alternate-entrance-address 0x0752)
(def halfway-page-address 0x075b)
(def level-number-address 0x075c)
(def hidden-one-up-address 0x075d)
(def world-number-address 0x075f)
(def area-number-address 0x0760)
(def primary-hard-mode-address 0x076a)
(def disable-screen-address 0x0774)
(def area-music-queue-address 0x00fb)
(def secondary-hard-mode-address 0x06cc)
(def block-buffer-column-address 0x06a0)
(def metatile-buffer-base 0x06a1)

(def vertical-pipe-one 0)
(def area-style-object 1)
(def row-of-bricks 2)
(def row-of-solid-blocks 3)
(def row-of-coins 4)
(def column-of-bricks 5)
(def column-of-solid-blocks 6)
(def vertical-pipe-two 7)
(def hole-empty 8)
(def pulley-rope 9)
(def bridge-high 10)
(def bridge-middle 11)
(def bridge-low 12)
(def hole-water 13)
(def question-row-high 14)
(def question-row-low 15)
(def endless-rope 16)
(def balance-platform-rope 17)
(def castle-object 18)
(def staircase-object 19)
(def exit-pipe 20)
(def flag-balls 21)
(def question-powerup 22)
(def question-coin 23)
(def question-one-coin 24)
(def hidden-one-up 25)
(def brick-powerup 26)
(def brick-vine 27)
(def brick-star 28)
(def brick-coins 29)
(def brick-one-up 30)
(def water-pipe 31)
(def empty-block 32)
(def jumpspring 33)
(def intro-pipe 34)
(def flagpole-object 35)
(def axe-object 36)
(def chain-object 37)
(def castle-bridge 38)
(def scroll-lock-warp 39)
(def scroll-lock-one 40)
(def scroll-lock-two 41)
(def flying-cheep-cheep 42)
(def bullet-or-cheep-frenzy 43)
(def stop-frenzy 44)
(def loop-command 45)
(def alter-area-attributes 46)

(defn- world-rom
  [world]
  (or (get world :rom)
      (error "world has no attached SMB1 ROM")))

(defn- store-u16!
  [ram low-address high-address value]
  (put ram low-address (bytes/low-u16 value))
  (put ram high-address (bytes/high-u16 value)))

(defn data-address
  [ram]
  (bytes/pack-u16 (get ram area-data-high-address)
                  (get ram area-data-low-address)))

(defn enemy-address
  [ram]
  (bytes/pack-u16 (get ram enemy-data-high-address)
                  (get ram enemy-data-low-address)))

(defn data-byte
  [world offset]
  (rom/read-cpu (world-rom world)
                (bytes/u16 (+ (data-address (world :ram)) offset))))

(defn enemy-byte
  [world offset]
  (rom/read-cpu (world-rom world)
                (bytes/u16 (+ (enemy-address (world :ram)) offset))))

(defn world-area-range
  [world world-number]
  (unless (and (int? world-number) (>= world-number 0) (< world-number 8))
    (error (string "world number out of range: " world-number)))
  (def image (world-rom world))
  (def first (rom/read-cpu image (+ world-offsets-address world-number)))
  (def end (if (= world-number 7)
             0x24
             (rom/read-cpu image (+ world-offsets-address (inc world-number)))))
  [first end])

(defn load-pointer!
  [world]
  (def ram (world :ram))
  (def image (world-rom world))
  (def world-number (get ram world-number-address))
  (def area-number (get ram area-number-address))
  (def world-offset (rom/read-cpu image (+ world-offsets-address world-number)))
  (def area-pointer
    (rom/read-cpu image (+ area-offsets-address
                           (bytes/u8 (+ world-offset area-number)))))
  (put ram area-pointer-address area-pointer)
  (put ram area-type-address (band (brshift area-pointer 5) 3))
  world)

(defn load-data-addresses!
  [world]
  (def ram (world :ram))
  (def image (world-rom world))
  (def pointer (get ram area-pointer-address))
  (def area-type (band (brshift pointer 5) 3))
  (def low-offset (band pointer 0x1f))
  (put ram area-type-address area-type)
  (put ram area-low-offset-address low-offset)

  (def enemy-table-offset
    (+ (rom/read-cpu image (+ enemy-high-offsets-address area-type)) low-offset))
  (def enemy-data-address
    (bor (rom/read-cpu image (+ enemy-address-low-address enemy-table-offset))
         (blshift (rom/read-cpu image (+ enemy-address-high-address enemy-table-offset)) 8)))
  (store-u16! ram enemy-data-low-address enemy-data-high-address enemy-data-address)

  (def area-table-offset
    (+ (rom/read-cpu image (+ area-high-offsets-address area-type)) low-offset))
  (var area-address
    (bor (rom/read-cpu image (+ area-address-low-address area-table-offset))
         (blshift (rom/read-cpu image (+ area-address-high-address area-table-offset)) 8)))
  (def header-zero (rom/read-cpu image area-address))
  (def header-one (rom/read-cpu image (inc area-address)))

  (def scenery (band header-zero 7))
  (if (>= scenery 4)
    (do
      (put ram foreground-scenery-address 0)
      (put ram background-color-address scenery))
    (put ram foreground-scenery-address scenery))
  (put ram player-entrance-address (band (brshift header-zero 3) 7))
  (put ram game-timer-setting-address (brshift header-zero 6))

  (def style (brshift header-one 6))
  (put ram terrain-control-address (band header-one 0x0f))
  (put ram background-scenery-address (band (brshift header-one 4) 3))
  (if (= style 3)
    (do
      (put ram area-style-address 0)
      (put ram cloud-override-address 3))
    (put ram area-style-address style))

  (set area-address (bytes/u16 (+ area-address 2)))
  (store-u16! ram area-data-low-address area-data-high-address area-address)
  world)

(defn initialize!
  "Initialize the SMB1 area parser and header state without presentation or actor-mode work."
  [world]
  (def ram (world :ram))
  (reset/initialize-memory! ram 0x4b)
  (timers/initialize! ram)
  (put ram screen-left-page-address (get ram halfway-page-address))
  (when (not= (get ram alternate-entrance-address) 0)
    (put ram screen-left-page-address (get ram entrance-page-address)))
  (put ram current-page-address (get ram screen-left-page-address))
  (put ram backloading-address (get ram screen-left-page-address))
  (def screen-right (scroll/screen-position! ram))
  (put ram current-name-table-high-address (if (= (band screen-right 1) 0) 0x20 0x24))
  (put ram current-name-table-low-address 0x80)
  (put ram block-buffer-column-address (blshift (band screen-right 1) 4))
  (loop [index :range [0 3]]
    (put ram (+ area-object-length-base index)
         (bytes/u8 (dec (get ram (+ area-object-length-base index))))))
  (put ram column-sets-address 0x0b)
  (load-data-addresses! world)
  (when (or (not= (get ram primary-hard-mode-address) 0)
            (and (>= (get ram world-number-address) 4)
                 (or (not= (get ram world-number-address) 4)
                     (>= (get ram level-number-address) 2))))
    (put ram secondary-hard-mode-address
         (bytes/u8 (inc (get ram secondary-hard-mode-address)))))
  (when (not= (get ram halfway-page-address) 0)
    (put ram player-entrance-address 2))
  (put ram area-music-queue-address 0)
  (put ram disable-screen-address 1)
  world)

(defn decode-object
  [data-zero data-one]
  (def nibble (band data-zero 0x0f))
  (def data (band data-one 0x7f))
  (case nibble
    0x0c (get [hole-empty pulley-rope bridge-high bridge-middle bridge-low
               hole-water question-row-high question-row-low]
              (band (brshift data 4) 7))
    0x0d (case (band data 0x3f)
           0x00 intro-pipe
           0x01 flagpole-object
           0x02 axe-object
           0x03 chain-object
           0x04 castle-bridge
           0x05 scroll-lock-warp
           0x06 scroll-lock-one
           0x07 scroll-lock-two
           0x08 flying-cheep-cheep
           0x09 bullet-or-cheep-frenzy
           0x0a stop-frenzy
           0x0b loop-command
           0x0c alter-area-attributes
           (error (string/format "invalid area control object: 0x%02x" data)))
    0x0e alter-area-attributes
    0x0f (get [endless-rope balance-platform-rope castle-object staircase-object
               exit-pipe flag-balls question-powerup question-coin]
              (band (brshift data 4) 7))
    (if (= (band data 0x70) 0)
      (get [question-powerup question-coin question-one-coin hidden-one-up
            brick-powerup brick-vine brick-star brick-coins brick-one-up
            water-pipe empty-block jumpspring intro-pipe flagpole-object
            axe-object chain-object]
           (band data 0x0f))
      (case (band (brshift data 4) 7)
        1 area-style-object
        2 row-of-bricks
        3 row-of-solid-blocks
        4 row-of-coins
        5 column-of-bricks
        6 column-of-solid-blocks
        7 (if (= (band data 0x78) 0x78) vertical-pipe-one vertical-pipe-two)
        (error (string/format "invalid area object: 0x%02x 0x%02x" nibble data))))))

(defn increment-column!
  [ram]
  (def column (bytes/u8 (inc (get ram current-column-address))))
  (if (= (band column 0x0f) 0)
    (do
      (put ram current-page-address
           (bytes/u8 (inc (get ram current-page-address))))
      (put ram current-column-address 0))
    (put ram current-column-address column))
  (put ram block-buffer-column-address
       (band (inc (get ram block-buffer-column-address)) 0x1f))
  ram)

(defn process-objects!
  "Advance the three-slot area-object stream scheduler for the current column."
  [world object-handler]
  (unless (function? object-handler)
    (error "area object handler must be a function"))
  (def ram (world :ram))
  (var finished false)
  (while (not finished)
    (var behind false)
    (var objoff 2)
    (var returned false)
    (while (and (>= objoff 0) (not returned))
      (set behind false)
      (var should-decode true)
      (def length-address (+ area-object-length-base objoff))
      (def object-length (get ram length-address))

      (when (>= object-length 0x80)
        (def stream-offset (get ram area-data-offset-address))
        (def data-zero (data-byte world stream-offset))
        (when (not= data-zero 0xfd)
          (def data-one (data-byte world (bytes/u8 (inc stream-offset))))
          (def first-nibble (band data-zero 0x0f))
          (when (= (get ram area-object-page-select-address) 0)
            (cond
              (not= (band data-one 0x80) 0)
              (do
                (put ram area-object-page-select-address 1)
                (put ram area-object-page-address
                     (bytes/u8 (inc (get ram area-object-page-address)))))
              (and (= first-nibble 0x0d) (= (band data-one 0x40) 0))
              (do
                (put ram area-object-page-select-address 1)
                (put ram area-object-page-address (band data-one 0x1f))
                (set should-decode false))))
          (when (and (or (not= first-nibble 0x0e)
                         (= (get ram backloading-address) 0))
                     (> (get ram current-page-address)
                        (get ram area-object-page-address)))
            (set behind true)
            (set should-decode false))))

      (if should-decode
        (do
          (def offset
            (if (>= (get ram length-address) 0x80)
              (get ram area-data-offset-address)
              (get ram (+ area-object-offset-base objoff))))
          (def data-zero (data-byte world offset))
          (when (not= data-zero 0xfd)
            (def data-one (band (data-byte world (bytes/u8 (inc offset))) 0x7f))
            (unless (and (= (band data-zero 0x0f) 0x0d)
                         (= (band data-one 0x40) 0))
              (def object-index (decode-object data-zero data-one))
              (when (= object-index loop-command)
                (put ram loop-command-address
                     (bytes/u8 (inc (get ram loop-command-address)))))
              (cond
                (< (get ram length-address) 0x80)
                (object-handler world objoff object-index)
                (= (get ram area-object-page-address)
                   (get ram current-page-address))
                (if (not= (get ram backloading-address) 0)
                  (do
                    (put ram backloading-address 0)
                    (when (< (get ram area-object-length-base) 0x80)
                      (put ram area-object-length-base
                           (bytes/u8 (dec (get ram area-object-length-base)))))
                    (set returned true))
                  (when (= (brshift data-zero 4)
                           (get ram current-column-address))
                    (put ram (+ area-object-offset-base objoff)
                         (get ram area-data-offset-address))
                    (object-handler world objoff object-index)
                    (put ram area-data-offset-address
                         (bytes/u8 (+ (get ram area-data-offset-address) 2)))
                    (put ram area-object-page-select-address 0)))
                (and (= (band data-zero 0x0f) 0x0e)
                     (not= (get ram backloading-address) 0))
                (do
                  (put ram (+ area-object-offset-base objoff)
                       (get ram area-data-offset-address))
                  (object-handler world objoff object-index)
                  (put ram area-data-offset-address
                       (bytes/u8 (+ (get ram area-data-offset-address) 2)))
                  (put ram area-object-page-select-address 0))))))
        (do
          (put ram area-data-offset-address
               (bytes/u8 (+ (get ram area-data-offset-address) 2)))
          (put ram area-object-page-select-address 0)))

      (unless returned
        (when (< (get ram length-address) 0x80)
          (put ram length-address (bytes/u8 (dec (get ram length-address)))))
        (-- objoff)))

    (if returned
      (set finished true)
      (when (and (not behind) (= (get ram backloading-address) 0))
        (set finished true))))
  world)

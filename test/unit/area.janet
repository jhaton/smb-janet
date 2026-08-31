(import spork/test)
(import ../../src/smb/actors)
(import ../../src/smb/area)
(import ../../src/smb/enemies)
(import ../../src/smb/metatiles)
(import ../../src/smb/player)
(import ../../src/smb/movement)
(import ../../src/smb/rom)
(import ../../src/smb/scroll)
(import ../../src/smb/state)

(defn- numbers
  [fields start end]
  (tuple ;(map scan-number (slice fields start end))))

(defn- hex-bytes
  [text]
  (def result (buffer/new (div (length text) 2)))
  (loop [index :range [0 (length text) 2]]
    (buffer/push result (scan-number (slice text index (+ index 2)) 16)))
  result)

(defn- assert-equal
  [actual expected context]
  (test/assert (deep= actual expected) context))

(def image (rom/load))
(def world (rom/attach! (state/make-world) image))
(def ram (world :ram))
(var pointer-count 0)
(var decoder-count 0)
(var column-count 0)
(var scroll-count 0)
(var handler-count 0)
(def enemy-rows @[])
(var loop-count 0)
(var active-world -1)
(var active-area -1)

(defn- check-pointer
  [line fields]
  (def expected (numbers fields 3 15))
  (buffer/fill ram)
  (put ram area/world-number-address (scan-number (get fields 1)))
  (put ram area/area-number-address (scan-number (get fields 2)))
  (area/load-pointer! world)
  (area/load-data-addresses! world)
  (def actual
    [(get ram area/area-pointer-address)
     (get ram area/area-type-address)
     (area/enemy-address ram)
     (area/data-address ram)
     (get ram area/foreground-scenery-address)
     (get ram area/background-scenery-address)
     (get ram area/background-color-address)
     (get ram area/player-entrance-address)
     (get ram area/game-timer-setting-address)
     (get ram area/terrain-control-address)
     (get ram area/area-style-address)
     (get ram area/cloud-override-address)])
  (assert-equal actual expected (string "area pointer oracle mismatch: " line)))

(defn- prepare-column-area!
  [world-number area-number]
  (when (or (not= world-number active-world) (not= area-number active-area))
    (set active-world world-number)
    (set active-area area-number)
    (buffer/fill ram)
    (put ram area/world-number-address world-number)
    (put ram area/area-number-address area-number)
    (area/load-pointer! world)
    (area/initialize! world)))

(defn- check-column
  [line fields]
  (def world-number (scan-number (get fields 1)))
  (def area-number (scan-number (get fields 2)))
  (prepare-column-area! world-number area-number)
  (metatiles/render-column! world)
  (def expected-state (numbers fields 4 11))
  (def actual-state
    [(get ram area/current-page-address)
     (get ram area/current-column-address)
     (get ram area/block-buffer-column-address)
     (get ram area/area-data-offset-address)
     (get ram area/area-object-page-address)
     (get ram area/area-object-page-select-address)
     (get ram area/backloading-address)])
  (assert-equal actual-state expected-state
                (string "area parser state mismatch: " line
                        "; expected " (string/join (map string expected-state) ",")
                        ", got " (string/join (map string actual-state) ",")))
  (assert-equal (buffer/slice ram area/metatile-buffer-base (+ area/metatile-buffer-base 13))
                (hex-bytes (get fields 11))
                (string "metatile column mismatch: " line))
  (def collision (buffer/new 13))
  (loop [row :range [0 13]]
    (buffer/push collision
                 (metatiles/get-metatile ram (get ram area/block-buffer-column-address) row)))
  (assert-equal collision (hex-bytes (get fields 12))
                (string "collision column mismatch: " line))
  (assert-equal (buffer/slice ram area/area-object-length-base
                              (+ area/area-object-length-base 3))
                (hex-bytes (get fields 13))
                (string "area object length mismatch: " line))
  (assert-equal (buffer/slice ram area/area-object-offset-base
                              (+ area/area-object-offset-base 3))
                (hex-bytes (get fields 14))
                (string "area object offset mismatch: " line))
  (each [start length index name]
    [[0x000f 7 15 "enemy flag"]
     [0x0016 6 16 "enemy id"]
     [0x006e 6 17 "enemy page"]
     [0x0087 6 18 "enemy x"]
     [0x00cf 6 19 "enemy y"]]
    (def actual (buffer/slice ram start (+ start length)))
    (def expected (hex-bytes (get fields index)))
    (assert-equal actual expected
                  (string/format "%s mismatch: %s; expected %p, got %p"
                                 name line expected actual)))
  (area/increment-column! ram))

(defn- check-scroll
  [line fields]
  (def values (numbers fields 1 11))
  (buffer/fill ram)
  (put ram scroll/screen-left-page-address (get values 0))
  (put ram scroll/screen-left-x-address (get values 1))
  (put ram scroll/mirror-ppu-control-one-address 0xa6)
  (put ram scroll/scroll-thirty-two-address 0xf8)
  (scroll/scroll-screen! ram (get values 2))
  (def actual
    [(get ram scroll/scroll-amount-address)
     (get ram scroll/scroll-thirty-two-address)
     (get ram scroll/screen-left-page-address)
     (get ram scroll/screen-left-x-address)
     (get ram scroll/screen-right-page-address)
     (get ram scroll/screen-right-x-address)
     (get ram scroll/mirror-ppu-control-one-address)])
  (assert-equal actual (slice values 3) (string "scroll oracle mismatch: " line)))

(def handler-inputs
  {"locked" [2 0 0x70 1 0]
   "left-threshold" [2 0 0x40 0 0]
   "collision" [2 0 0x70 0 1]
   "zero" [0 0 0x70 0 0]
   "overflow" [0x81 0 0x70 0 0]
   "one-mid" [1 0 0x60 0 0]
   "two-mid" [2 0 0x60 0 0]
   "two-right" [2 0 0x70 0 0]
   "platform" [1 2 0x70 0 0]})

(defn- check-scroll-handler
  [line fields]
  (def input (get handler-inputs (get fields 1)))
  (buffer/fill ram)
  (put ram scroll/screen-left-page-address 1)
  (scroll/screen-position! ram)
  (put ram movement/page-base 1)
  (put ram movement/x-position-base 0x80)
  (put ram scroll/player-scroll-address (get input 0))
  (put ram scroll/platform-scroll-address (get input 1))
  (put ram scroll/player-position-for-scroll-address (get input 2))
  (put ram scroll/scroll-lock-address (get input 3))
  (put ram scroll/side-collision-timer-address (get input 4))
  (scroll/handle! ram)
  (def actual
    [(get ram scroll/player-scroll-address)
     (get ram scroll/platform-scroll-address)
     (get ram scroll/scroll-amount-address)
     (get ram scroll/screen-left-page-address)
     (get ram scroll/screen-left-x-address)
     (get ram scroll/screen-right-page-address)
     (get ram scroll/screen-right-x-address)
     (get ram scroll/scroll-thirty-two-address)])
  (assert-equal actual (numbers fields 2 10)
                (string "scroll handler oracle mismatch: " line)))

(defn- check-loop-command
  [line fields]
  (def index (scan-number (get fields 1)))
  (def correct (scan-number (get fields 2)))
  (buffer/fill ram)
  (put ram area/world-number-address
       (rom/read-cpu image (+ enemies/loop-worlds-address index)))
  (put ram area/current-page-address
       (rom/read-cpu image (+ enemies/loop-pages-address index)))
  (put ram area/current-column-address 0)
  (put ram area/loop-command-address 1)
  (put ram movement/y-position-base
       (+ (rom/read-cpu image (+ enemies/loop-y-address index))
          (if (= correct 1) 0 1)))
  (put ram enemies/player-state-address 0)
  (put ram movement/page-base 0x20)
  (put ram scroll/screen-left-page-address 0x21)
  (put ram scroll/screen-right-page-address 0x22)
  (put ram area/area-object-page-address 0x23)
  (put ram area/enemy-data-offset-address 0x34)
  (put ram area/enemy-object-page-address 0x24)
  (put ram area/area-data-offset-address 0x35)
  (put ram area/enemy-object-page-select-address 1)
  (put ram area/area-object-page-select-address 1)
  (put ram enemies/enemy-frenzy-buffer-address 0x17)
  (loop [slot :range [0 5]]
    (put ram (+ enemies/enemy-flag-base slot) 1)
    (put ram (+ enemies/enemy-id-base slot) 6)
    (put ram (+ enemies/enemy-state-base slot) 2))
  (when (= (get ram area/world-number-address) 6)
    (put ram enemies/multi-loop-pass-address 2)
    (put ram enemies/multi-loop-correct-address 2))
  (enemies/handle-loop-command! world)
  (def actual
    [(get ram movement/page-base)
     (get ram area/current-page-address)
     (get ram scroll/screen-left-page-address)
     (get ram scroll/screen-right-page-address)
     (get ram area/area-object-page-address)
     (get ram area/enemy-data-offset-address)
     (get ram area/enemy-object-page-address)
     (get ram area/area-data-offset-address)
     (get ram area/enemy-object-page-select-address)
     (get ram area/area-object-page-select-address)
     (get ram enemies/multi-loop-pass-address)
     (get ram enemies/multi-loop-correct-address)
     (get ram area/loop-command-address)])
  (assert-equal actual (numbers fields 3 16)
                (string "loop command state mismatch: " line))
  (assert-equal
    (buffer/slice ram enemies/enemy-flag-base (+ enemies/enemy-flag-base 5))
    (hex-bytes (get fields 16))
    (string "loop command enemy reset mismatch: " line))
  (assert-equal (get ram enemies/enemy-frenzy-buffer-address)
                (scan-number (get fields 17))
                (string "loop command frenzy reset mismatch: " line)))

(defn- check-enemy-stream
  []
  (var row-index 0)
  (loop [world-number :range [0 8]]
    (def world-range (area/world-area-range world world-number))
    (loop [area-number :range [0 (- (get world-range 1) (get world-range 0))]]
      (buffer/fill ram)
      (put ram area/world-number-address world-number)
      (put ram area/area-number-address area-number)
      (area/load-pointer! world)
      (area/initialize! world)
      (var sequence 0)
      (var ended false)
      (var page 0)
      (while (and (< page 32) (not ended))
        (var x 0)
        (while (and (< x 256) (not ended))
          (put ram scroll/screen-right-page-address page)
          (put ram scroll/screen-right-x-address x)
          (def before (get ram area/enemy-data-offset-address))
          (enemies/process-stream! world 0)
          (def after (get ram area/enemy-data-offset-address))
          (when (or (not= before after)
                    (not= (get ram enemies/enemy-flag-base) 0))
            (def expected (numbers (get enemy-rows row-index) 1 13))
            (def actual
              [world-number area-number sequence page x before after
               (get ram enemies/enemy-id-base)
               (get ram enemies/enemy-flag-base)
               (get ram enemies/enemy-page-base)
               (get ram enemies/enemy-x-base)
               (get ram enemies/enemy-y-base)])
            (assert-equal actual expected
                          (string "enemy stream mismatch at row " row-index
                                  "; expected " (string/join (map string expected) ",")
                                  ", got " (string/join (map string actual) ",")))
            (++ row-index)
            (++ sequence)
            (put ram enemies/enemy-flag-base 0)
            (put ram enemies/enemy-id-base 0))
          (when (= (area/enemy-byte world
                                    (get ram area/enemy-data-offset-address)) 0xff)
            (set ended true))
          (set x (+ x 16)))
        (++ page))))
  (assert-equal row-index 549 "enemy stream vector count"))

(test/start-suite "SMB1 area construction and scrolling oracle parity")

(each line (string/split "\n" (slurp "build/area-vectors.tsv"))
  (when (pos? (length line))
    (def fields (string/split "\t" line))
    (case (first fields)
      "A" (do (++ pointer-count) (check-pointer line fields))
      "D" (do
            (++ decoder-count)
            (assert-equal (area/decode-object (scan-number (get fields 1))
                                              (scan-number (get fields 2)))
                          (scan-number (get fields 3))
                          (string "area decoder mismatch: " line)))
      "C" (do (++ column-count) (check-column line fields))
      "E" (array/push enemy-rows fields)
      "L" (do (++ loop-count) (check-loop-command line fields))
      "S" (do (++ scroll-count) (check-scroll line fields))
      "H" (do (++ handler-count) (check-scroll-handler line fields))
      (error (string "unknown area oracle row: " line)))))

(check-enemy-stream)

(buffer/fill ram)
(put ram area/current-column-address 4)
(put ram area/current-page-address 3)
(put ram player/addr-player-y 0x29)
(metatiles/dispatch-object! world 0 35)
(test/assert (= (get ram player/addr-player-y) 0x29)
             "flagpole area object must not overwrite Mario's Y position")
(test/assert (deep= [(get ram (+ actors/addr-enemy-flag 5))
                     (get ram (+ actors/addr-enemy-id 5))
                     (get ram (+ actors/addr-enemy-page 5))
                     (get ram (+ actors/addr-enemy-x 5))
                     (get ram (+ actors/addr-enemy-y-high 5))
                     (get ram (+ actors/addr-enemy-y 5))]
                    [1 actors/actor-flagpole 3 0x38 0 0x30])
             "flagpole area object must occupy fixed slot 5 without object Y-high state")

(buffer/fill ram)
(put ram area/current-column-address 4)
(put ram area/current-page-address 3)
(put ram (+ actors/addr-enemy-y-high 5) 1)
(metatiles/dispatch-object! world 0 35)
(test/assert (= (get ram (+ actors/addr-enemy-y-high 5)) 1)
             "flagpole spawn must preserve slot 5 Y-high state")

(buffer/fill ram)
(put ram 0x00e7 0x51)
(put ram 0x00e8 0x85)
(put ram area/area-object-length-base 0xff)
(put ram area/area-object-offset-base 0)
(put ram area/area-number-address 1)
(put ram area/current-column-address 2)
(put ram area/current-page-address 1)
(metatiles/dispatch-object! world 0 0)
(test/assert (deep= [(get ram actors/addr-enemy-flag)
                     (get ram actors/addr-enemy-id)
                     (get ram actors/addr-enemy-page)
                     (get ram actors/addr-enemy-x)
                     (get ram actors/addr-enemy-y-high)
                     (get ram actors/addr-enemy-y)
                     (get ram 0x0417)
                     (get ram 0x0434)]
                    [1 actors/actor-piranha 1 0x28 1 0x80 0x68 0x80])
             "pipe area object must preserve Piranha up and down endpoints")

(assert-equal pointer-count 36 "area pointer vector count")
(assert-equal decoder-count 339 "area decoder vector count")
(assert-equal column-count 9216 "area column vector count")
(assert-equal loop-count 22 "loop command vector count")
(assert-equal scroll-count 72 "scroll vector count")
(assert-equal handler-count 9 "scroll handler vector count")
(test/end-suite)

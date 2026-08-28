(import ./area)
(import ./bytes)
(import ./rom)
(import ./movement)
(import ./scroll)

(def enemy-flag-base 0x000f)
(def enemy-id-base 0x0016)
(def enemy-state-base 0x001e)
(def enemy-page-base 0x006e)
(def enemy-x-base 0x0087)
(def enemy-y-high-base 0x00b5)
(def enemy-y-base 0x00ce)
(def enemy-offscreen-base 0x03d8)
(def vine-flag-offset-address 0x0398)
(def enemy-frenzy-buffer-address 0x06cb)
(def enemy-frenzy-queue-address 0x06cd)
(def group-count-address 0x06d3)
(def frenzy-timer-address 0x078f)
(def flame-y-table-address 0xc59d)
(def loopback-offsets-address 0x9bf8)
(def loop-worlds-address 0xc06b)
(def loop-pages-address 0xc076)
(def loop-y-address 0xc081)
(def player-state-address 0x001d)
(def area-parser-task-address 0x071f)
(def multi-loop-correct-address 0x06d9)
(def multi-loop-pass-address 0x06da)

(def actor-buzzy-beetle 2)
(def actor-goomba 6)
(def actor-podoboo 12)
(def actor-lakitu 17)
(def actor-flying-cheep-cheep 20)
(def actor-bowser-flame 21)
(def actor-stop-frenzy 24)
(def actor-firebar-one 27)
(def actor-firebar-five 31)
(def actor-balance-platform 36)
(def actor-large-lift-up 38)
(def actor-large-lift-down 39)
(def actor-small-lift-up 43)
(def actor-small-lift-down 44)
(def actor-vine 47)

(defn- put-at-right-extent!
  [world slot y]
  (def ram (world :ram))
  (def screen-x (get ram scroll/screen-right-x-address))
  (put ram (+ enemy-y-base slot) y)
  (put ram (+ enemy-x-base slot) (bytes/u8 (+ screen-x 0x20)))
  (put ram (+ enemy-page-base slot)
       (bytes/u8 (+ (get ram scroll/screen-right-page-address)
                    (if (>= screen-x 0xe0) 1 0))))
  (put ram (+ enemy-y-high-base slot) 1)
  (put ram (+ enemy-flag-base slot) 1))

(defn- add-x!
  [ram slot amount]
  (def result
    (bytes/add-u16 (get ram (+ enemy-page-base slot))
                   (get ram (+ enemy-x-base slot))
                   0 amount))
  (put ram (+ enemy-page-base slot) (bytes/high-u16 result))
  (put ram (+ enemy-x-base slot) (bytes/low-u16 result)))

(defn initialize-actor!
  "Initialize the stream-visible actor state required at deterministic spawn time."
  [world slot]
  (def ram (world :ram))
  (def actor-id (get ram (+ enemy-id-base slot)))
  (put ram (+ enemy-state-base slot) 0)
  (when (<= actor-id actor-flying-cheep-cheep)
    (put ram (+ enemy-y-base slot)
         (bytes/u8 (+ (get ram (+ enemy-y-base slot)) 8)))
    (put ram (+ enemy-offscreen-base slot) 1))
  (case actor-id
    12 (do
         (put ram (+ enemy-y-high-base slot) 2)
         (put ram (+ enemy-y-base slot) 2))
    17 (when (not= (get ram enemy-frenzy-buffer-address) 0)
         (put ram (+ enemy-flag-base slot) 0))
    21 (do
         (put ram enemy-frenzy-buffer-address actor-bowser-flame)
         (when (= (get ram frenzy-timer-address) 0)
           (put ram frenzy-timer-address 1)
           (put-at-right-extent! world slot
                                 (rom/read-cpu (world :rom) flame-y-table-address))))
    24 (do
         (put ram enemy-frenzy-buffer-address 0)
         (put ram (+ enemy-flag-base slot) 0))
    27 (do
         (put ram (+ enemy-y-base slot)
              (bytes/u8 (+ (get ram (+ enemy-y-base slot)) 4)))
         (add-x! ram slot 4))
    28 (do
         (put ram (+ enemy-y-base slot)
              (bytes/u8 (+ (get ram (+ enemy-y-base slot)) 4)))
         (add-x! ram slot 4))
    29 (do
         (put ram (+ enemy-y-base slot)
              (bytes/u8 (+ (get ram (+ enemy-y-base slot)) 4)))
         (add-x! ram slot 4))
    30 (do
         (put ram (+ enemy-y-base slot)
              (bytes/u8 (+ (get ram (+ enemy-y-base slot)) 4)))
         (add-x! ram slot 4))
    31 (do
         (put ram (+ enemy-y-base slot)
              (bytes/u8 (+ (get ram (+ enemy-y-base slot)) 4)))
         (add-x! ram slot 4))
    36 (do
         (put ram (+ enemy-y-base slot)
              (bytes/u8 (- (get ram (+ enemy-y-base slot)) 2)))
         (when (not= (get ram area/secondary-hard-mode-address) 0)
           (add-x! ram slot 8)))
    38 (add-x! ram slot 12)
    39 (add-x! ram slot 12)
    43 (add-x! ram slot 12)
    44 (add-x! ram slot 12)
    53 (put ram (+ enemy-y-base slot) 0xb8)
    nil)
  world)

(defn- fallback-actor!
  [world slot]
  (def ram (world :ram))
  (var actor-id (get ram enemy-frenzy-buffer-address))
  (if (and (= actor-id 0) (not= (get ram vine-flag-offset-address) 1))
    nil
    (do
      (when (= actor-id 0)
        (set actor-id actor-vine))
      (put ram (+ enemy-id-base slot) actor-id)
      (initialize-actor! world slot))))

(defn- handle-group!
  [world group-id]
  (def ram (world :ram))
  (def data (- group-id 0x37))
  (def actor-id
    (if (not= (band data 4) 0)
      0
      (if (not= (get ram area/primary-hard-mode-address) 0)
        actor-buzzy-beetle
        actor-goomba)))
  (var remaining (if (not= (band data 1) 0) 3 2))
  (put ram group-count-address remaining)
  (var x (get ram scroll/screen-right-x-address))
  (var page (get ram scroll/screen-right-page-address))
  (var full false)
  (while (and (> remaining 0) (not full))
    (var slot 0)
    (while (and (< slot 5) (not= (get ram (+ enemy-flag-base slot)) 0))
      (++ slot))
    (if (= slot 5)
      (set full true)
      (do
        (put ram (+ enemy-id-base slot) actor-id)
        (put ram (+ enemy-page-base slot) page)
        (put ram (+ enemy-x-base slot) x)
        (put ram (+ enemy-y-base slot) (if (not= (band data 2) 0) 0x70 0xb0))
        (put ram (+ enemy-y-high-base slot) 1)
        (put ram (+ enemy-flag-base slot) 1)
        (initialize-actor! world slot)
        (when (>= x 0xe8) (set page (bytes/u8 (inc page))))
        (set x (bytes/u8 (+ x 0x18)))
        (-- remaining)
        (put ram group-count-address remaining))))
  (put ram area/enemy-data-offset-address
       (bytes/u8 (+ (get ram area/enemy-data-offset-address) 2)))
  (put ram area/enemy-object-page-select-address 0)
  world)

(defn- skip-entry!
  [world]
  (def ram (world :ram))
  (def offset (get ram area/enemy-data-offset-address))
  (when (= (band (area/enemy-byte world offset) 0x0f) 0x0e)
    (put ram area/enemy-data-offset-address (bytes/u8 (inc offset))))
  (put ram area/enemy-data-offset-address
       (bytes/u8 (+ (get ram area/enemy-data-offset-address) 2)))
  (put ram area/enemy-object-page-select-address 0))

(defn- kill-all!
  [ram]
  (loop [slot :range [0 5]]
    (put ram (+ enemy-flag-base slot) 0)
    (put ram (+ enemy-id-base slot) 0)
    (put ram (+ enemy-state-base slot) 0))
  (put ram enemy-frenzy-buffer-address 0))

(defn- execute-loopback!
  [world index]
  (def ram (world :ram))
  (put ram movement/page-base
       (bytes/u8 (- (get ram movement/page-base) 4)))
  (put ram area/current-page-address
       (bytes/u8 (- (get ram area/current-page-address) 4)))
  (put ram scroll/screen-left-page-address
       (bytes/u8 (- (get ram scroll/screen-left-page-address) 4)))
  (put ram scroll/screen-right-page-address
       (bytes/u8 (- (get ram scroll/screen-right-page-address) 4)))
  (put ram area/area-object-page-address
       (bytes/u8 (- (get ram area/area-object-page-address) 4)))
  (put ram area/enemy-object-page-select-address 0)
  (put ram area/area-object-page-select-address 0)
  (put ram area/enemy-data-offset-address 0)
  (put ram area/enemy-object-page-address 0)
  (put ram area/area-data-offset-address
       (rom/read-cpu (world :rom) (+ loopback-offsets-address index)))
  (kill-all! ram))

(defn handle-loop-command!
  "Resolve a pending SMB1 maze loop command at a page boundary."
  [world]
  (def ram (world :ram))
  (when (and (not= (get ram area/loop-command-address) 0)
             (= (get ram area/current-column-address) 0))
    (def image (world :rom))
    (var index 10)
    (var match-index nil)
    (while (and (>= index 0) (nil? match-index))
      (when (and (= (get ram area/world-number-address)
                    (rom/read-cpu image (+ loop-worlds-address index)))
                 (= (get ram area/current-page-address)
                    (rom/read-cpu image (+ loop-pages-address index))))
        (set match-index index))
      (-- index))
    (when match-index
      (def correct
        (and (= (get ram movement/y-position-base)
                (rom/read-cpu image (+ loop-y-address match-index)))
             (= (get ram player-state-address) 0)))
      (when correct
        (put ram multi-loop-correct-address
             (bytes/u8 (inc (get ram multi-loop-correct-address)))))
      (if (not= (get ram area/world-number-address) 6)
        (do
          (unless correct
            (execute-loopback! world match-index))
          (put ram multi-loop-pass-address 0)
          (put ram multi-loop-correct-address 0))
        (do
          (put ram multi-loop-pass-address
               (bytes/u8 (inc (get ram multi-loop-pass-address))))
          (when (= (get ram multi-loop-pass-address) 3)
            (when (not= (get ram multi-loop-correct-address) 3)
              (execute-loopback! world match-index))
            (put ram multi-loop-pass-address 0)
            (put ram multi-loop-correct-address 0))))
      (put ram area/loop-command-address 0)))
  world)

(defn- process-candidate!
  [world slot offset data-zero data-one screen-x extent-x extent-page]
  (def ram (world :ram))
  (put ram (+ enemy-page-base slot) (get ram area/enemy-object-page-address))
  (def actor-x (band data-zero 0xf0))
  (put ram (+ enemy-x-base slot) actor-x)
  (def actor-page (get ram (+ enemy-page-base slot)))
  (def screen-page (get ram scroll/screen-right-page-address))
  (def visible
    (or (and (<= screen-x actor-x) (<= screen-page actor-page))
        (and (> screen-x actor-x) (< screen-page actor-page))))
  (if visible
    (do
      (def crossed (< (band extent-x 0xf0) actor-x))
      (if (and (or crossed (< extent-page actor-page))
               (or (not crossed) (<= extent-page actor-page)))
        (fallback-actor! world slot)
        (do
          (put ram (+ enemy-y-high-base slot) 1)
          (def y-nibble (band data-zero 0x0f))
          (put ram (+ enemy-y-base slot) (blshift y-nibble 4))
          (cond
            (= y-nibble 0x0e)
            (do
              (when (= (brshift (area/enemy-byte world
                                                 (bytes/u8 (+ offset 2))) 5)
                       (get ram area/world-number-address))
                (put ram area/area-pointer-address data-one)
                (put ram area/entrance-page-address
                     (band (area/enemy-byte world
                                            (bytes/u8 (+ offset 2))) 0x1f)))
              (put ram area/enemy-data-offset-address
                   (bytes/u8 (+ offset 3)))
              (put ram area/enemy-object-page-select-address 0))
            (and (not= (band data-one 0x40) 0)
                 (= (get ram area/secondary-hard-mode-address) 0))
            (do
              (put ram area/enemy-data-offset-address
                   (bytes/u8 (+ offset 2)))
              (put ram area/enemy-object-page-select-address 0))
            true
            (do
              (var actor-id (band data-one 0x3f))
              (if (and (>= actor-id 0x37) (<= actor-id 0x3e))
                (handle-group! world actor-id)
                (do
                  (when (and (= actor-id actor-goomba)
                             (not= (get ram area/primary-hard-mode-address) 0))
                    (set actor-id actor-buzzy-beetle))
                  (put ram (+ enemy-id-base slot) actor-id)
                  (put ram (+ enemy-flag-base slot) 1)
                  (initialize-actor! world slot)
                  (when (not= (get ram (+ enemy-flag-base slot)) 0)
                    (put ram area/enemy-data-offset-address
                         (bytes/u8 (+ offset 2)))
                    (put ram area/enemy-object-page-select-address 0)))))))))
    (when (not= (band data-zero 0x0f) 0x0e)
      (skip-entry! world))))

(defn process-stream!
  "Process the SMB1 enemy stream for one actor slot at the current right screen edge."
  [world slot]
  (unless (and (int? slot) (>= slot 0) (< slot 6))
    (error (string "enemy slot out of range: " slot)))
  (def ram (world :ram))
  (handle-loop-command! world)
  (var scanning true)
  (while scanning
    (set scanning false)
    (def offset (get ram area/enemy-data-offset-address))
    (def queued (get ram enemy-frenzy-queue-address))
    (cond
      (not= queued 0)
      (do
        (put ram (+ enemy-id-base slot) queued)
        (put ram (+ enemy-flag-base slot) 1)
        (put ram (+ enemy-state-base slot) 0)
        (put ram enemy-frenzy-queue-address 0)
        (initialize-actor! world slot))
      (= (area/enemy-byte world offset) 0xff)
      (fallback-actor! world slot)
      true
      (do
        (def data-zero (area/enemy-byte world offset))
        (def data-one (area/enemy-byte world (bytes/u8 (inc offset))))
        (unless (and (not= (band data-zero 0x0f) 0x0e)
                     (>= slot 5)
                     (not= (band data-one 0x3f) 0x2e))
          (def screen-x (get ram scroll/screen-right-x-address))
          (def extent-x (bytes/u8 (+ screen-x 0x30)))
          (def extent-page
            (bytes/u8 (+ (get ram scroll/screen-right-page-address)
                         (if (>= screen-x 0xd0) 1 0))))
          (when (and (not= (band data-one 0x80) 0)
                     (= (get ram area/enemy-object-page-select-address) 0))
            (put ram area/enemy-object-page-select-address 1)
            (put ram area/enemy-object-page-address
                 (bytes/u8 (inc (get ram area/enemy-object-page-address)))))
          (if (and (= (band data-zero 0x0f) 0x0f)
                   (= (get ram area/enemy-object-page-select-address) 0))
            (do
              (put ram area/enemy-object-page-address (band data-one 0x3f))
              (put ram area/enemy-data-offset-address (bytes/u8 (+ offset 2)))
              (put ram area/enemy-object-page-select-address 1)
              (set scanning true))
            (process-candidate! world slot offset data-zero data-one
                                screen-x extent-x extent-page))))))
  world)

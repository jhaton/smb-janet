(import ./actors)
(import ./area)
(import ./bytes)
(import ./enemies)
(import ./input)
(import ./modes)
(import ./movement)
(import ./objects)
(import ./player)
(import ./scroll)
(import ./startup)

(def addr-victory-destination-page 0x0034)
(def addr-victory-walk-control 0x0035)
(def addr-event-music 0x00fc)
(def addr-square2-sound 0x00fe)
(def addr-noise-sound 0x00fd)
(def addr-vram-buffer-offset 0x0300)
(def addr-bowser-body-controls 0x0363)
(def addr-bowser-feet-counter 0x0364)
(def addr-bowser-front-offset 0x0368)
(def addr-bridge-collapse-offset 0x0369)
(def addr-primary-message-counter 0x0719)
(def addr-secondary-message-counter 0x0749)
(def addr-current-player 0x0753)
(def addr-fetch-new-game-timer 0x0757)
(def addr-level-number 0x075c)
(def addr-world-number 0x075f)
(def addr-area-number 0x0760)
(def addr-scroll-fractional 0x0768)
(def addr-vram-address-control 0x0773)
(def addr-world-end-timer 0x07a1)

(def bridge-x @[26 24 24 22 20 18 16 14 12 10 8 6 4 2 0])
(def bridge-y @[0 2 4 4 4 4 4 4 4 4 4 4 4 4 4])

(defn- slot-read
  [ram base slot]
  (get ram (+ base slot)))

(defn- slot-write!
  [ram base slot value]
  (put ram (+ base slot) (bytes/u8 value)))

(defn- remove-bridge-metatile!
  [ram collapse-offset]
  (def x (get bridge-x collapse-offset))
  (def y (+ 8 (div (get bridge-y collapse-offset) 2)))
  (def address (+ 0x2000 (* y 64) x))
  (def offset (inc (get ram addr-vram-buffer-offset)))
  (put ram (+ 0x0300 offset) (bytes/high-u16 address))
  (put ram (+ 0x0301 offset) (bytes/low-u16 address))
  (put ram (+ 0x0302 offset) 2)
  (put ram (+ 0x0303 offset) 0x24)
  (put ram (+ 0x0304 offset) 0x24)
  (put ram (+ 0x0305 offset) (bytes/high-u16 address))
  (put ram (+ 0x0306 offset) (+ (bytes/low-u16 address) 32))
  (put ram (+ 0x0307 offset) 2)
  (put ram (+ 0x0308 offset) 0x24)
  (put ram (+ 0x0309 offset) 0x24)
  (put ram (+ 0x030a offset) 0)
  (put ram addr-vram-buffer-offset
       (bytes/u8 (+ (get ram addr-vram-buffer-offset) 10))))

(defn- kill-normal-actors!
  [world]
  (loop [slot :range [0 5]]
    (actors/erase! world slot)))

(defn- enemy-core-zero!
  [world]
  (def ram (world :ram))
  (def flag (slot-read ram actors/addr-enemy-flag 0))
  (cond
    (not= (band flag 0x80) 0)
    (when (zero? (slot-read ram actors/addr-enemy-flag (band flag 0x0f)))
      (slot-write! ram actors/addr-enemy-flag 0 0))
    (not= flag 0)
    (objects/actor-slot! world 0)
    (not= (band (get ram 0x071f) 7) 7)
    (enemies/process-stream! world 0))
  world)

(defn- finish!
  [world]
  (def ram (world :ram))
  (unless (= (get ram modes/oper-mode-task-address)
             modes/victory-bridge-collapse)
    (enemy-core-zero! world))
  (player/presentation-position! world)
  (player/graphics-step! world)
  world)

(defn bridge-collapse!
  [world]
  (def ram (world :ram))
  (def slot (get ram addr-bowser-front-offset))
  (var collapsing false)
  (when (= (slot-read ram actors/addr-enemy-id slot) actors/actor-bowser)
    (def state (slot-read ram actors/addr-enemy-state slot))
    (cond
      (zero? state)
      (do
        (set collapsing true)
        (def feet (bytes/u8 (dec (get ram addr-bowser-feet-counter))))
        (put ram addr-bowser-feet-counter feet)
        (when (zero? feet)
          (put ram addr-bowser-feet-counter 4)
          (put ram addr-bowser-body-controls
               (bxor (get ram addr-bowser-body-controls) 1))
          (def collapse-offset (get ram addr-bridge-collapse-offset))
          (remove-bridge-metatile! ram collapse-offset)
          (put ram addr-square2-sound 8)
          (put ram addr-noise-sound 1)
          (put ram addr-bridge-collapse-offset (inc collapse-offset))
          (when (= (inc collapse-offset) 0x0f)
            (slot-write! ram actors/addr-enemy-y-speed slot 0)
            (slot-write! ram actors/addr-enemy-y-force slot 0)
            (slot-write! ram actors/addr-enemy-state slot 0x40)
            (put ram addr-square2-sound 0x80)))
        (objects/bowser-presentation! world slot))
      (and (not= (band state 0x40) 0)
           (< (slot-read ram actors/addr-enemy-y slot) 0xe0))
      (do
        (set collapsing true)
        (movement/impose-gravity! ram false (inc slot) 0x0f 0 2))))
  (unless collapsing
    (put ram addr-event-music 0x80)
    (put ram modes/oper-mode-task-address modes/victory-setup)
    (kill-normal-actors! world))
  (finish! world))

(defn setup!
  [world]
  (def ram (world :ram))
  (put ram addr-victory-destination-page
       (bytes/u8 (inc (get ram scroll/screen-right-page-address))))
  (put ram addr-event-music 8)
  (put ram modes/oper-mode-task-address modes/victory-player-walk)
  (finish! world))

(defn player-walk!
  [world]
  (def ram (world :ram))
  (def destination (get ram addr-victory-destination-page))
  (def arrived
    (and (= (get ram player/addr-player-page) destination)
         (>= (get ram player/addr-player-x) 0x60)))
  (put ram addr-victory-walk-control (if arrived 0 1))
  (player/auto-control-player! world (if arrived 0 input/button-right))
  (when (not= (get ram scroll/screen-left-page-address) destination)
    (def old-fraction (get ram addr-scroll-fractional))
    (put ram addr-scroll-fractional (bytes/u8 (+ old-fraction 0x80)))
    (scroll/scroll-screen! ram (if (>= old-fraction 0x80) 2 1))
    (startup/update-scroll-parser! world)
    (put ram addr-victory-walk-control
         (inc (get ram addr-victory-walk-control))))
  (when (zero? (get ram addr-victory-walk-control))
    (put ram modes/oper-mode-task-address modes/victory-print-messages))
  (finish! world))

(defn print-messages!
  [world]
  (def ram (world :ram))
  (def primary (get ram addr-primary-message-counter))
  (def secondary (get ram addr-secondary-message-counter))
  (var increment-counter true)
  (when (zero? secondary)
    (cond
      (zero? primary)
      (put ram addr-vram-address-control
           (if (zero? (get ram addr-current-player)) 12 13))
      (< primary 9)
      (if (not= (get ram addr-world-number) 7)
        (do
          (when (= primary 2)
            (put ram addr-vram-address-control 14))
          (when (>= primary 4)
            (set increment-counter false)))
        (when (>= primary 3)
          (when (= primary 3)
            (put ram addr-event-music 4))
          (put ram addr-vram-address-control (+ 12 primary))))))
  (var continue-messages false)
  (when increment-counter
    (def counter (+ (* primary 0x100) secondary 4))
    (put ram addr-primary-message-counter (band (brshift counter 8) 0xff))
    (put ram addr-secondary-message-counter (band counter 0xff))
    (set continue-messages
         (<= (get ram addr-primary-message-counter) 6)))
  (unless continue-messages
    (put ram addr-world-end-timer 6)
    (put ram modes/oper-mode-task-address modes/victory-player-end-world))
  (finish! world))

(defn player-end-world!
  [world]
  (def ram (world :ram))
  (when (and (zero? (get ram addr-world-end-timer))
             (< (get ram addr-world-number) 7))
    (put ram addr-area-number 0)
    (put ram addr-level-number 0)
    (put ram addr-world-number (inc (get ram addr-world-number)))
    (area/load-pointer! world)
    (put ram addr-fetch-new-game-timer
         (inc (get ram addr-fetch-new-game-timer)))
    (put ram modes/oper-mode-address modes/game)
    (put ram modes/oper-mode-task-address modes/game-initialize-area))
  (finish! world))

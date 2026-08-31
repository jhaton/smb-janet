(import ./bytes)
(import ./movement)
(import ./rom)
(import ./player)

(def slot-count 6)

(def addr-frame-counter 0x0009)
(def addr-enemy-flag 0x000f)
(def addr-enemy-id 0x0016)
(def addr-enemy-state 0x001e)
(def addr-fireball-state 0x0024)
(def addr-power-up-type 0x0039)
(def addr-hammer-jump-timer 0x003c)
(def addr-enemy-moving-dir 0x0046)
(def addr-enemy-x-speed 0x0058)
(def addr-enemy-page 0x006e)
(def addr-enemy-x 0x0087)
(def addr-enemy-y-speed 0x00a0)
(def addr-enemy-y-high 0x00b6)
(def addr-enemy-y 0x00cf)
(def addr-floatey-control 0x0110)
(def addr-floatey-x 0x0117)
(def addr-floatey-y 0x011e)
(def addr-shell-chain 0x0125)
(def addr-floatey-timer 0x012c)
(def addr-bowser-body-controls 0x0363)
(def addr-bowser-feet-counter 0x0364)
(def addr-bowser-movement-speed 0x0365)
(def addr-bowser-origin-x 0x0366)
(def addr-bowser-front-offset 0x0368)
(def addr-bridge-collapse-offset 0x0369)
(def addr-firebar-spin-speed 0x0388)
(def addr-vine-flag-offset 0x0398)
(def addr-vine-height 0x0399)
(def addr-vine-object-offset 0x039a)
(def addr-vine-start-y 0x039d)
(def addr-balance-platform-alignment 0x03a0)
(def addr-platform-collision 0x03a2)
(def addr-enemy-relative-x 0x03ae)
(def addr-enemy-relative-y 0x03b9)
(def addr-enemy-attribute 0x03c5)
(def addr-enemy-offscreen-masked 0x03d8)
(def addr-enemy-x-force 0x0401)
(def addr-red-paratroopa-origin 0x0401)
(def addr-enemy-y-fraction 0x0417)
(def addr-enemy-y-force 0x0434)
(def addr-bowser-hit-points 0x0483)
(def addr-enemy-collision-bits 0x0491)
(def addr-enemy-bbox-control 0x049a)
(def addr-enemy-frenzy-buffer 0x06cb)
(def addr-secondary-hard-mode 0x06cc)
(def addr-enemy-frenzy-queue 0x06cd)
(def addr-duplicate-object-offset 0x06cf)
(def addr-fireworks-counter 0x06d7)
(def addr-lakitu-reappear-timer 0x06d1)
(def addr-max-range-origin 0x06dc)
(def addr-bit-filter 0x06dd)
(def addr-timer-control 0x0747)
(def addr-background-color 0x0744)
(def addr-area-type 0x074e)
(def addr-player-status 0x0756)
(def addr-world-number 0x075f)
(def addr-primary-hard-mode 0x076a)
(def addr-enemy-frame-timer 0x078a)
(def addr-frenzy-enemy-timer 0x078f)
(def addr-bowser-fire-timer 0x0790)
(def addr-stomp-timer 0x0791)
(def addr-injury-timer 0x079e)
(def addr-star-timer 0x079f)
(def addr-random 0x07a7)
(def addr-square1-sound 0x00ff)
(def addr-square2-sound 0x00fe)
(def addr-noise-sound 0x00fd)
(def addr-area-music 0x00fb)
(def addr-event-music 0x00fc)
(def addr-vram-buffer-offset 0x0300)

(def actor-green-koopa 0)
(def actor-red-koopa-greenlike 1)
(def actor-buzzy-beetle 2)
(def actor-red-koopa 3)
(def actor-hammer-bro 5)
(def actor-goomba 6)
(def actor-bloober 7)
(def actor-bullet-bill 8)
(def actor-green-paratroopa-inplace 9)
(def actor-cheep-gray 10)
(def actor-cheep-red 11)
(def actor-podoboo 12)
(def actor-piranha 13)
(def actor-green-paratroopa 14)
(def actor-red-paratroopa 15)
(def actor-green-paratroopa-horizontal 16)
(def actor-lakitu 17)
(def actor-spiny 18)
(def actor-flying-cheep 20)
(def actor-bowser-flame 21)
(def actor-fireworks 22)
(def actor-bullet-cheep-frenzy 23)
(def actor-stop-frenzy 24)
(def actor-firebar-one 27)
(def actor-firebar-five 31)
(def actor-large-platform-balance 36)
(def actor-large-platform-y 37)
(def actor-large-lift-up 38)
(def actor-large-lift-down 39)
(def actor-large-platform-x 40)
(def actor-large-platform-drop 41)
(def actor-large-platform-right 42)
(def actor-small-lift-up 43)
(def actor-small-lift-down 44)
(def actor-bowser 45)
(def actor-power-up 46)
(def actor-vine 47)
(def actor-flagpole 48)
(def actor-star-flag 49)
(def actor-jumpspring 50)
(def actor-cannon-bullet 51)
(def actor-warp-zone 52)
(def actor-retainer 53)
(def fireworks-x-offsets [0x00 0x30 0x60 0x60 0x00 0x20])
(def fireworks-y-positions [0x60 0x40 0x70 0x40 0x60 0x30])

(defn- read8 [ram address] (get ram address))
(defn- write8! [ram address value] (put ram address (bytes/u8 value)))
(defn- slot-read [ram base slot] (read8 ram (+ base slot)))
(defn- slot-write! [ram base slot value] (write8! ram (+ base slot) value))

(defn actor-enemy? [id] (<= id actor-flying-cheep))
(defn actor-large-platform? [id]
  (and (>= id actor-large-platform-balance) (<= id actor-large-platform-right)))
(defn actor-firebar? [id] (and (>= id actor-firebar-one) (<= id 34)))

(defn- add-position!
  [ram page-base x-base slot amount]
  (def result
    (bytes/add-u16 (slot-read ram page-base slot)
                   (slot-read ram x-base slot)
                   (if (< amount 0) -1 0)
                   (bytes/u8 amount)))
  (slot-write! ram page-base slot (bytes/high-u16 result))
  (slot-write! ram x-base slot (bytes/low-u16 result)))

(defn- player-enemy-diff
  [ram slot]
  (def player-position
    (bytes/pack-u16 (read8 ram player/addr-player-page)
                    (read8 ram player/addr-player-x)))
  (def enemy-position
    (bytes/pack-u16 (slot-read ram addr-enemy-page slot)
                    (slot-read ram addr-enemy-x slot)))
  (def difference (- enemy-position player-position))
  @{:negative (< difference 0)
    :carry (<= player-position enemy-position)
    :low (bytes/u8 difference)})

(defn- initialize-vertical!
  [ram slot]
  (slot-write! ram addr-enemy-y-speed slot 0)
  (slot-write! ram addr-enemy-y-force slot 0))

(defn- initialize-small-box!
  [ram slot]
  (slot-write! ram addr-enemy-bbox-control slot 9)
  (slot-write! ram addr-enemy-moving-dir slot 2)
  (initialize-vertical! ram slot))

(defn- initialize-normal!
  [ram slot]
  (slot-write! ram addr-enemy-x-speed slot
               (if (zero? (read8 ram addr-primary-hard-mode)) 0xf8 0xf4))
  (slot-write! ram addr-enemy-bbox-control slot 3)
  (slot-write! ram addr-enemy-moving-dir slot 2)
  (initialize-vertical! ram slot))

(defn erase!
  [world slot]
  (def ram (world :ram))
  (slot-write! ram addr-enemy-flag slot 0)
  (slot-write! ram addr-enemy-id slot actor-green-koopa)
  (slot-write! ram addr-enemy-state slot 0)
  (slot-write! ram addr-floatey-control slot 0)
  (slot-write! ram 0x0796 slot 0)
  (slot-write! ram addr-shell-chain slot 0)
  (slot-write! ram addr-enemy-attribute slot 0)
  (slot-write! ram addr-enemy-frame-timer slot 0)
  world)

(defn- setup-lakitu!
  [ram slot]
  (write8! ram addr-lakitu-reappear-timer 0)
  (slot-write! ram addr-enemy-x-speed slot 0)
  (slot-write! ram addr-enemy-bbox-control slot 3)
  (slot-write! ram addr-enemy-moving-dir slot 2)
  (initialize-vertical! ram slot))

(defn- put-at-right-extent!
  [ram slot y]
  (def screen-x (read8 ram 0x071d))
  (slot-write! ram addr-enemy-y slot y)
  (slot-write! ram addr-enemy-x slot (+ screen-x 0x20))
  (slot-write! ram addr-enemy-page slot
               (+ (read8 ram 0x071b) (if (>= screen-x 0xe0) 1 0)))
  (slot-write! ram addr-enemy-bbox-control slot 8)
  (slot-write! ram addr-enemy-y-high slot 1)
  (slot-write! ram addr-enemy-flag slot 1)
  (slot-write! ram addr-enemy-x-force slot 0)
  (slot-write! ram addr-enemy-state slot 0))

(defn- initialize-spiny!
  [ram slot]
  (write8! ram addr-enemy-frenzy-buffer actor-spiny)
  (when (zero? (read8 ram addr-frenzy-enemy-timer))
    (write8! ram addr-frenzy-enemy-timer 0x80)
    (var found false)
    (var i 4)
    (while (and (>= i 0) (not found))
      (when (= (slot-read ram addr-enemy-id i) actor-lakitu)
        (set found true)
        (when (and (>= (read8 ram player/addr-player-y) 0x2c)
                   (zero? (slot-read ram addr-enemy-state i)))
          (slot-write! ram addr-enemy-page slot (slot-read ram addr-enemy-page i))
          (slot-write! ram addr-enemy-x slot (slot-read ram addr-enemy-x i))
          (slot-write! ram addr-enemy-y-high slot 1)
          (slot-write! ram addr-enemy-y slot (- (slot-read ram addr-enemy-y i) 8))
          (initialize-small-box! ram slot)
          (slot-write! ram addr-enemy-y-speed slot 0xfd)
          (slot-write! ram addr-enemy-flag slot 1)
          (slot-write! ram addr-enemy-state slot 5)))
      (-- i))
    (unless found
      (write8! ram addr-lakitu-reappear-timer
               (inc (read8 ram addr-lakitu-reappear-timer))))))

(def firebar-speed @[0x28 0x38 0x28 0x38 0x28])
(def firebar-direction @[0 0 0x10 0x10 0])

(defn- initialize-firebar!
  [ram slot id]
  (slot-write! ram addr-enemy-x-speed slot 0)
  (slot-write! ram addr-firebar-spin-speed slot
               (get firebar-speed (- id actor-firebar-one)))
  (slot-write! ram 0x0034 slot
               (get firebar-direction (- id actor-firebar-one)))
  (slot-write! ram addr-enemy-y slot (+ (slot-read ram addr-enemy-y slot) 4))
  (add-position! ram addr-enemy-page addr-enemy-x slot 4)
  (slot-write! ram addr-enemy-bbox-control slot 3))

(defn- position-platform!
  [ram slot index]
  (add-position! ram addr-enemy-page addr-enemy-x slot
                 (get @[8 12 -8] index)))

(defn- platform-box!
  [ram slot]
  (slot-write! ram addr-enemy-bbox-control slot
               (if (and (not= (read8 ram addr-area-type) 3)
                        (zero? (read8 ram addr-secondary-hard-mode)))
                 6
                 5)))

(defn- initialize-drop-platform!
  [ram slot]
  (slot-write! ram addr-platform-collision slot 0xff)
  (initialize-vertical! ram slot)
  (platform-box! ram slot))

(defn- initialize-lift-up!
  [ram slot]
  (slot-write! ram addr-enemy-y-force slot 0x10)
  (slot-write! ram addr-enemy-y-speed slot 0xff)
  (position-platform! ram slot 1)
  (slot-write! ram addr-enemy-bbox-control slot 4))

(defn- duplicate!
  [ram slot]
  (var duplicate 0)
  (while (not (zero? (slot-read ram addr-enemy-flag duplicate)))
    (++ duplicate))
  (write8! ram addr-duplicate-object-offset duplicate)
  (slot-write! ram addr-enemy-flag duplicate (bor slot 0x80))
  (slot-write! ram addr-enemy-page duplicate (slot-read ram addr-enemy-page slot))
  (slot-write! ram addr-enemy-x duplicate (slot-read ram addr-enemy-x slot))
  (slot-write! ram addr-enemy-flag slot 1)
  (slot-write! ram addr-enemy-y-high duplicate 1)
  (slot-write! ram addr-enemy-y duplicate (slot-read ram addr-enemy-y slot)))

(defn- initialize-lift-down!
  [ram slot]
  (slot-write! ram addr-enemy-y-force slot 0xf0)
  (slot-write! ram addr-enemy-y-speed slot 0)
  (position-platform! ram slot 1)
  (slot-write! ram addr-enemy-bbox-control slot 4))

(defn initialize!
  [world slot]
  (def ram (world :ram))
  (def id (slot-read ram addr-enemy-id slot))
  (when (actor-enemy? id)
    (slot-write! ram addr-enemy-y slot (+ (slot-read ram addr-enemy-y slot) 8))
    (slot-write! ram addr-enemy-offscreen-masked slot 1))
  (case id
    0 (initialize-normal! ram slot)
    1 (initialize-normal! ram slot)
    2 (initialize-normal! ram slot)
    3 (do (initialize-normal! ram slot)
          (slot-write! ram addr-enemy-state slot 1))
    4 (initialize-normal! ram slot)
    5 (do
        (slot-write! ram addr-hammer-jump-timer slot 0)
        (slot-write! ram addr-enemy-x-speed slot 0)
        (slot-write! ram 0x0796 slot
                     (if (zero? (read8 ram addr-secondary-hard-mode)) 0x80 0x50))
        (slot-write! ram addr-enemy-bbox-control slot 0x0b)
        (slot-write! ram addr-enemy-moving-dir slot 2)
        (initialize-vertical! ram slot))
    6 (do (initialize-normal! ram slot) (initialize-small-box! ram slot))
    7 (do (slot-write! ram addr-enemy-x-speed slot 0)
          (initialize-small-box! ram slot))
    8 (do (slot-write! ram addr-enemy-moving-dir slot 2)
          (slot-write! ram addr-enemy-bbox-control slot 9))
    9 nil
    10 (do (initialize-small-box! ram slot)
           (slot-write! ram addr-enemy-x-speed slot
                        (band (slot-read ram addr-random slot) 0x10))
           (slot-write! ram addr-enemy-y-force slot
                        (slot-read ram addr-enemy-y slot)))
    11 (do (initialize-small-box! ram slot)
           (slot-write! ram addr-enemy-x-speed slot
                        (band (slot-read ram addr-random slot) 0x10))
           (slot-write! ram addr-enemy-y-force slot
                        (slot-read ram addr-enemy-y slot)))
    12 (do
         (slot-write! ram addr-enemy-y-high slot 2)
         (slot-write! ram addr-enemy-y slot 2)
         (slot-write! ram 0x0796 slot 1)
         (slot-write! ram addr-enemy-state slot 0)
         (initialize-small-box! ram slot))
    13 (do
         (slot-write! ram addr-enemy-x-speed slot 1)
         (slot-write! ram addr-enemy-state slot 0)
         (slot-write! ram addr-enemy-y-speed slot 0)
         (slot-write! ram addr-enemy-y-force slot (slot-read ram addr-enemy-y slot))
         (slot-write! ram addr-enemy-y-fraction slot
                      (- (slot-read ram addr-enemy-y slot) 0x18))
         (slot-write! ram addr-enemy-bbox-control slot 9))
    14 (do
         (slot-write! ram addr-enemy-moving-dir slot 2)
         (slot-write! ram addr-enemy-x-speed slot 0xf8)
         (slot-write! ram addr-enemy-bbox-control slot 3))
    15 (do
         (slot-write! ram addr-red-paratroopa-origin slot
                      (slot-read ram addr-enemy-y slot))
         (slot-write! ram addr-enemy-x-speed slot
                      (+ (slot-read ram addr-enemy-y slot)
                         (if (>= (slot-read ram addr-enemy-y slot) 0x80)
                           -0x20 0x30)))
         (slot-write! ram addr-enemy-bbox-control slot 3)
         (slot-write! ram addr-enemy-moving-dir slot 2)
         (initialize-vertical! ram slot))
    16 (do (slot-write! ram addr-enemy-x-speed slot 0)
           (slot-write! ram addr-enemy-bbox-control slot 3)
           (slot-write! ram addr-enemy-moving-dir slot 2)
           (initialize-vertical! ram slot))
    17 (if (zero? (read8 ram addr-enemy-frenzy-buffer))
         (setup-lakitu! ram slot)
         (erase! world slot))
    18 (initialize-spiny! ram slot)
    19 nil
    20 (do
         (write8! ram addr-enemy-frenzy-buffer actor-flying-cheep)
         (when (zero? (read8 ram addr-frenzy-enemy-timer))
           (initialize-small-box! ram slot)
           (write8! ram addr-frenzy-enemy-timer
                    (get @[0x10 0x60 0x20 0x48]
                         (band (slot-read ram addr-random (inc slot)) 3)))
           (when (< slot (if (zero? (read8 ram addr-secondary-hard-mode)) 3 4))
             (slot-write! ram addr-enemy-y-speed slot 0xfb)
             (slot-write! ram addr-enemy-x-speed slot
                          (get @[0x0e 0x05 0x06 0x0e]
                               (band (slot-read ram addr-random slot) 3)))
             (slot-write! ram addr-enemy-moving-dir slot 1)
             (slot-write! ram addr-enemy-page slot
                          (read8 ram player/addr-player-page))
             (slot-write! ram addr-enemy-x slot
                          (read8 ram player/addr-player-x))
             (add-position! ram addr-enemy-page addr-enemy-x slot -0x80)
             (slot-write! ram addr-enemy-flag slot 1)
             (slot-write! ram addr-enemy-y-high slot 1)
             (slot-write! ram addr-enemy-y slot 0xf8))))
    21 (do
         (write8! ram addr-enemy-frenzy-buffer actor-bowser-flame)
         (when (zero? (read8 ram addr-frenzy-enemy-timer))
           (slot-write! ram addr-enemy-y-force slot 0)
           (def bowser-slot (read8 ram addr-bowser-front-offset))
           (write8! ram addr-noise-sound (bor (read8 ram addr-noise-sound) 2))
           (def random (band (slot-read ram addr-random slot) 3))
           (slot-write! ram addr-enemy-y-fraction slot random)
           (if (not= (slot-read ram addr-enemy-id bowser-slot) actor-bowser)
             (do
               (def control (read8 ram 0x0367))
               (def timer
                 (get @[0xbf 0x40 0xbf 0xbf 0xbf 0x40 0x40 0xbf] control))
               (write8! ram 0x0367 (band (inc control) 7))
               (write8! ram addr-frenzy-enemy-timer
                        (+ timer
                           (if (zero? (read8 ram addr-secondary-hard-mode))
                             0x20 0x10)))
               (put-at-right-extent!
                 ram slot
                 (rom/read-cpu (world :rom) (+ 0xc59d random))))
             (do
               (slot-write! ram addr-enemy-x slot
                            (- (slot-read ram addr-enemy-x bowser-slot) 0x0e))
               (slot-write! ram addr-enemy-page slot
                            (slot-read ram addr-enemy-page bowser-slot))
               (slot-write! ram addr-enemy-y slot
                            (+ (slot-read ram addr-enemy-y bowser-slot) 8))
               (slot-write! ram addr-enemy-y-force slot
                            (if (<= (slot-read ram addr-enemy-y slot)
                                    (rom/read-cpu (world :rom)
                                                  (+ 0xc59d random)))
                              1 0xff))
               (write8! ram addr-enemy-frenzy-buffer 0)
               (slot-write! ram addr-enemy-bbox-control slot 8)
               (slot-write! ram addr-enemy-y-high slot 1)
               (slot-write! ram addr-enemy-flag slot 1)
               (slot-write! ram addr-enemy-x-force slot 0)
               (slot-write! ram addr-enemy-state slot 0)))))
    22 (when (zero? (read8 ram addr-frenzy-enemy-timer))
         (write8! ram addr-frenzy-enemy-timer 0x20)
         (write8! ram addr-fireworks-counter
                  (dec (read8 ram addr-fireworks-counter)))
         (var star-slot 5)
         (while (and (>= star-slot 0)
                     (not= (slot-read ram addr-enemy-id star-slot)
                           actor-star-flag))
           (-- star-slot))
         (when (< star-slot 0)
           (error "fireworks require an active star-flag object"))
         (def index (+ (read8 ram addr-fireworks-counter)
                       (slot-read ram addr-enemy-state star-slot)))
         (def position
           (bytes/u16
             (+ (* (slot-read ram addr-enemy-page star-slot) 0x100)
                (slot-read ram addr-enemy-x star-slot)
                -0x30
                (get fireworks-x-offsets index))))
         (slot-write! ram addr-enemy-page slot (bytes/high-u16 position))
         (slot-write! ram addr-enemy-x slot (bytes/low-u16 position))
         (slot-write! ram addr-enemy-y slot
                      (get fireworks-y-positions index))
         (slot-write! ram addr-enemy-y-high slot 1)
         (slot-write! ram addr-enemy-flag slot 1)
         (slot-write! ram addr-enemy-x-speed slot 0)
         (slot-write! ram addr-enemy-y-speed slot 8))
    24 (do
         (for i 0 6
           (when (= (slot-read ram addr-enemy-id i) actor-lakitu)
             (slot-write! ram addr-enemy-state i 1)))
         (write8! ram addr-enemy-frenzy-buffer 0)
         (slot-write! ram addr-enemy-flag slot 0))
    27 (initialize-firebar! ram slot id)
    28 (initialize-firebar! ram slot id)
    29 (initialize-firebar! ram slot id)
    30 (initialize-firebar! ram slot id)
    31 (do (duplicate! ram slot) (initialize-firebar! ram slot id))
    36 (do
         (slot-write! ram addr-enemy-y slot (- (slot-read ram addr-enemy-y slot) 2))
         (when (zero? (read8 ram addr-secondary-hard-mode))
           (position-platform! ram slot 2))
         (slot-write! ram addr-enemy-state slot
                      (read8 ram addr-balance-platform-alignment))
         (write8! ram addr-balance-platform-alignment slot)
         (slot-write! ram addr-enemy-moving-dir slot 0)
         (position-platform! ram slot 0)
         (initialize-drop-platform! ram slot))
    37 (do
         (def y (bytes/i8 (slot-read ram addr-enemy-y slot)))
         (if (>= y 0)
           (do (slot-write! ram addr-red-paratroopa-origin slot y)
               (slot-write! ram addr-enemy-x-speed slot (+ y 0x40)))
           (do (slot-write! ram addr-red-paratroopa-origin slot (- y))
               (slot-write! ram addr-enemy-x-speed slot (+ y -0x40))))
         (initialize-vertical! ram slot)
         (platform-box! ram slot))
    38 (do (initialize-lift-up! ram slot) (platform-box! ram slot))
    39 (do (initialize-lift-down! ram slot) (platform-box! ram slot))
    40 (do (slot-write! ram addr-enemy-x-speed slot 0)
           (initialize-vertical! ram slot)
           (platform-box! ram slot))
    41 (initialize-drop-platform! ram slot)
    42 (do (slot-write! ram addr-enemy-x-speed slot 0)
           (initialize-vertical! ram slot)
           (platform-box! ram slot))
    43 (initialize-lift-up! ram slot)
    44 (initialize-lift-down! ram slot)
    45 (do
         (var duplicate 0)
         (while (not (zero? (slot-read ram addr-enemy-flag duplicate)))
           (++ duplicate))
         (write8! ram addr-duplicate-object-offset duplicate)
         (slot-write! ram addr-enemy-flag duplicate (bor slot 0x80))
         (slot-write! ram addr-enemy-page duplicate
                      (slot-read ram addr-enemy-page slot))
         (slot-write! ram addr-enemy-x duplicate (slot-read ram addr-enemy-x slot))
         (slot-write! ram addr-enemy-flag slot 1)
         (slot-write! ram addr-enemy-y-high duplicate 1)
         (slot-write! ram addr-enemy-y duplicate (slot-read ram addr-enemy-y slot))
         (write8! ram addr-bowser-body-controls 0)
         (write8! ram addr-bridge-collapse-offset 0)
         (write8! ram addr-bowser-origin-x (slot-read ram addr-enemy-x slot))
         (write8! ram addr-bowser-fire-timer 0xdf)
         (write8! ram addr-bowser-front-offset slot)
         (slot-write! ram addr-enemy-moving-dir slot 0xdf)
         (write8! ram addr-bowser-feet-counter 0x20)
         (slot-write! ram addr-enemy-frame-timer slot 0x20)
         (write8! ram 0x0483 5)
         (write8! ram addr-bowser-movement-speed 2))
    46 (do
         (slot-write! ram addr-enemy-state 5 1)
         (slot-write! ram addr-enemy-flag 5 1)
         (slot-write! ram addr-enemy-bbox-control 5 3)
         (slot-write! ram addr-enemy-attribute 5 0x20)
         (write8! ram addr-square2-sound 2))
    47 (do
         (slot-write! ram addr-enemy-id slot actor-vine)
         (slot-write! ram addr-enemy-flag slot 1)
         (slot-write! ram addr-enemy-page slot (read8 ram 0xe7))
         (slot-write! ram addr-enemy-x slot (read8 ram 0xef))
         (slot-write! ram addr-enemy-y slot (read8 ram 0x0136))
         (when (zero? (read8 ram addr-vine-flag-offset))
           (write8! ram addr-vine-start-y (slot-read ram addr-enemy-y slot)))
         (write8! ram (+ addr-vine-object-offset
                         (read8 ram addr-vine-flag-offset)) slot)
         (write8! ram addr-vine-flag-offset
                  (inc (read8 ram addr-vine-flag-offset)))
         (write8! ram addr-square2-sound 4))
    53 (slot-write! ram addr-enemy-y slot 0xb8)
    nil)
  world)

(defn- set-x-move!
  [ram slot maximum acceleration]
  (movement/impose-gravity! ram false (inc slot) acceleration 0 maximum))

(defn- move-down!
  [ram slot]
  (set-x-move! ram slot 3
               (if (= (slot-read ram addr-enemy-state slot) 5) 0x20 0x3d)))

(defn move-jumping!
  [ram slot]
  (set-x-move! ram slot 3 0x1c))

(defn- move-horizontal!
  [ram slot]
  (movement/move-object-horizontally! ram (inc slot)))

(defn- move-defeated!
  [ram slot]
  (move-down! ram slot)
  (move-horizontal! ram slot))

(defn move-normal!
  [world slot]
  (def ram (world :ram))
  (def state (slot-read ram addr-enemy-state slot))
  (var falling true)
  (when (zero? (band state 0x40))
    (def low (band state 7))
    (cond
      (not= (band state 0x80) 0) (set falling false)
      (not= (band state 0x20) 0) (do (move-defeated! ram slot) (set falling nil))
      (zero? low) (set falling false)
      (or (= low 3) (= low 4) (= low 6) (= low 7))
      (do
        (if (zero? (slot-read ram 0x0796 slot))
          (do
            (slot-write! ram addr-enemy-state slot 0)
            (def direction (band (read8 ram addr-frame-counter) 1))
            (slot-write! ram addr-enemy-moving-dir slot (inc direction))
            (slot-write! ram addr-enemy-x-speed slot
                         (if (zero? (read8 ram addr-primary-hard-mode))
                           (if (zero? direction) 8 0xf8)
                           (if (zero? direction) 12 0xf4))))
          (when (and (= (slot-read ram 0x0796 slot) 0x0e)
                     (= (slot-read ram addr-enemy-id slot) actor-goomba))
            (erase! world slot)))
        (set falling nil))))
  (when (not (nil? falling))
    (var adjust 0)
    (when falling
      (move-down! ram slot)
      (when (= (slot-read ram addr-enemy-state slot) 2)
        (move-horizontal! ram slot)
        (set adjust nil))
      (when (and (not (nil? adjust))
                 (not= (band (slot-read ram addr-enemy-state slot) 0x40) 0)
                 (not= (slot-read ram addr-enemy-id slot) actor-power-up))
        (set adjust 1)))
    (when (not (nil? adjust))
      (def speed (slot-read ram addr-enemy-x-speed slot))
      (when (= adjust 1)
        (slot-write! ram addr-enemy-x-speed slot
                     (+ speed (if (< speed 0x80) -24 24))))
      (move-horizontal! ram slot)
      (slot-write! ram addr-enemy-x-speed slot speed))))

(defn- move-hammer-x!
  [world slot]
  (def ram (world :ram))
  (slot-write! ram addr-enemy-x-speed slot
               (if (zero? (band (read8 ram addr-frame-counter) 0x40)) 4 0xfc))
  (def difference (player-enemy-diff ram slot))
  (when (and (not (difference :negative))
             (zero? (slot-read ram 0x0796 slot)))
    (slot-write! ram addr-enemy-x-speed slot 0xf8))
  (slot-write! ram addr-enemy-moving-dir slot
               (if (difference :negative) 1 2))
  (move-normal! world slot))

(defn- set-hammer-jump!
  [world slot speed high-jump]
  (def ram (world :ram))
  (slot-write! ram addr-enemy-y-speed slot speed)
  (slot-write! ram addr-enemy-state slot
               (bor (slot-read ram addr-enemy-state slot) 1))
  (slot-write! ram addr-enemy-frame-timer slot 0x20)
  (when (and high-jump (not= (read8 ram addr-secondary-hard-mode) 0)
             (not= (band (slot-read ram addr-random (+ slot 2)) 1) 0))
    (slot-write! ram addr-enemy-frame-timer slot 0x37))
  (slot-write! ram addr-hammer-jump-timer slot
               (bor (slot-read ram addr-random (inc slot)) 0xc0))
  (move-hammer-x! world slot))

(defn- move-hammer!
  [world slot]
  (def ram (world :ram))
  (cond
    (not= (band (slot-read ram addr-enemy-state slot) 0x20) 0)
    (move-defeated! ram slot)
    (not= (slot-read ram addr-hammer-jump-timer slot) 0)
    (do
      (slot-write! ram addr-hammer-jump-timer slot
                   (dec (slot-read ram addr-hammer-jump-timer slot)))
      (move-hammer-x! world slot))
    (= (band (slot-read ram addr-enemy-state slot) 7) 1)
    (move-hammer-x! world slot)
    (>= (slot-read ram addr-enemy-y slot) 0x80)
    (set-hammer-jump! world slot 0xfa false)
    (< (slot-read ram addr-enemy-y slot) 0x70)
    (set-hammer-jump! world slot 0xfd true)
    (not= (band (slot-read ram addr-random (inc slot)) 1) 0)
    (set-hammer-jump! world slot 0xfd false)
    true (set-hammer-jump! world slot 0xfa false)))

(defn- move-red-paratroopa!
  [ram slot]
  (def stationary
    (zero? (bor (slot-read ram addr-enemy-y-speed slot)
                (slot-read ram addr-enemy-y-force slot))))
  (when stationary
    (slot-write! ram addr-enemy-y-fraction slot 0))
  (if (and stationary
           (< (slot-read ram addr-enemy-y slot)
              (slot-read ram addr-red-paratroopa-origin slot)))
    (when (zero? (band (read8 ram addr-frame-counter) 7))
      (slot-write! ram addr-enemy-y slot
                   (inc (slot-read ram addr-enemy-y slot))))
    (if (<= (slot-read ram addr-enemy-x-speed slot)
            (slot-read ram addr-enemy-y slot))
      (movement/impose-gravity! ram true (inc slot) 3 6 2)
      (movement/impose-gravity! ram false (inc slot) 3 6 2))))

(defn- update-x-counter!
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

(defn- move-with-x-counters!
  [ram slot]
  (def amount (slot-read ram addr-enemy-x-speed slot))
  (if (not= (band (slot-read ram addr-enemy-y-speed slot) 2) 0)
    (slot-write! ram addr-enemy-moving-dir slot 1)
    (do
      (slot-write! ram addr-enemy-x-speed slot (- amount))
      (slot-write! ram addr-enemy-moving-dir slot 2)))
  (move-horizontal! ram slot)
  (slot-write! ram addr-enemy-x-speed slot amount))

(defn- move-horizontal-paratroopa!
  [ram slot]
  (update-x-counter! ram slot 0x13)
  (move-with-x-counters! ram slot)
  (when (zero? (band (read8 ram addr-frame-counter) 3))
    (slot-write! ram addr-enemy-y slot
                 (+ (slot-read ram addr-enemy-y slot)
                    (if (zero? (band (read8 ram addr-frame-counter) 0x40)) -1 1)))))

(defn- move-bloober!
  [ram slot]
  (if (not= (band (slot-read ram addr-enemy-state slot) 0x20) 0)
    (set-x-move! ram slot 2 0x0f)
    (do
      (def random
        (band (slot-read ram addr-random (inc slot))
              (if (zero? (read8 ram addr-secondary-hard-mode)) 0x3f 3)))
      (var direction-carry false)
      (when (zero? random)
        (if (not= (band slot 1) 0)
          (do
            (slot-write! ram addr-enemy-moving-dir slot
                         (read8 ram player/addr-player-moving))
            (set direction-carry true))
          (do
            (def difference (player-enemy-diff ram slot))
            (slot-write! ram addr-enemy-moving-dir slot
                         (if (difference :negative) 1 2))
            (set direction-carry (difference :carry)))))
      (def counter (slot-read ram addr-enemy-y-speed slot))
      (cond
        (zero? (band counter 2))
        (if (zero? (band counter 1))
          (when (zero? (band (read8 ram addr-frame-counter) 7))
            (def amount (inc (slot-read ram addr-enemy-y-force slot)))
            (slot-write! ram addr-enemy-y-force slot amount)
            (slot-write! ram addr-enemy-x-speed slot amount)
            (when (= amount 2)
              (slot-write! ram addr-enemy-y-speed slot (inc counter))))
          (when (zero? (band (read8 ram addr-frame-counter) 7))
            (def amount (dec (slot-read ram addr-enemy-y-force slot)))
            (slot-write! ram addr-enemy-y-force slot amount)
            (slot-write! ram addr-enemy-x-speed slot amount)
            (when (zero? amount)
              (slot-write! ram addr-enemy-y-speed slot (inc counter))
              (slot-write! ram 0x0796 slot 2))))
        (and (zero? (slot-read ram 0x0796 slot))
             (<= (read8 ram player/addr-player-y)
                 (bytes/u8 (+ (slot-read ram addr-enemy-y slot) 0x10
                              (if direction-carry 1 0)))))
        (slot-write! ram addr-enemy-y-speed slot 0)
        (zero? (band (read8 ram addr-frame-counter) 1))
        (slot-write! ram addr-enemy-y slot
                     (inc (slot-read ram addr-enemy-y slot))))
      (def y-difference
        (bytes/u8 (- (slot-read ram addr-enemy-y slot)
                     (slot-read ram addr-enemy-y-force slot))))
      (when (>= y-difference 0x20)
        (slot-write! ram addr-enemy-y slot y-difference))
      (add-position! ram addr-enemy-page addr-enemy-x slot
                     (if (= (slot-read ram addr-enemy-moving-dir slot) 1)
                       (slot-read ram addr-enemy-x-speed slot)
                       (- (slot-read ram addr-enemy-x-speed slot)))))))

(defn- move-cheep!
  [ram slot]
  (if (not= (band (slot-read ram addr-enemy-state slot) 0x20) 0)
    (set-x-move! ram slot 2 0x0f)
    (do
      (def x-position
        (bytes/u24 (- (bytes/pack-u24 (slot-read ram addr-enemy-page slot)
                                     (slot-read ram addr-enemy-x slot)
                                     (slot-read ram addr-enemy-x-force slot))
                       (if (= (slot-read ram addr-enemy-id slot) actor-cheep-gray)
                         0x40 0x80))))
      (slot-write! ram addr-enemy-page slot (bytes/high-u24 x-position))
      (slot-write! ram addr-enemy-x slot (bytes/middle-u24 x-position))
      (slot-write! ram addr-enemy-x-force slot (bytes/low-u24 x-position))
      (when (> slot 1)
        (def amount 0x20)
        (def y-position
          (bytes/u24
            ((if (< (slot-read ram addr-enemy-x-speed slot) 0x10) - +)
             (bytes/pack-u24 (slot-read ram addr-enemy-y-high slot)
                             (slot-read ram addr-enemy-y slot)
                             (slot-read ram addr-enemy-y-fraction slot))
             amount)))
        (slot-write! ram addr-enemy-y-high slot (bytes/high-u24 y-position))
        (slot-write! ram addr-enemy-y slot (bytes/middle-u24 y-position))
        (slot-write! ram addr-enemy-y-fraction slot (bytes/low-u24 y-position))
        (def difference
          (bytes/i8 (- (slot-read ram addr-enemy-y slot)
                       (slot-read ram addr-enemy-y-force slot))))
        (cond (> difference 14) (slot-write! ram addr-enemy-x-speed slot 0)
              (< difference -14) (slot-write! ram addr-enemy-x-speed slot 0x10))))))

(def flying-y-offsets @[-8 -96 112 -67 0 32 32 32 0 0 -75 30 41 32 -16 8])

(defn- move-flying-cheep!
  [ram slot]
  (if (not= (band (slot-read ram addr-enemy-state slot) 0x20) 0)
    (do
      (slot-write! ram addr-enemy-attribute slot 0)
      (move-jumping! ram slot))
    (do
      (move-horizontal! ram slot)
      (set-x-move! ram slot 5 0x0d)
      (var index (brshift (slot-read ram addr-enemy-y-force slot) 4))
      (var difference
        (bytes/u8 (- (slot-read ram addr-enemy-y slot)
                     (get flying-y-offsets index))))
      (when (>= difference 0x80) (set difference (bytes/u8 (- difference))))
      (when (< difference 8)
        (def force (slot-read ram addr-enemy-y-force slot))
        (slot-write! ram addr-enemy-y-force slot (+ force 0x10))
        (set index (brshift (bytes/u8 (+ force 0x10)) 4)))
      (slot-write! ram addr-enemy-attribute slot 0))))

(defn- lakitu-difference
  [ram slot near middle far]
  (def difference (player-enemy-diff ram slot))
  (var negative-offset (if (difference :negative) 1 0))
  (var distance (difference :low))
  (when (difference :negative) (set distance (bytes/u8 (- distance))))
  (when (>= distance 0x3c)
    (set distance 0x3c)
    (when (= (slot-read ram addr-enemy-id slot) actor-lakitu)
      (when (not= negative-offset (slot-read ram addr-enemy-y-speed slot))
        (when (not= (slot-read ram addr-enemy-y-speed slot) 0)
          (slot-write! ram addr-enemy-x-speed slot
                       (dec (slot-read ram addr-enemy-x-speed slot))))
        (when (zero? (slot-read ram addr-enemy-x-speed slot))
          (slot-write! ram addr-enemy-y-speed slot negative-offset)))))
  (def adjustment (inc (band (brshift distance 2) 0x0f)))
  (cond
    (or (zero? (read8 ram player/addr-player-x-speed))
        (zero? (read8 ram 0x0775))) (- near adjustment)
    (and (not= (slot-read ram addr-enemy-id slot) actor-spiny)
         (zero? (slot-read ram addr-enemy-y-speed slot))) (- near adjustment)
    (or (<= (read8 ram player/addr-player-x-speed) 0x18)
        (<= (read8 ram 0x0775) 1)) (- middle adjustment)
    true (- far adjustment)))

(defn- move-lakitu!
  [ram slot]
  (if (zero? (band (slot-read ram addr-enemy-state slot) 0x20))
    (do
      (if (zero? (slot-read ram addr-enemy-state slot))
        (do
          (write8! ram addr-enemy-frenzy-buffer actor-spiny)
          (slot-write! ram addr-enemy-x-speed slot
                       (lakitu-difference ram slot 21 48 64)))
        (do
          (slot-write! ram addr-enemy-y-speed slot 0)
          (write8! ram addr-enemy-frenzy-buffer 0)
          (slot-write! ram addr-enemy-x-speed slot 0x10)))
      (if (not= (band (slot-read ram addr-enemy-y-speed slot) 1) 0)
        (slot-write! ram addr-enemy-moving-dir slot 1)
        (do
          (slot-write! ram addr-enemy-x-speed slot
                       (- (slot-read ram addr-enemy-x-speed slot)))
          (slot-write! ram addr-enemy-moving-dir slot 2)))
      (move-horizontal! ram slot))
    (move-down! ram slot)))

(defn- move-piranha!
  [ram slot]
  (when (and (zero? (slot-read ram addr-enemy-state slot))
             (zero? (slot-read ram addr-enemy-frame-timer slot)))
    (var waiting false)
    (when (zero? (slot-read ram addr-enemy-y-speed slot))
      (when (< (slot-read ram addr-enemy-x-speed slot) 0x80)
        (def difference (player-enemy-diff ram slot))
        (def distance
          (if (difference :negative)
            (bytes/u8 (- (difference :low)))
            (difference :low)))
        (when (< distance 0x21)
          (set waiting true)))
      (unless waiting
        (slot-write! ram addr-enemy-x-speed slot
                     (- (slot-read ram addr-enemy-x-speed slot)))
        (slot-write! ram addr-enemy-y-speed slot 1)))
    (unless waiting
      (def target
        (if (>= (slot-read ram addr-enemy-x-speed slot) 0x80)
          (slot-read ram addr-enemy-y-fraction slot)
          (slot-read ram addr-enemy-y-force slot)))
      (when (and (zero? (read8 ram addr-timer-control))
                 (not= (band (read8 ram addr-frame-counter) 1) 0))
        (slot-write! ram addr-enemy-y slot
                     (+ (slot-read ram addr-enemy-y slot)
                        (bytes/i8 (slot-read ram addr-enemy-x-speed slot))))
        (when (= (slot-read ram addr-enemy-y slot) target)
          (slot-write! ram addr-enemy-y-speed slot 0)
          (slot-write! ram addr-enemy-frame-timer slot 0x40)))))
  (slot-write! ram addr-enemy-attribute slot 0x20))

(defn movement!
  [world slot]
  (def ram (world :ram))
  (case (slot-read ram addr-enemy-id slot)
    0 (move-normal! world slot)
    1 (move-normal! world slot)
    2 (move-normal! world slot)
    3 (move-normal! world slot)
    4 (move-normal! world slot)
    5 (move-hammer! world slot)
    6 (move-normal! world slot)
    7 (move-bloober! ram slot)
    8 (if (not= (band (slot-read ram addr-enemy-state slot) 0x20) 0)
        (move-jumping! ram slot)
        (do (slot-write! ram addr-enemy-x-speed slot 0xe8)
            (move-horizontal! ram slot)))
    9 nil
    10 (move-cheep! ram slot)
    11 (move-cheep! ram slot)
    12 (do
         (when (zero? (slot-read ram 0x0796 slot))
           (slot-write! ram addr-enemy-y-high slot 2)
           (slot-write! ram addr-enemy-y slot 2)
           (slot-write! ram 0x0796 slot 1)
           (slot-write! ram addr-enemy-state slot 0)
           (initialize-small-box! ram slot)
           (def random (slot-read ram addr-random (inc slot)))
           (slot-write! ram addr-enemy-y-force slot (bor random 0x80))
           (slot-write! ram 0x0796 slot (bor (band random 0x0f) 6))
           (slot-write! ram addr-enemy-y-speed slot 0xf9))
         (move-jumping! ram slot))
    13 (move-piranha! ram slot)
    14 (do (move-jumping! ram slot) (move-horizontal! ram slot))
    15 (move-red-paratroopa! ram slot)
    16 (move-horizontal-paratroopa! ram slot)
    17 (move-lakitu! ram slot)
    18 (move-normal! world slot)
    19 nil
    20 (move-flying-cheep! ram slot)
    nil)
  world)

(def addr-bounding-boxes 0x04ac)

(defn boxes-collide?
  [ram first second]
  (var colliding true)
  (loop [axis :range [0 2]
         :while colliding]
    (def first-top (read8 ram (+ addr-bounding-boxes first axis)))
    (def second-top (read8 ram (+ addr-bounding-boxes second axis)))
    (def first-bottom (read8 ram (+ addr-bounding-boxes first axis 2)))
    (def second-bottom (read8 ram (+ addr-bounding-boxes second axis 2)))
    (when (or
            (and (< second-top first-top) (< second-bottom first-top)
                 (or (<= first-top first-bottom)
                     (and (> second-top first-bottom)
                          (<= second-top second-bottom))))
            (and (> second-top first-top) (< first-bottom second-top)
                 (or (<= second-top second-bottom)
                     (> first-top second-bottom))))
      (set colliding false)))
  colliding)

(defn- setup-floatey!
  [ram points slot]
  (slot-write! ram addr-floatey-control slot points)
  (slot-write! ram addr-floatey-timer slot 0x30)
  (slot-write! ram addr-floatey-y slot (slot-read ram addr-enemy-y slot))
  (slot-write! ram addr-floatey-x slot (read8 ram addr-enemy-relative-x)))

(defn force-injury!
  [ram]
  (if (zero? (read8 ram addr-player-status))
    (do
      (write8! ram addr-event-music 1)
      (write8! ram player/addr-player-y-speed 0xfc)
      (write8! ram player/addr-player-x-speed 0)
      (write8! ram player/addr-game-routine player/routine-player-death))
    (do
      (write8! ram addr-injury-timer 8)
      (write8! ram addr-square1-sound 0x10)
      (write8! ram addr-player-status 0)
      (write8! ram player/addr-game-routine player/routine-injury)))
  (write8! ram player/addr-player-state player/state-jump-swim)
  (write8! ram addr-timer-control 0xff)
  (write8! ram 0x0775 0))

(defn injure-player!
  [ram]
  (when (zero? (read8 ram addr-injury-timer))
    (force-injury! ram)))

(defn- face-player!
  [ram slot]
  (def negative ((player-enemy-diff ram slot) :negative))
  (slot-write! ram addr-enemy-moving-dir slot (if negative 2 1))
  negative)

(defn- set-stun!
  [ram slot]
  (slot-write! ram addr-enemy-y slot (- (slot-read ram addr-enemy-y slot) 2))
  (slot-write! ram addr-enemy-y-speed slot
               (if (or (= (slot-read ram addr-enemy-id slot) actor-bloober)
                       (= (read8 ram addr-area-type) 0))
                 0xff
                 0xfd))
  (def negative ((player-enemy-diff ram slot) :negative))
  (unless (or (= (slot-read ram addr-enemy-id slot) actor-cannon-bullet)
              (= (slot-read ram addr-enemy-id slot) actor-bullet-bill))
    (slot-write! ram addr-enemy-moving-dir slot (if negative 2 1)))
  (slot-write! ram addr-enemy-x-speed slot (if negative 0xf0 0x10)))

(defn- check-to-stun!
  [ram enemy-id slot]
  (case enemy-id
    9 (slot-write! ram addr-enemy-id slot actor-red-koopa-greenlike)
    15 (slot-write! ram addr-enemy-id slot actor-red-koopa-greenlike)
    13 (slot-write! ram addr-enemy-id slot actor-red-koopa-greenlike)
    14 (slot-write! ram addr-enemy-id slot actor-green-koopa)
    16 (slot-write! ram addr-enemy-id slot actor-green-koopa)
    nil)
  (slot-write! ram addr-enemy-state slot
               (bor (band (slot-read ram addr-enemy-state slot) 0xf0) 2))
  (set-stun! ram slot))

(defn- shell-defeat!
  [ram slot]
  (var enemy-id (slot-read ram addr-enemy-id slot))
  (when (= enemy-id actor-piranha)
    (slot-write! ram addr-enemy-y slot (+ (slot-read ram addr-enemy-y slot) 0x19))
    (set enemy-id (slot-read ram addr-enemy-y slot)))
  (check-to-stun! ram enemy-id slot)
  (slot-write! ram addr-enemy-state slot
               (bor (band (slot-read ram addr-enemy-state slot) 0x1f) 0x20))
  (setup-floatey! ram
                  (case (slot-read ram addr-enemy-id slot)
                    6 1
                    5 6
                    2)
                  slot)
  (write8! ram addr-square1-sound 8))

(defn- turn-around!
  [ram slot]
  (def id (slot-read ram addr-enemy-id slot))
  (when (or (<= id actor-red-koopa)
            (= id actor-goomba)
            (= id actor-green-paratroopa)
            (= id actor-spiny))
    (slot-write! ram addr-enemy-x-speed slot
                 (- (slot-read ram addr-enemy-x-speed slot)))
    (slot-write! ram addr-enemy-moving-dir slot
                 (bxor (slot-read ram addr-enemy-moving-dir slot) 3))))

(defn- write-fire-player-colors!
  [ram]
  (def background-control (read8 ram addr-background-color))
  (def color-index
    (if (zero? background-control)
      (read8 ram addr-area-type)
      background-control))
  (def background
    (get @[0x22 0x22 0x0f 0x0f 0x0f 0x22 0x0f 0x0f] color-index))
  (def offset (read8 ram addr-vram-buffer-offset))
  (eachp [index value] @[0x3f 0x10 4 background 0x37 0x27 0x16 0]
    (write8! ram (+ 0x0301 offset index) value))
  (write8! ram addr-vram-buffer-offset (+ offset 7)))

(defn- handle-power-up!
  [world slot]
  (def ram (world :ram))
  (erase! world slot)
  (setup-floatey! ram 6 slot)
  (write8! ram addr-square2-sound 0x20)
  (def power-up-type (read8 ram addr-power-up-type))
  (cond
    (= power-up-type 2)
    (slot-write! ram addr-floatey-control slot 0x0b)
    (= power-up-type 3)
    (do
      (write8! ram addr-star-timer 0x23)
      (write8! ram addr-area-music 0x40))
    (or (= power-up-type 0) (= power-up-type 1))
    (cond
      (= (read8 ram addr-player-status) 0)
      (do
        (write8! ram addr-player-status 1)
        (write8! ram player/addr-game-routine player/routine-change-size)
        (write8! ram player/addr-player-state player/state-on-ground)
        (write8! ram addr-timer-control 0xff)
        (write8! ram 0x0775 0))
      (= (read8 ram addr-player-status) 1)
      (do
        (write8! ram addr-player-status 2)
        (write-fire-player-colors! ram)
        (write8! ram player/addr-game-routine player/routine-fire-flower)
        (write8! ram player/addr-player-state player/state-on-ground)
        (write8! ram addr-timer-control 0xff)
        (write8! ram 0x0775 0)))))

(defn player-collision!
  [world slot]
  (def ram (world :ram))
  (when (and
          (zero? (band (read8 ram addr-frame-counter) 1))
          (not (or (>= (read8 ram 0x03d0) 0xf0)
                   (and (= (read8 ram player/addr-player-y-high) 1)
                        (>= (read8 ram player/addr-player-y) 0xd0))))
          (zero? (slot-read ram addr-enemy-offscreen-masked slot))
          (= (read8 ram player/addr-game-routine) player/routine-player-control)
          (zero? (band (slot-read ram addr-enemy-state slot) 0x20)))
    (if (not (boxes-collide? ram 0 (* (inc slot) 4)))
      (slot-write! ram addr-enemy-collision-bits slot
                   (band (slot-read ram addr-enemy-collision-bits slot) 0xfe))
      (do
        (def id (slot-read ram addr-enemy-id slot))
        (cond
          (= id actor-power-up) (handle-power-up! world slot)
          (not= (read8 ram addr-star-timer) 0) (shell-defeat! ram slot)
          (not= (bor (band (slot-read ram addr-enemy-collision-bits slot) 1)
                     (slot-read ram addr-enemy-offscreen-masked slot))
                0)
          nil
          true
          (do
            (slot-write! ram addr-enemy-collision-bits slot
                         (bor (slot-read ram addr-enemy-collision-bits slot) 1))
            (cond
              (or (= id actor-podoboo) (= id actor-piranha))
              (injure-player! ram)
              (and (not= id actor-spiny) (not= id actor-cannon-bullet)
                   (not (actor-enemy? id)))
              (injure-player! ram)
              (= (read8 ram addr-area-type) 0)
              (injure-player! ram)
              (and (not= id actor-spiny)
                   (not= id actor-cannon-bullet)
                   (zero? (band (slot-read ram addr-enemy-state slot) 0x80))
                   (not= (band (slot-read ram addr-enemy-state slot) 6) 0))
              (unless (= id actor-goomba)
                (write8! ram addr-square1-sound 8)
                (slot-write! ram addr-enemy-state slot
                             (bor (slot-read ram addr-enemy-state slot) 0x80))
                (slot-write! ram addr-enemy-x-speed slot
                             (if (face-player! ram slot) 0xd0 0x30))
                (setup-floatey! ram
                                (case (slot-read ram 0x0796 slot)
                                  0 10
                                  1 6
                                  2 4
                                  (+ (read8 ram 0x0484) 3))
                                slot))
              true
              (do
                (var injured false)
                (when (zero? (read8 ram addr-stomp-timer))
                  (def direct-stomp-id
                    (or (<= id actor-goomba) (= id actor-buzzy-beetle)))
                  (def vertical-contact
                    (if direct-stomp-id
                      true
                      (<= (slot-read ram addr-enemy-y slot)
                          (bytes/u8 (+ (read8 ram player/addr-player-y) 0x0c)))))
                  (when (and vertical-contact
                             (or (zero? (read8 ram player/addr-player-y-speed))
                                 (>= (read8 ram player/addr-player-y-speed) 0x80)))
                    (if (zero? (read8 ram addr-injury-timer))
                      (if (>= (read8 ram 0x03ad)
                              (read8 ram addr-enemy-relative-x))
                        (do (when (not= (slot-read ram addr-enemy-moving-dir slot) 1)
                              (turn-around! ram slot))
                            (injure-player! ram))
                        (if (not= (slot-read ram addr-enemy-moving-dir slot) 1)
                          (injure-player! ram)
                          (do (turn-around! ram slot) (injure-player! ram)))))
                    (set injured true)))
                (unless injured
                  (if (= id actor-spiny)
                    (injure-player! ram)
                    (do
                      (write8! ram addr-square1-sound 4)
                      (def points
                        (case id
                          5 6
                          7 6
                          8 2
                          20 2
                          51 2
                          17 5
                          nil))
                      (if points
                        (do
                          (setup-floatey! ram points slot)
                          (def direction (slot-read ram addr-enemy-moving-dir slot))
                          (set-stun! ram slot)
                          (slot-write! ram addr-enemy-moving-dir slot direction)
                          (slot-write! ram addr-enemy-state slot 0x20)
                          (initialize-vertical! ram slot)
                          (slot-write! ram addr-enemy-x-speed slot 0)
                          (write8! ram player/addr-player-y-speed 0xfd))
                        (if (or (<= id actor-goomba) (= id actor-buzzy-beetle))
                          (do
                            (slot-write! ram addr-enemy-state slot 4)
                            (write8! ram 0x0484 (inc (read8 ram 0x0484)))
                            (setup-floatey! ram
                                            (+ (read8 ram 0x0484)
                                               (read8 ram addr-stomp-timer))
                                            slot)
                            (write8! ram addr-stomp-timer
                                     (inc (read8 ram addr-stomp-timer)))
                            (slot-write! ram 0x0796 slot
                                         (if (zero? (read8 ram addr-primary-hard-mode))
                                           0x10 0x0b))
                            (write8! ram player/addr-player-y-speed 0xfc))
                          (do
                            (slot-write! ram addr-enemy-id slot
                                         (if (zero? (band id 1))
                                           actor-green-koopa
                                           actor-red-koopa-greenlike))
                            (slot-write! ram addr-enemy-state slot 0)
                            (setup-floatey! ram 3 slot)
                            (initialize-vertical! ram slot)
                            (slot-write! ram addr-enemy-x-speed slot
                                         (if (face-player! ram slot) 0xf8 8))
                            (write8! ram player/addr-player-y-speed 0xfc))))))))))))))
  world)

(defn fireball-collision!
  [world fireball-slot]
  (def ram (world :ram))
  (when (and (not= (slot-read ram addr-fireball-state fireball-slot) 0)
             (zero? (band (slot-read ram addr-fireball-state fireball-slot) 0x80))
             (zero? (band (read8 ram addr-frame-counter) 1)))
    (var slot 4)
    (while (>= slot 0)
      (def id (slot-read ram addr-enemy-id slot))
      (when (and
              (zero? (band (slot-read ram addr-enemy-state slot) 0x20))
              (not= (slot-read ram addr-enemy-flag slot) 0)
              (not (actor-large-platform? id))
              (not (and (= id actor-goomba)
                        (>= (slot-read ram addr-enemy-state slot) 2)))
              (zero? (slot-read ram addr-enemy-offscreen-masked slot))
              (boxes-collide? ram (* (inc slot) 4)
                              (+ 0x1c (* fireball-slot 4))))
        (slot-write! ram addr-fireball-state fireball-slot 0x80)
        (write8! ram addr-enemy-relative-y (slot-read ram addr-enemy-y slot))
        (write8! ram addr-enemy-relative-x
                 (- (slot-read ram addr-enemy-x slot) (read8 ram 0x071c)))
        (def flag (slot-read ram addr-enemy-flag slot))
        (def parent (band flag 0x0f))
        (def bowser-slot
          (cond
            (= id actor-bowser) slot
            (and (not= (band flag 0x80) 0)
                 (= (slot-read ram addr-enemy-id parent) actor-bowser))
            parent
            true nil))
        (if (not (nil? bowser-slot))
          (do
            (def hit-points (bytes/u8 (dec (read8 ram addr-bowser-hit-points))))
            (write8! ram addr-bowser-hit-points hit-points)
            (when (zero? hit-points)
              (initialize-vertical! ram bowser-slot)
              (write8! ram addr-enemy-frenzy-buffer 0)
              (slot-write! ram addr-enemy-x-speed bowser-slot 0)
              (slot-write! ram addr-enemy-y-speed bowser-slot 0xfe)
              (slot-write! ram addr-enemy-id bowser-slot
                           (rom/read-cpu (world :rom)
                                         (+ 0xd736
                                            (read8 ram addr-world-number))))
              (slot-write! ram addr-enemy-state bowser-slot
                           (if (< (read8 ram addr-world-number) 3) 0x23 0x20))
              (write8! ram addr-square2-sound 0x80)
              (setup-floatey! ram 9 slot)
              (write8! ram addr-square1-sound 8)))
          (unless (or (= id actor-buzzy-beetle)
                      (= id actor-bullet-bill)
                      (= id actor-podoboo)
                      (not (actor-enemy? id)))
            (shell-defeat! ram slot))))
      (-- slot)))
  world)

(defn enemy-collision!
  [world slot]
  (def ram (world :ram))
  (when (and
          (not= (band (read8 ram addr-frame-counter) 1) 0)
          (not= (read8 ram addr-area-type) 0)
          (actor-enemy? (slot-read ram addr-enemy-id slot))
          (not= (slot-read ram addr-enemy-id slot) actor-lakitu)
          (not= (slot-read ram addr-enemy-id slot) actor-piranha)
          (zero? (slot-read ram addr-enemy-offscreen-masked slot)))
    (var other (dec slot))
    (while (>= other 0)
      (when (and
              (not= (slot-read ram addr-enemy-flag other) 0)
              (actor-enemy? (slot-read ram addr-enemy-id other))
              (not= (slot-read ram addr-enemy-id other) actor-lakitu)
              (not= (slot-read ram addr-enemy-id other) actor-piranha)
              (zero? (slot-read ram addr-enemy-offscreen-masked other)))
        (def mask (blshift 1 (- 7 slot)))
        (if (not (boxes-collide? ram (* (inc other) 4) (* (inc slot) 4)))
          (slot-write! ram addr-enemy-collision-bits other
                       (band (slot-read ram addr-enemy-collision-bits other)
                             (bnot mask)))
          (when (or (not= (band (slot-read ram addr-enemy-state slot) 0x80) 0)
                    (not= (band (slot-read ram addr-enemy-state other) 0x80) 0)
                    (zero? (band (slot-read ram addr-enemy-collision-bits other)
                                 mask)))
            (slot-write! ram addr-enemy-collision-bits other
                         (bor (slot-read ram addr-enemy-collision-bits other) mask))
            (cond
              (not= (band (bor (slot-read ram addr-enemy-state other)
                               (slot-read ram addr-enemy-state slot))
                           0x20)
                    0)
              nil
              (and (< (slot-read ram addr-enemy-state slot) 6)
                   (< (slot-read ram addr-enemy-state other) 6))
              (do (turn-around! ram other) (turn-around! ram slot))
              (and (< (slot-read ram addr-enemy-state slot) 6)
                   (not= (slot-read ram addr-enemy-id other) actor-hammer-bro))
              (do
                (shell-defeat! ram slot)
                (setup-floatey! ram
                                (+ (slot-read ram addr-shell-chain other) 4)
                                slot)
                (slot-write! ram addr-shell-chain other
                             (inc (slot-read ram addr-shell-chain other))))
              (and (>= (slot-read ram addr-enemy-state slot) 6)
                   (not= (slot-read ram addr-enemy-id slot) actor-hammer-bro))
              (do
                (when (>= (slot-read ram addr-enemy-state other) 0x80)
                  (setup-floatey! ram 6 slot)
                  (shell-defeat! ram slot))
                (shell-defeat! ram other)
                (setup-floatey! ram
                                (+ (slot-read ram addr-shell-chain slot) 4)
                                other)
                (slot-write! ram addr-shell-chain slot
                             (inc (slot-read ram addr-shell-chain slot))))))))
      (-- other)))
  world)

(defn- get-metatile
  [ram mt-x mt-y]
  (if (or (< mt-y 0) (>= mt-y 13))
    0
    (read8 ram (+ (if (< (% mt-x 32) 16) 0x0500 0x05d0)
                  (% mt-x 16)
                  (* mt-y 16)))))

(def collision-x-adders
  @[8 3 12 2 2 13 13 8 3 12 2 2 13 13
    8 3 12 2 2 13 13 8 0 16 4 20 4 4])
(def collision-y-adders
  @[4 32 32 8 24 8 24 2 32 32 8 24 8 24
    18 32 32 24 24 24 24 24 20 20 6 6 8 16])

(defn- block-collision
  [ram use-x object probe]
  (def x-position
    (bytes/pack-u16 (read8 ram (+ movement/page-base object))
                    (read8 ram (+ movement/x-position-base object))))
  (def y-position (read8 ram (+ movement/y-position-base object)))
  (def mt-x (div (+ x-position (get collision-x-adders probe)) 16))
  (def mt-y (- (div (+ y-position (get collision-y-adders probe)) 16) 2))
  @[(get-metatile ram mt-x mt-y)
    (band (if use-x x-position y-position) 0x0f)])

(defn- non-solid?
  [tile]
  (or (= tile 0x26) (= tile 0x5f) (= tile 0x60)
      (= tile 0xc2) (= tile 0xc3)))

(defn- side-check!
  [ram slot]
  (when (>= (slot-read ram addr-enemy-y slot) 0x20)
    (def direction (slot-read ram addr-enemy-moving-dir slot))
    (when (or (= direction 1) (= direction 2))
      (def tile (get (block-collision ram true (inc slot)
                                      (if (= direction 1) 23 22))
                     0))
      (when (and (not= tile 0) (not (non-solid? tile)))
        (when (and (not= slot 5)
                   (>= (slot-read ram addr-enemy-state slot) 0x80))
          (write8! ram addr-square1-sound 2))
        (turn-around! ram slot)))))

(defn- enemy-landing!
  [ram slot]
  (initialize-vertical! ram slot)
  (slot-write! ram addr-enemy-y slot
               (bor (band (slot-read ram addr-enemy-y slot) 0xf0) 8)))

(defn enemy-jump!
  [ram slot]
  (when (and (> (bytes/u8 (+ (slot-read ram addr-enemy-y slot) 0x3e)) 0x43)
             (> (bytes/u8 (+ (slot-read ram addr-enemy-y-speed slot) 2)) 2))
    (def tile (get (block-collision ram false (inc slot) 21) 0))
    (when (and (not= tile 0) (not (non-solid? tile)))
      (enemy-landing! ram slot)
      (slot-write! ram addr-enemy-y-speed slot 0xfd)))
  (side-check! ram slot))

(defn- hammer-background!
  [ram slot]
  (def tile (get (block-collision ram false (inc slot) 21) 0))
  (var handled false)
  (when (not= tile 0)
    (cond
      (= tile 0x23)
      (do
        (shell-defeat! ram slot)
        (slot-write! ram addr-enemy-y-speed slot 0xfc)
        (set handled true))
      (zero? (slot-read ram addr-enemy-frame-timer slot))
      (do
        (slot-write! ram addr-enemy-state slot
                     (band (slot-read ram addr-enemy-state slot) 0x88))
        (enemy-landing! ram slot)
        (side-check! ram slot)
        (set handled true))))
  (unless handled
    (slot-write! ram addr-enemy-state slot
                 (bor (slot-read ram addr-enemy-state slot) 1))))

(defn background-collision!
  [world slot]
  (def ram (world :ram))
  (when (and
          (zero? (band (slot-read ram addr-enemy-state slot) 0x20))
          (> (bytes/u8 (+ (slot-read ram addr-enemy-y slot) 0x3e)) 0x43))
    (def id (slot-read ram addr-enemy-id slot))
    (cond
      (= id actor-green-paratroopa)
      (enemy-jump! ram slot)
      (= id actor-hammer-bro)
      (hammer-background! ram slot)
      (and (= id actor-spiny) (< (slot-read ram addr-enemy-y slot) 0x25))
      nil
      (or (= id actor-green-koopa)
          (= id actor-red-koopa-greenlike)
          (= id actor-buzzy-beetle)
          (= id actor-red-koopa)
          (= id actor-goomba)
          (= id 4)
          (= id actor-spiny)
          (= id actor-power-up))
      (do
        (def collision (block-collision ram false (inc slot) 21))
        (def tile (get collision 0))
        (if (or (= tile 0) (non-solid? tile)
                (> (bytes/u8 (- (get collision 1) 8)) 4))
          (do
            (def red-turn
              (and (= id actor-red-koopa)
                   (zero? (slot-read ram addr-enemy-state slot))))
            (if red-turn
              (turn-around! ram slot)
              (if (not= (band (slot-read ram addr-enemy-state slot) 0x80) 0)
                (slot-write! ram addr-enemy-state slot
                             (bor (slot-read ram addr-enemy-state slot) 0x40))
                (slot-write! ram addr-enemy-state slot
                             (get @[1 1 2 2 2 5]
                                  (slot-read ram addr-enemy-state slot)))))
            (unless red-turn
              (side-check! ram slot)))
          (do
            (def state (slot-read ram addr-enemy-state slot))
            (if (not= (band state 0x40) 0)
              (do
                (enemy-landing! ram slot)
                (slot-write! ram addr-enemy-state slot
                             (if (not= (band state 0x80) 0)
                               (band state 0xbf)
                               0)))
              (cond
                (= state 2)
                (do
                  (slot-write! ram 0x0796 slot (if (= id actor-spiny) 0 0x10))
                  (slot-write! ram addr-enemy-state slot 3)
                  (enemy-landing! ram slot))
                (or (= state 0) (= state 1) (= state 5))
                (do
                  (side-check! ram slot)
                  (enemy-landing! ram slot)
                  (slot-write! ram addr-enemy-state slot 0)))))))))
  world)

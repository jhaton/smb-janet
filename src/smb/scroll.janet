(import ./bytes)
(import ./input)
(import ./movement)

(def platform-scroll-address 0x03a1)
(def player-scroll-address 0x06ff)
(def screen-left-page-address 0x071a)
(def screen-right-page-address 0x071b)
(def screen-left-x-address 0x071c)
(def screen-right-x-address 0x071d)
(def scroll-lock-address 0x0723)
(def scroll-thirty-two-address 0x073d)
(def horizontal-scroll-address 0x073f)
(def player-position-for-scroll-address 0x0755)
(def scroll-amount-address 0x0775)
(def mirror-ppu-control-one-address 0x0778)
(def side-collision-timer-address 0x0785)
(def scroll-interval-timer-address 0x0795)
(def left-right-buttons-address 0x000c)
(def offscreen-bit-mask
  [0x7f 0x3f 0x1f 0x0f 0x07 0x03 0x01 0x00
   0x80 0xc0 0xe0 0xf0 0xf8 0xfc 0xfe 0xff])


(defn screen-position!
  [ram]
  (def left-x (get ram screen-left-x-address))
  (put ram screen-right-x-address (bytes/u8 (dec left-x)))
  (put ram screen-right-page-address
       (bytes/u8 (+ (get ram screen-left-page-address)
                    (if (= left-x 0) 0 1))))
  (get ram screen-right-page-address))

(defn- wrapped-i16
  [value]
  (cond
    (>= value 0x8000) (- value 0x10000)
    (< value -0x8000) (+ value 0x10000)
    value))

(defn- offscreen-index
  [ram object right]
  (def page (get ram (if right screen-right-page-address
                       screen-left-page-address)))
  (def x (get ram (if right screen-right-x-address
                    screen-left-x-address)))
  (def page-difference (- page (get ram (+ movement/page-base object))))
  (def x-difference (- x (get ram (+ movement/x-position-base object))))
  (def distance (wrapped-i16 (+ x-difference (* page-difference 256))))
  (var index
    (cond
      (< distance 0) 7
      (< distance 56) (+ (div distance 8) 8)
      15))
  (when right
    (set index (% (+ index 8) 16)))
  index)

(defn x-offscreen-bits
  [ram object]
  (def right-bits (get offscreen-bit-mask (offscreen-index ram object true)))
  (if (not= right-bits 0)
    right-bits
    (get offscreen-bit-mask (offscreen-index ram object false))))

(defn check-player-offscreen!
  [ram]
  (def bits (x-offscreen-bits ram 0))
  (cond
    (not= (band bits 0x80) 0)
    (do
      (def subtracter 0)
      (def left-x (get ram screen-left-x-address))
      (put ram movement/x-position-base (bytes/u8 (- left-x subtracter)))
      (put ram movement/page-base
           (bytes/u8 (- (get ram screen-left-page-address)
                        (if (< left-x subtracter) 1 0))))
      (when (not= (get ram left-right-buttons-address) input/button-right)
        (put ram movement/x-speed-base 0)))
    (not= (band bits 0x20) 0)
    (do
      (def subtracter 0x10)
      (def right-x (get ram screen-right-x-address))
      (put ram movement/x-position-base (bytes/u8 (- right-x subtracter)))
      (put ram movement/page-base
           (bytes/u8 (- (get ram screen-right-page-address)
                        (if (< right-x subtracter) 1 0))))
      (when (not= (get ram left-right-buttons-address) input/button-left)
        (put ram movement/x-speed-base 0))))
  (put ram platform-scroll-address 0)
  ram)

(defn scroll-screen!
  [ram amount]
  (def byte-amount (bytes/u8 amount))
  (put ram scroll-amount-address byte-amount)
  (put ram scroll-thirty-two-address
       (bytes/u8 (+ (get ram scroll-thirty-two-address) byte-amount)))
  (def position
    (bytes/add-u16 (get ram screen-left-page-address)
                   (get ram screen-left-x-address)
                   0 byte-amount))
  (put ram screen-left-page-address (bytes/high-u16 position))
  (put ram screen-left-x-address (bytes/low-u16 position))
  (put ram horizontal-scroll-address (bytes/low-u16 position))
  (put ram mirror-ppu-control-one-address
       (bor (band (get ram mirror-ppu-control-one-address) 0xfe)
            (band (bytes/high-u16 position) 1)))
  (screen-position! ram)
  (put ram scroll-interval-timer-address 8)
  (check-player-offscreen! ram)
  ram)

(defn handle!
  [ram]
  (def player-scroll
    (bytes/u8 (+ (get ram player-scroll-address)
                 (get ram platform-scroll-address))))
  (put ram player-scroll-address player-scroll)
  (if (or (not= (get ram scroll-lock-address) 0)
          (< (get ram player-position-for-scroll-address) 0x50)
          (not= (get ram side-collision-timer-address) 0)
          (> (bytes/u8 (dec player-scroll)) 0x7f))
    (do
      (put ram scroll-amount-address 0)
      (check-player-offscreen! ram))
    (do
      (def adjusted (if (> player-scroll 1) (dec player-scroll) player-scroll))
      (scroll-screen! ram
                      (if (< (get ram player-position-for-scroll-address) 0x70)
                        adjusted
                        player-scroll))))
  ram)

(import ./bytes)

(def oper-mode-address 0x0770)
(def disable-screen-address 0x0774)
(def mirror-ppu-control-one-address 0x0778)
(def prng-base 0x07a7)
(def display-digits-base 0x07d7)
(def warm-boot-validation-address 0x07ff)
(def sprite-data-base 0x0200)
(def sprite-count 64)
(def sprite-y-offscreen 0xf8)

(defn- clear-range!
  [ram first count]
  (loop [offset :range [0 count]]
    (put ram (+ first offset) 0)))

(defn initialize-memory!
  "Apply the SMB1 selective RAM clear through the supplied low address in page $0700."
  [ram last-low-address]
  (def page-seven-count (bytes/u8 (inc last-low-address)))
  (clear-range! ram 0x000 0x160)
  (clear-range! ram 0x200 0x500)
  (clear-range! ram 0x700 page-seven-count)
  ram)

(defn reset!
  "Apply the SMB1 cold/warm reset decision and gameplay-RAM initialization order."
  [world]
  (def ram (world :ram))
  (var initialize-through
    (if (= (get ram warm-boot-validation-address) 0xa5) 0xd6 0xfe))

  (loop [index :range [0 6]
         :while (= initialize-through 0xd6)]
    (when (> (get ram (+ display-digits-base index)) 9)
      (set initialize-through 0xfe)))

  (initialize-memory! ram initialize-through)
  (put ram oper-mode-address 0)
  (put ram warm-boot-validation-address 0xa5)
  (put ram prng-base 0xa5)
  (loop [sprite :range [0 sprite-count]]
    (put ram (+ sprite-data-base (* sprite 4)) sprite-y-offscreen))
  (put ram mirror-ppu-control-one-address
       (bor (band (get ram mirror-ppu-control-one-address) 0xf0) 0x10))
  (put ram disable-screen-address
       (bytes/u8 (inc (get ram disable-screen-address))))
  (put ram mirror-ppu-control-one-address
       (bor (get ram mirror-ppu-control-one-address) 0x80))
  (put world :frame 0)
  world)

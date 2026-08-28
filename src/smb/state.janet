(import ./bytes)

(def gameplay-ram-size 0x800)

(defn make-world
  []
  @{:frame 0
    :ram (buffer/new-filled gameplay-ram-size)})

(defn- check-address
  [address]
  (unless (and (int? address)
               (>= address 0)
               (< address gameplay-ram-size))
    (error (string "gameplay RAM address out of range: " address))))

(defn read-u8
  [world address]
  (check-address address)
  (get (world :ram) address))

(defn write-u8!
  [world address value]
  (check-address address)
  (put (world :ram) address (bytes/u8 value))
  world)

(defn reset!
  [world]
  (buffer/fill (world :ram))
  (put world :frame 0)
  world)

(defn advance-frame!
  [world]
  (put world :frame (inc (world :frame)))
  world)

(defn snapshot
  [world]
  (buffer/slice (world :ram)))

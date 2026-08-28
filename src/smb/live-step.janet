(import ./movement)

(defn live-step
  [world]
  (def ram (world :ram))
  (def x (get ram movement/x-position-base))
  (def horizontal-speed (get ram movement/x-speed-base))
  (cond
    (and (>= x 224) (< horizontal-speed 0x80))
      (put ram movement/x-speed-base 0xf0)
    (and (<= x 16) (>= horizontal-speed 0x80))
      (put ram movement/x-speed-base 0x10))

  (def y (get ram movement/y-position-base))
  (def vertical-speed (get ram movement/y-speed-base))
  (when (and (>= y 176) (< vertical-speed 0x80))
    (put ram movement/y-speed-base 0xfb)
    (put ram movement/y-move-force-base 0))

  (movement/move-object-horizontally! ram 0)
  (movement/impose-gravity! ram false 0 4 0 4)
  world)

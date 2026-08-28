(import ./bytes)

(def x-speed-base 0x0057)
(def page-base 0x006d)
(def x-position-base 0x0086)
(def y-speed-base 0x009f)
(def y-high-base 0x00b5)
(def y-position-base 0x00ce)
(def x-fraction-base 0x0400)
(def y-position-fraction-base 0x0416)
(def y-move-force-base 0x0433)
(def motion-object-count 22)

(defn- check-object
  [object]
  (unless (and (int? object) (>= object 0) (< object motion-object-count))
    (error (string "motion object index out of range: " object))))

(defn move-object-horizontally!
  "Apply the reference 8.4 horizontal speed to a 16.8 position. Returns the wrapped pixel delta."
  [ram object]
  (check-object object)
  (def old-x (get ram (+ x-position-base object)))
  (def position
    (bytes/pack-u24 (get ram (+ page-base object))
                    old-x
                    (get ram (+ x-fraction-base object))))
  (def speed (* (bytes/i8 (get ram (+ x-speed-base object))) 16))
  (def moved (bytes/u24 (+ position speed)))
  (def new-x (bytes/middle-u24 moved))

  (put ram (+ page-base object) (bytes/high-u24 moved))
  (put ram (+ x-position-base object) new-x)
  (put ram (+ x-fraction-base object) (bytes/low-u24 moved))
  (bytes/u8 (- new-x old-x)))

(defn impose-gravity!
  "Move one object vertically, then update and clamp its signed 8.8 velocity exactly as the reference does."
  [ram upward object acceleration upward-acceleration maximum-speed]
  (check-object object)

  (def y-high-address (+ y-high-base object))
  (def y-address (+ y-position-base object))
  (def y-position-fraction-address (+ y-position-fraction-base object))
  (def speed-address (+ y-speed-base object))
  (def force-address (+ y-move-force-base object))

  (def moved
    (bytes/add-signed-u24-u16
      (get ram y-high-address)
      (get ram y-address)
      (get ram y-position-fraction-address)
      (get ram speed-address)
      (get ram force-address)))
  (put ram y-high-address (bytes/high-u24 moved))
  (put ram y-address (bytes/middle-u24 moved))
  (put ram y-position-fraction-address (bytes/low-u24 moved))

  (def accelerated
    (bytes/add-u16 (get ram speed-address)
                   (get ram force-address)
                   0 acceleration))
  (put ram speed-address (bytes/high-u16 accelerated))
  (put ram force-address (bytes/low-u16 accelerated))

  (def speed (get ram speed-address))
  (def force (get ram force-address))
  (when (and (>= (bytes/i8 (- speed maximum-speed)) 0)
             (>= force 0x80))
    (put ram speed-address (bytes/u8 maximum-speed))
    (put ram force-address 0))

  (when upward
    (def adjusted
      (bytes/sub-u16 (get ram speed-address)
                     (get ram force-address)
                     0 upward-acceleration))
    (put ram speed-address (bytes/high-u16 adjusted))
    (put ram force-address (bytes/low-u16 adjusted))

    (def adjusted-speed (get ram speed-address))
    (def adjusted-force (get ram force-address))
    (when (and (< (bytes/i8 (+ adjusted-speed maximum-speed)) 0)
               (< adjusted-force 0x80))
      (put ram speed-address (bytes/u8 (- maximum-speed)))
      (put ram force-address 0xff)))

  ram)

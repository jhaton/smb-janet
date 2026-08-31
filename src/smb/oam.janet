(import ./bytes)

(def data-base 0x0200)
(def sprite-count 64)
(def offscreen-y 0xf8)

(defn address
  [sprite-offset sprite component]
  (+ data-base (bytes/u8 (+ sprite-offset (* sprite 4) component))))

(defn read
  [ram sprite-offset sprite component]
  (get ram (address sprite-offset sprite component)))

(defn write!
  [ram sprite-offset sprite component value]
  (put ram (address sprite-offset sprite component) (bytes/u8 value)))

(defn draw-row!
  [ram row sprite-offset left-tile right-tile x y attributes flip-horizontal]
  (def left-sprite (* row 2))
  (def right-sprite (inc left-sprite))
  (def effective-attributes (bor attributes (if flip-horizontal 0x40 0)))
  (write! ram sprite-offset left-sprite 1
          (if flip-horizontal right-tile left-tile))
  (write! ram sprite-offset right-sprite 1
          (if flip-horizontal left-tile right-tile))
  (write! ram sprite-offset left-sprite 2 effective-attributes)
  (write! ram sprite-offset right-sprite 2 effective-attributes)
  (write! ram sprite-offset left-sprite 0 (+ y (* row 8)))
  (write! ram sprite-offset right-sprite 0 (+ y (* row 8)))
  (write! ram sprite-offset left-sprite 3 x)
  (write! ram sprite-offset right-sprite 3 (+ x 8)))

(defn hide-row!
  [ram sprite-offset row]
  (write! ram sprite-offset (* row 2) 0 offscreen-y)
  (write! ram sprite-offset (inc (* row 2)) 0 offscreen-y))

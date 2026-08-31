(import ./rom)

(def atlas-width 128)
(def atlas-height 256)
(def tile-size 8)
(def tile-count 512)
(def mask-layer-count 3)

(defn decode
  "Decode the two SMB1 CHR pattern tables once into 2-bit atlas pixels."
  [image]
  (def pixels (buffer/new-filled (* atlas-width atlas-height)))
  (loop [tile :range [0 tile-count]]
    (def source (* tile 0x10))
    (def tile-x (* (% tile 16) tile-size))
    (def tile-y (* (div tile 16) tile-size))
    (loop [y :range [0 tile-size]]
      (def low (rom/read-chr image (+ source y)))
      (def high (rom/read-chr image (+ source y 8)))
      (loop [x :range [0 tile-size]]
        (def shift (- 7 x))
        (def value (bor (band (brshift low shift) 1)
                        (blshift (band (brshift high shift) 1) 1)))
        (put pixels (+ tile-x x (* (+ tile-y y) atlas-width)) value))))
  @{:width atlas-width
    :height atlas-height
    :pixels pixels})

(defn tile-pixel
  [atlas tile x y]
  (unless (and (int? tile) (>= tile 0) (< tile tile-count)
               (int? x) (>= x 0) (< x tile-size)
               (int? y) (>= y 0) (< y tile-size))
    (error "CHR tile pixel coordinate out of range"))
  (def atlas-x (+ (* (% tile 16) tile-size) x))
  (def atlas-y (+ (* (div tile 16) tile-size) y))
  (get (atlas :pixels) (+ atlas-x (* atlas-y atlas-width))))

(defn- push-u16!
  [buffer value]
  (buffer/push-byte buffer (band value 0xff))
  (buffer/push-byte buffer (band (brshift value 8) 0xff)))

(defn- push-u32!
  [buffer value]
  (loop [shift :range [0 32 8]]
    (buffer/push-byte buffer (band (brshift value shift) 0xff))))

(defn mask-bmp
  "Encode the three nonzero CHR pixel planes as one vertically stacked RGBA BMP."
  [atlas]
  (def width (atlas :width))
  (def source-height (atlas :height))
  (def height (* source-height mask-layer-count))
  (def pixel-bytes (* width height 4))
  (def output (buffer/new 54))
  (buffer/push-string output "BM")
  (push-u32! output (+ 54 pixel-bytes))
  (push-u32! output 0)
  (push-u32! output 54)
  (push-u32! output 40)
  (push-u32! output width)
  (push-u32! output height)
  (push-u16! output 1)
  (push-u16! output 32)
  (push-u32! output 0)
  (push-u32! output pixel-bytes)
  (push-u32! output 0)
  (push-u32! output 0)
  (push-u32! output 0)
  (push-u32! output 0)

  # BMP rows are bottom-up. Each layer contains an opaque white mask for one
  # nonzero CHR value and transparent pixels for the other values.
  (loop [bmp-y :range [0 height]]
    (def display-y (- height bmp-y 1))
    (def layer (div display-y source-height))
    (def source-y (% display-y source-height))
    (def target-value (inc layer))
    (loop [x :range [0 width]]
      (def opaque (= (get (atlas :pixels) (+ x (* source-y width))) target-value))
      (def channel (if opaque 0xff 0))
      (buffer/push-byte output channel)
      (buffer/push-byte output channel)
      (buffer/push-byte output channel)
      (buffer/push-byte output channel)))
  output)

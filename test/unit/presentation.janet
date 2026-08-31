(import spork/test)
(import ../../src/smb/chr)
(import ../../src/smb/presentation)
(import ../../src/smb/rom)

(defn- fill-fixture!
  [state]
  (def tables (state :nametables))
  (loop [index :range [0 0x03c0]]
    (put tables index (band (+ (* index 13) 7) 0xff))
    (put tables (+ 0x0400 index) (band (+ (* index 17) 11) 0xff)))
  (loop [index :range [0 0x40]]
    (put tables (+ 0x03c0 index) (band (+ (* index 29) 3) 0xff))
    (put tables (+ 0x07c0 index) (band (+ (* index 31) 5) 0xff)))
  (loop [index :range [0 0x20]]
    (put (state :palette) index (band (+ (* index 3) 2) 0x3f)))
  (loop [sprite :range [0 64]]
    (def offset (* sprite 4))
    (put (state :sprites) offset (band (+ (* sprite 17) 3) 0xff))
    (put (state :sprites) (+ offset 1) (band (+ (* sprite 11) 5) 0xff))
    (put (state :sprites) (+ offset 2)
         (bor (band sprite 3)
              (if (= (% sprite 3) 0) 0x20 0)
              (if (not= (band sprite 4) 0) 0x40 0)
              (if (not= (band sprite 8) 0) 0x80 0)))
    (put (state :sprites) (+ offset 3) (band (+ (* sprite 19) 9) 0xff)))
  state)

(def scenarios
  {"screen-off" [false 0]
   "scroll-0" [true 0]
   "scroll-7" [true 7]
   "scroll-8" [true 8]
   "scroll-255" [true 255]
   "scroll-256" [true 256]
   "scroll-511" [true 511]})

(defn- palette-text
  [palette]
  (def digits "0123456789abcdef")
  (def output (buffer/new 64))
  (each value palette
    (buffer/push-byte output (get digits (band (brshift value 4) 0x0f)))
    (buffer/push-byte output (get digits (band value 0x0f))))
  (string output))

(test/start-suite "CHR decoding and ordered presentation oracle parity")

(def image (rom/load))
(def atlas (chr/decode image))
(def state (presentation/make-state))
(def counts @{:chr 0 :palette 0 :tile 0 :count 0})

(each line (string/split "\n" (slurp "build/render-vectors.tsv"))
  (when (pos? (length line))
    (def fields (string/split "\t" line))
    (case (get fields 0)
      "X"
      (do
        (def tile (scan-number (get fields 1)))
        (def actual (buffer/new 64))
        (loop [y :range [0 8]]
          (loop [x :range [0 8]]
            (buffer/push-byte actual (+ 0x30 (chr/tile-pixel atlas tile x y)))))
        (test/assert (= (string actual) (get fields 2))
                     (string "CHR tile mismatch " tile))
        (put counts :chr (inc (counts :chr))))

      "P"
      (do
        (def name (get fields 1))
        (def scenario (get scenarios name))
        (unless scenario
          (error (string "unknown render scenario: " name)))
        (fill-fixture! state)
        (put state :screen-on (get scenario 0))
        (put state :scroll-x (get scenario 1))
        (presentation/build-commands! state)
        (test/assert (= (palette-text (state :palette)) (get fields 2))
                     (string "palette mismatch " name))
        (put counts :palette (inc (counts :palette))))

      "T"
      (do
        (def name (get fields 1))
        (def index (scan-number (get fields 2)))
        (def expected
          [(scan-number (get fields 3))
           (scan-number (get fields 4))
           (= (get fields 5) "1")
           (= (get fields 6) "1")
           (scan-number (get fields 7))
           (scan-number (get fields 8))
           (scan-number (get fields 9))
           (scan-number (get fields 10))
           (scan-number (get fields 11))])
        (test/assert (= (presentation/command state index) expected)
                     (string "tile command mismatch " name " index " index))
        (put counts :tile (inc (counts :tile))))

      "C"
      (do
        (def name (get fields 1))
        (def expected (scan-number (get fields 2)))
        (test/assert (= (state :command-count) expected)
                     (string "command count mismatch " name))
        (put counts :count (inc (counts :count))))

      (error (string "unknown render oracle row: " (get fields 0))))))

(test/assert (= (counts :chr) 512) "render oracle must cover all CHR tiles")
(test/assert (= (counts :palette) 7) "render oracle palette scenario count")
(test/assert (= (counts :tile) 11136) "render oracle tile command count")
(test/assert (= (counts :count) 7) "render oracle frame count")

(def mask-bmp (chr/mask-bmp atlas))
(test/assert (= (length mask-bmp) 393270) "CHR mask atlas BMP size")
(test/assert (and (= (get mask-bmp 0) 0x42) (= (get mask-bmp 1) 0x4d))
             "CHR mask atlas BMP header")

(test/end-suite)

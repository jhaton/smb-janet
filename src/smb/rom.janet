(def header-size 16)
(def prg-size 0x8000)
(def chr-size 0x2000)
(def expected-size (+ header-size prg-size chr-size))
(def cpu-base 0x8000)
(def default-path "local/smb.nes")

(defn load
  "Load and validate the supported SMB1 iNES image without copying PRG or CHR data."
  [&opt path]
  (default path default-path)
  (def image (slurp path))
  (unless (= (length image) expected-size)
    (error (string "unsupported SMB1 ROM size: " (length image))))
  (unless (and (= (get image 0) 0x4e)
               (= (get image 1) 0x45)
               (= (get image 2) 0x53)
               (= (get image 3) 0x1a))
    (error "invalid iNES header"))
  (unless (and (= (get image 4) 2)
               (= (get image 5) 1)
               (= (band (get image 6) 0xf4) 0)
               (= (band (get image 7) 0xf0) 0))
    (error "unsupported ROM layout; expected mapper-0 SMB1 with 32 KiB PRG and 8 KiB CHR"))
  {:path path :image image})

(defn read-cpu
  [rom address]
  (unless (and (int? address) (>= address cpu-base) (<= address 0xffff))
    (error (string/format "CPU ROM address out of range: 0x%04x" address)))
  (get (rom :image) (+ header-size (- address cpu-base))))

(defn read-cpu-u16
  [rom address]
  (bor (read-cpu rom address)
       (blshift (read-cpu rom (inc address)) 8)))

(defn read-chr
  [rom offset]
  (unless (and (int? offset) (>= offset 0) (< offset chr-size))
    (error (string/format "CHR offset out of range: 0x%04x" offset)))
  (get (rom :image) (+ header-size prg-size offset)))

(defn attach!
  [world rom]
  (put world :rom rom)
  world)

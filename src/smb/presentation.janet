(import ./bytes)
(import ./metatiles)
(import ./rom)

(def screen-width 256)
(def screen-height 240)
(def nametable-size 0x400)
(def nametable-count 2)
(def palette-size 0x20)
(def sprite-count 64)
(def sprite-data-base 0x0200)
(def max-command-count 1856)

(def tile-type-sprite 0)
(def tile-type-background 1)
(def flag-flip-horizontal 1)
(def flag-flip-vertical 2)
(def background-colors @[0x22 0x22 0x0f 0x0f 0x0f 0x22 0x0f 0x0f])

(defn make-state
  []
  @{:nametables (buffer/new-filled (* nametable-size nametable-count))
    :palette (buffer/new-filled palette-size)
    :sprites (buffer/new-filled (* sprite-count 4))
    :screen-on false
    :scroll-x 0
    :command-count 0
    :command-tiles (array/new-filled max-command-count 0)
    :command-palettes (buffer/new-filled max-command-count)
    :command-flags (buffer/new-filled max-command-count)
    :command-x (array/new-filled max-command-count 0)
    :command-y (array/new-filled max-command-count 0)
    :command-types (buffer/new-filled max-command-count)
    :command-extra-x (array/new-filled max-command-count 0)
    :command-extra-y (array/new-filled max-command-count 0)})

(defn- ppu-write!
  [state address value]
  (cond
    (and (>= address 0x2000) (< address 0x2800))
    (put (state :nametables) (- address 0x2000) value)
    (and (>= address 0x3f00) (< address 0x4000))
    (do
      (def raw-index (band address 0x1f))
      (def index (if (= raw-index 0x10) 0 raw-index))
      (put (state :palette) index value))
    true nil))

(defn- apply-stream!
  [state read-byte source terminator]
  (var offset source)
  (var running true)
  (while running
    (def high (read-byte offset))
    (++ offset)
    (if (= high terminator)
      (set running false)
      (do
        (def low (read-byte offset))
        (def control (read-byte (inc offset)))
        (set offset (+ offset 2))
        (var count (band control 0x3f))
        (when (zero? count) (set count 0x100))
        (def increment (if (not= (band control 0x80) 0) 32 1))
        (def repeat? (not= (band control 0x40) 0))
        (def repeated (if repeat? (read-byte offset) 0))
        (when repeat? (++ offset))
        (var address (bor (blshift high 8) low))
        (loop [_ :range [0 count]]
          (ppu-write! state address
                      (if repeat?
                        repeated
                        (do
                          (def value (read-byte offset))
                          (++ offset)
                          value)))
          (set address (+ address increment))))))
  state)

(defn- apply-vram-stream!
  [state cartridge source terminator]
  (apply-stream! state |(rom/read-cpu cartridge $) source terminator))

(defn load-default-presentation!
  "Load SMB1's ground-area palette and top status line from ROM data."
  [state cartridge]
  (loop [table :range [0 nametable-count]]
    (def base (* table nametable-size))
    (loop [tile-y :range [0 30]]
      (loop [tile-x :range [0 32]]
        (put (state :nametables) (+ base (* tile-y 32) tile-x) 0x24))))
  (def palette-pointer
    (bor (rom/read-cpu cartridge 0x805c)
         (blshift (rom/read-cpu cartridge 0x806f) 8)))
  (apply-vram-stream! state cartridge palette-pointer 0)
  (apply-vram-stream! state cartridge
                      (+ 0x8752 (rom/read-cpu cartridge 0x87fe))
                      0xff)
  state)

(defn load-title-presentation!
  "Apply SMB1's CHR-resident title-screen stream to the detached nametables."
  [state cartridge]
  (apply-stream! state |(rom/read-chr cartridge $) 0x1ec0 0)
  state)

(defn sync-metatiles!
  "Expand both block-buffer pages into nametable tiles and attributes."
  [state world]
  (def ram (world :ram))
  (def cartridge (world :rom))
  (def tables (state :nametables))
  (loop [column :range [0 32]]
    (def base (if (< column 16) 0 nametable-size))
    (def tile-x (* (% column 16) 2))
    (loop [row :range [0 metatiles/column-height]]
      (def metatile (metatiles/get-metatile ram column row))
      (def group (brshift metatile 6))
      (def pointer
        (bor (rom/read-cpu cartridge (+ 0x8b08 group))
             (blshift (rom/read-cpu cartridge (+ 0x8b0c group)) 8)))
      (def source (+ pointer (band (blshift metatile 2) 0xff)))
      (def tile-y (+ 4 (* row 2)))
      (put tables (+ base (* tile-y 32) tile-x)
           (rom/read-cpu cartridge source))
      (put tables (+ base (* (inc tile-y) 32) tile-x)
           (rom/read-cpu cartridge (inc source)))
      (put tables (+ base (* tile-y 32) (inc tile-x))
           (rom/read-cpu cartridge (+ source 2)))
      (put tables (+ base (* (inc tile-y) 32) (inc tile-x))
           (rom/read-cpu cartridge (+ source 3)))
      (def attribute-address
        (+ base 0x03c0 (* (div tile-y 4) 8) (div tile-x 4)))
      (def shift (+ (* (% (div tile-x 2) 2) 2)
                    (* (% (div tile-y 2) 2) 4)))
      (def previous (get tables attribute-address))
      (put tables attribute-address
           (bor (band previous (bxor 0xff (blshift 3 shift)))
                (blshift group shift)))))
  state)

(defn- sync-player-palette!
  [state ram]
  (def control (get ram 0x0744))
  (def background-index (if (zero? control) (get ram 0x074e) control))
  (put (state :palette) 0 (get background-colors background-index))
  (def mario? (zero? (get ram 0x0753)))
  (def status (get ram 0x0756))
  (def palette (state :palette))
  (if (= status 2)
    (do
      (put palette 17 0x37)
      (put palette 18 0x27)
      (put palette 19 0x16))
    (if mario?
      (do
        (put palette 17 0x16)
        (put palette 18 0x27)
        (put palette 19 0x18))
      (do
        (put palette 17 0x30)
        (put palette 18 0x27)
        (put palette 19 0x19))))
  state)
(defn sync-status!
  "Write current score, coin, world, level, and timer digits into NT0."
  [state ram]
  (def table (state :nametables))
  (loop [index :range [0 6]]
    (put table (+ (* 3 32) 2 index) (get ram (+ 0x07dd index))))
  (put table (+ (* 3 32) 13) (get ram 0x07ed))
  (put table (+ (* 3 32) 14) (get ram 0x07ee))
  (loop [index :range [0 3]]
    (put table (+ (* 3 32) 26 index) (get ram (+ 0x07f8 index))))
  (put table (+ (* 3 32) 18) (inc (get ram 0x075f)))
  (put table (+ (* 3 32) 19) 0x28)
  (sync-player-palette! state ram)
  (put table (+ (* 3 32) 20) (inc (get ram 0x075c)))

  state)

(defn capture-sprites!
  "Capture OAM before the simulation frame, matching the NES DMA ordering."
  [state ram]
  (def sprites (state :sprites))
  (loop [offset :range [0 (* sprite-count 4)]]
    (put sprites offset (get ram (+ sprite-data-base offset))))
  state)

(defn- emit!
  [state tile palette flags x y type extra-x extra-y]
  (def index (state :command-count))
  (when (>= index max-command-count)
    (error "presentation command buffer overflow"))
  (put (state :command-tiles) index tile)
  (put (state :command-palettes) index palette)
  (put (state :command-flags) index flags)
  (put (state :command-x) index x)
  (put (state :command-y) index y)
  (put (state :command-types) index type)
  (put (state :command-extra-x) index extra-x)
  (put (state :command-extra-y) index extra-y)
  (put state :command-count (inc index)))

(defn- emit-sprite!
  [state sprite]
  (def source (state :sprites))
  (def offset (* sprite 4))
  (def attributes (get source (+ offset 2)))
  (def flags (bor (if (not= (band attributes 0x40) 0) flag-flip-horizontal 0)
                  (if (not= (band attributes 0x80) 0) flag-flip-vertical 0)))
  (emit! state
         (get source (+ offset 1))
         (+ 4 (band attributes 3))
         flags
         (get source (+ offset 3))
         (inc (get source offset))
         tile-type-sprite
         sprite
         -1))

(defn- nametable-base
  [ppu-offset]
  (case ppu-offset
    0x2000 0
    0x2400 nametable-size
    (error (string/format "unsupported nametable address: 0x%04x" ppu-offset))))

(defn- emit-background-tile!
  [state x y ppu-offset tile-x tile-y]
  (def table (state :nametables))
  (def base (nametable-base ppu-offset))
  (def tile (get table (+ base (* tile-y 32) tile-x)))
  (def attribute
    (get table (+ base 0x03c0 (* (div tile-y 4) 8) (div tile-x 4))))
  (def palette
    (band (brshift attribute
                    (+ (* (% (div tile-x 2) 2) 2)
                       (* (% (div tile-y 2) 2) 4)))
          3))
  # The C reference exposes tile-x in both debug coordinates; preserve it.
  (emit! state (+ tile 0x100) palette 0 x y tile-type-background tile-x tile-x))

(defn- emit-background-rect!
  [state x y ppu-offset from-x from-y to-x to-y]
  (loop [tile-y :range [from-y to-y]]
    (loop [tile-x :range [from-x to-x]]
      (emit-background-tile! state
                             (+ x (* (- tile-x from-x) 8))
                             (+ y (* (- tile-y from-y) 8))
                             ppu-offset tile-x tile-y))))

(defn build-commands!
  "Build the exact ordered C-reference tile stream without touching gameplay RAM."
  [state]
  (put state :command-count 0)
  (when (state :screen-on)
    (var sprite 63)
    (while (>= sprite 0)
      (when (not= (band (get (state :sprites) (+ (* sprite 4) 2)) 0x20) 0)
        (emit-sprite! state sprite))
      (-- sprite))

    (emit-background-rect! state 0 0 0x2000 0 0 32 4)
    (def scroll-x (state :scroll-x))
    (def scroll-offset (- (% scroll-x 256)))
    (def scroll-nametable (div scroll-x 256))
    (if (= scroll-nametable 0)
      (do
        (emit-background-rect! state scroll-offset 32 0x2000 0 4 32 30)
        (emit-background-rect! state (+ 256 scroll-offset) 32 0x2400 0 4 32 30))
      (do
        (emit-background-rect! state scroll-offset 32 0x2400 0 4 32 30)
        (emit-background-rect! state (+ 256 scroll-offset) 32 0x2000 0 4 32 30)))

    (set sprite 63)
    (while (>= sprite 0)
      (when (= (band (get (state :sprites) (+ (* sprite 4) 2)) 0x20) 0)
        (emit-sprite! state sprite))
      (-- sprite)))
  state)

(defn command
  "Return one command for tests and inspection; the renderer reads the backing arrays directly."
  [state index]
  (unless (and (int? index) (>= index 0) (< index (state :command-count)))
    (error "presentation command index out of range"))
  [(get (state :command-tiles) index)
   (get (state :command-palettes) index)
   (not= (band (get (state :command-flags) index) flag-flip-horizontal) 0)
   (not= (band (get (state :command-flags) index) flag-flip-vertical) 0)
   (get (state :command-x) index)
   (get (state :command-y) index)
   (get (state :command-types) index)
   (get (state :command-extra-x) index)
   (get (state :command-extra-y) index)])

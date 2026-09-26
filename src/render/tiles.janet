(import raylib :as rl)
(import ../smb/chr)
(import ../smb/presentation)

(def scale 2)
(def tile-size 8)

(defn- rgba
  "Split an 0xRRGGBBAA literal into the [r g b a] tuple raylib takes."
  [hex]
  [(div hex 0x1000000) (% (div hex 0x10000) 0x100) (% (div hex 0x100) 0x100) (% hex 0x100)])

(def- nes-hex-colors
  @[0x666666ff 0x002a88ff 0x1412a7ff 0x3b00a4ff
    0x5c007eff 0x6e0040ff 0x6c0600ff 0x561d00ff
    0x333500ff 0x0b4800ff 0x005200ff 0x004f08ff
    0x00404dff 0x000000ff 0x000000ff 0x000000ff
    0xadadadff 0x155fd9ff 0x4240ffff 0x7527feff
    0xa01accff 0xb71e7bff 0xb53120ff 0x994e00ff
    0x6b6d00ff 0x388700ff 0x0c9300ff 0x008f32ff
    0x007c8dff 0x000000ff 0x000000ff 0x000000ff
    0xfffeffff 0x64b0ffff 0x9290ffff 0xc676ffff
    0xf36affff 0xfe6eccff 0xfe8170ff 0xea9e22ff
    0xbcbe00ff 0x88d800ff 0x5ce430ff 0x45e082ff
    0x48cddeff 0x4f4f4fff 0x000000ff 0x000000ff
    0xfffeffff 0xc0dfffff 0xd3d2ffff 0xe8c8ffff
    0xfbc2ffff 0xfec4eaff 0xfeccc5ff 0xf7d8a5ff
    0xe4e594ff 0xcfef96ff 0xbdf4abff 0xb3f3ccff
    0xb5ebf2ff 0xb8b8b8ff 0x000000ff 0x000000ff])

(def nes-colors (map rgba nes-hex-colors))

(defn load-atlas
  "Decode CHR once and upload its indexed mask planes plus a cached world target."
  [cartridge]
  (def atlas (chr/decode cartridge))
  (def image (rl/load-image-from-memory ".bmp" (chr/mask-bmp atlas)))
  (def texture (rl/load-texture-from-image image))
  (rl/unload-image image)
  (rl/set-texture-filter texture :point)
  (def world-target (rl/load-render-texture 512 208))
  (def world-texture (world-target :texture))
  (def screen-target (rl/load-render-texture 512 480))
  (def screen-texture (screen-target :texture))
  (rl/set-texture-filter world-texture :point)
  (rl/set-texture-filter screen-texture :point)
  @{:texture texture
    :world-target world-target
    :world-texture world-texture
    :screen-target screen-target
    :screen-texture screen-texture
    :world-signature nil
    :source @[0 0 0 0]
    :destination @[0 0 0 0]
    :origin @[0 0]})

(defn unload-atlas
  [atlas]
  (rl/unload-render-texture (atlas :screen-target))
  (rl/unload-render-texture (atlas :world-target))
  (rl/unload-texture (atlas :texture)))

(defn- palette-color
  [display palette-index pixel-value]
  (def nes-index
    (band (get (display :palette) (+ (* palette-index 4) pixel-value)) 0x3f))
  (get nes-colors nes-index))

(defn- draw-layered-tile!
  [atlas display tile palette flags x y output-scale]
  (def source (atlas :source))
  (def destination (atlas :destination))
  (def flip-horizontal
    (not= (band flags presentation/flag-flip-horizontal) 0))
  (def flip-vertical
    (not= (band flags presentation/flag-flip-vertical) 0))
  (put source 0 (* (% tile 16) tile-size))
  (put source 2 (if flip-horizontal (- tile-size) tile-size))
  (put source 3 (if flip-vertical (- tile-size) tile-size))
  (put destination 0 (* output-scale x))
  (put destination 1 (* output-scale y))
  (put destination 2 (* output-scale tile-size))
  (put destination 3 (* output-scale tile-size))
  (loop [pixel-value :range [1 4]]
    (put source 1
         (+ (* (div tile 16) tile-size)
            (* (dec pixel-value) chr/atlas-height)))
    (rl/draw-texture-pro (atlas :texture) source destination (atlas :origin) 0
                         (palette-color display palette pixel-value))))

(defn- background-signature
  [display]
  (var signature 5381)
  (loop [index :range [0 (* 2 presentation/nametable-size)]]
    (set signature
         (% (+ (* signature 33) (get (display :nametables) index))
            2147483647)))
  (loop [index :range [0 16]]
    (set signature
         (% (+ (* signature 33) (get (display :palette) index))
            2147483647)))
  signature)

(defn- refresh-world!
  [atlas display signature]
  (rl/begin-texture-mode (atlas :world-target))
  (rl/clear-background (palette-color display 0 0))
  (def tables (display :nametables))
  (loop [name-table :range [0 2]]
    (def base (* name-table presentation/nametable-size))
    (loop [tile-y :range [4 30]]
      (loop [tile-x :range [0 32]]
        (def tile (+ 0x100 (get tables (+ base (* tile-y 32) tile-x))))
        (unless (= tile 0x124)
          (def attribute
            (get tables (+ base 0x03c0 (* (div tile-y 4) 8) (div tile-x 4))))
          (def palette
            (band (brshift attribute
                            (+ (* (% (div tile-x 2) 2) 2)
                               (* (% (div tile-y 2) 2) 4)))
                  3))
          (draw-layered-tile! atlas display tile palette 0
                              (+ (* name-table 256) (* tile-x tile-size))
                              (* (- tile-y 4) tile-size)
                              1)))))
  (rl/end-texture-mode)
  (put atlas :world-signature signature))

(defn- draw-cached-world!
  [atlas display]
  (def scroll (% (display :scroll-x) 512))
  (def first-width (min 256 (- 512 scroll)))
  (def source (atlas :source))
  (def destination (atlas :destination))
  (put source 0 scroll)
  (put source 1 208)
  (put source 2 first-width)
  (put source 3 -208)
  (put destination 0 0)
  (put destination 1 64)
  (put destination 2 (* scale first-width))
  (put destination 3 416)
  (rl/draw-texture-pro (atlas :world-texture) source destination
                       (atlas :origin) 0 :white)
  (when (< first-width 256)
    (def remaining (- 256 first-width))
    (put source 0 0)
    (put source 2 remaining)
    (put destination 0 (* scale first-width))
    (put destination 2 (* scale remaining))
    (rl/draw-texture-pro (atlas :world-texture) source destination
                         (atlas :origin) 0 :white)))

(defn- draw-command!
  [atlas display index]
  (def tile (get (display :command-tiles) index))
  (def type (get (display :command-types) index))
  (def y (get (display :command-y) index))
  (unless (or (and (= type presentation/tile-type-background) (= tile 0x124))
              (and (= type presentation/tile-type-sprite) (= tile 0xfc))
              (and (= type presentation/tile-type-sprite) (> y 240)))
    (draw-layered-tile! atlas display tile
                        (get (display :command-palettes) index)
                        (get (display :command-flags) index)
                        (get (display :command-x) index)
                        y scale)))

(defn draw!
  "Draw ordered presentation into a fixed pixel target, then fit the window."
  [atlas display]
  (def count (display :command-count))
  (when (pos? count)
    (def signature (background-signature display))
    (unless (= signature (atlas :world-signature))
      (refresh-world! atlas display signature)))
  (rl/begin-texture-mode (atlas :screen-target))
  (rl/clear-background (palette-color display 0 0))
  (when (pos? count)
    (var background-start 0)
    (while (and (< background-start count)
                (= (get (display :command-types) background-start)
                   presentation/tile-type-sprite))
      (draw-command! atlas display background-start)
      (++ background-start))
    (def status-end (+ background-start 128))
    (loop [index :range [background-start status-end]]
      (draw-command! atlas display index))
    (draw-cached-world! atlas display)
    (loop [index :range [(+ background-start 1792) count]]
      (draw-command! atlas display index)))
  (rl/end-texture-mode)
  (rl/rl-viewport 0 0 (rl/get-render-width) (rl/get-render-height))
  (rl/clear-background :black)
  (def source (atlas :source))
  (def destination (atlas :destination))
  (put source 0 0)
  (put source 1 480)
  (put source 2 512)
  (put source 3 -480)
  (put destination 0 0)
  (put destination 1 0)
  (put destination 2 (rl/get-render-width))
  (put destination 3 (rl/get-render-height))
  (rl/draw-texture-pro (atlas :screen-texture) source destination
                       (atlas :origin) 0 :white))

(defn save-screenshot
  "Export the fixed 512x480 pixel target used by the window renderer."
  [atlas path]
  (def image (rl/load-image-from-texture (atlas :screen-texture)))
  (rl/image-flip-vertical image)
  (rl/export-image image path)
  (rl/unload-image image))

(use jaylib)
(import ./smb/runtime)
(import ./smb/movement)
(import ./smb/input)

(defn- smoke-frame-limit
  [args]
  (when (def option (index-of "--smoke" args))
    (unless (< option (dec (length args)))
      (error "--smoke requires a positive frame count"))
    (def frames (scan-number (get args (inc option))))
    (unless (and (int? frames) (pos? frames))
      (error "--smoke requires a positive frame count"))
    frames))

(defn- controller-bits
  []
  (bor (if (key-down? :z) input/button-a 0)
       (if (key-down? :x) input/button-b 0)
       (if (key-down? :right-shift) input/button-select 0)
       (if (key-down? :enter) input/button-start 0)
       (if (key-down? :w) input/button-up 0)
       (if (key-down? :s) input/button-down 0)
       (if (key-down? :a) input/button-left 0)
       (if (key-down? :d) input/button-right 0)))

(defn- draw-surface
  [app]
  (def world (app :world))
  (def ram (world :ram))
  (def x (* 2 (get ram movement/x-position-base)))
  (def y (+ 32 (* 2 (get ram movement/y-position-base))))

  (clear-background 0x101820ff)
  (loop [grid-x :range [0 513 32]]
    (draw-line grid-x 32 grid-x 432 0x1d2b3aff))
  (loop [grid-y :range [32 433 32]]
    (draw-line 0 grid-y 512 grid-y 0x1d2b3aff))
  (draw-line 0 416 512 416 0x8ca0b3ff)
  (draw-rectangle x y 32 32 0xf2c94cff)
  (draw-rectangle (+ x 7) (+ y 8) 5 5 0x101820ff)
  (draw-rectangle (+ x 20) (+ y 8) 5 5 0x101820ff)
  (draw-text "SMB Janet motion kernel" 16 8 20 :ray-white)
  (draw-text (string/format "frame %d  reload generation %d  [R] reload"
                            (world :frame) (app :reload-generation))
             16 448 16 0x8ca0b3ff))

(defn main
  [& args]
  (def max-frames (smoke-frame-limit args))
  (def app (runtime/make-runtime))
  (runtime/reload-step! app)
  (def stable-world (app :world))
  (var smoke-reloaded false)
  (var screenshot-written false)

  (init-window 512 480 "SMB Janet — motion kernel")
  (set-target-fps 60)

  (while (and (not (window-should-close))
              (or (nil? max-frames)
                  (< ((app :world) :frame) max-frames)))
    (def frame ((app :world) :frame))
    (when (or (key-pressed? :r)
              (and max-frames
                   (not smoke-reloaded)
                   (>= frame (div max-frames 2))))
      (def before-frame ((app :world) :frame))
      (runtime/reload-step! app)
      (unless (= stable-world (app :world))
        (error "hot reload replaced the running world"))
      (set smoke-reloaded true)
      (printf "HOT_RELOAD frame=%d generation=%d world_preserved=true"
              before-frame (app :reload-generation)))

    (runtime/tick! app (controller-bits) 0)
    (begin-drawing)
    (draw-surface app)
    (end-drawing)

    (when (and max-frames
               (not screenshot-written)
               (>= ((app :world) :frame) max-frames))
      (take-screenshot "motion-smoke.png")
      (set screenshot-written true)))

  (close-window)
  (when screenshot-written
    (os/rename "motion-smoke.png" "build/motion-smoke.png"))
  (when max-frames
    (def world (app :world))
    (def ram (world :ram))
    (printf "SMOKE_OK frames=%d reloads=%d x=%d y=%d screenshot=%s"
            (world :frame)
            (app :reload-generation)
            (get ram movement/x-position-base)
            (get ram movement/y-position-base)
            (if screenshot-written "build/motion-smoke.png" "none"))))

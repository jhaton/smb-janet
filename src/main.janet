(use jaylib)
(import ./smb/runtime)
(import ./smb/movement)
(import ./smb/input)
(import ./render/tiles)
(import ./render/audio)

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

(defn- smoke-controller-bits
  [frame]
  (cond
    (= frame 120) input/button-start
    (and (>= frame 300) (< frame 360))
    (bor input/button-b input/button-right)
    (and (>= frame 360) (< frame 368))
    (bor input/button-a input/button-b input/button-right)
    (and (>= frame 368) (< frame 420))
    (bor input/button-b input/button-right)
    true 0))

(defn- draw-surface
  [atlas app]
  (tiles/draw! atlas (app :presentation)))

(defn main
  [& args]
  (def max-frames (smoke-frame-limit args))
  (def app (runtime/make-runtime))
  (runtime/reload-step! app)
  (def stable-world (app :world))
  (var smoke-reloaded false)
  (var screenshot-written false)
  (var title-screenshot-written false)

  (set-config-flags :window-highdpi)
  (init-window 512 480 "Super Mario Bros. — Janet")
  (set-target-fps (if max-frames 0 60))
  (def atlas (tiles/load-atlas (app :rom)))
  (def sound-playback (audio/start))
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

    (runtime/tick! app (if max-frames
                         (smoke-controller-bits frame)
                         (controller-bits))
                   0)
    (audio/update! sound-playback (app :sound))
    (begin-drawing)
    (draw-surface atlas app)
    (end-drawing)

    (when (and max-frames
               (not title-screenshot-written)
               (>= ((app :world) :frame) 30))
      (tiles/save-screenshot atlas "build/title-smoke.png")
      (set title-screenshot-written true))

    (when (and max-frames
               (not screenshot-written)
               (>= ((app :world) :frame) max-frames))
      (tiles/save-screenshot atlas "build/motion-smoke.png")
      (set screenshot-written true)))

  (def surface-width (get-render-width))
  (def surface-height (get-render-height))
  (def smoke-error
    (when max-frames
      (def ram ((app :world) :ram))
      (cond
        (not= (get ram 0x0770) 1) "smoke route did not enter game mode"
        (not= (get ram 0x0772) 3) "smoke route did not reach game core"
        (= (get ram movement/page-base) 0) "smoke route did not advance into World 1-1"
        true nil)))
  (tiles/unload-atlas atlas)
  (audio/stop sound-playback)
  (close-window)
  (when smoke-error
    (error smoke-error))
  (when max-frames
    (def world (app :world))
    (def ram (world :ram))
    (printf "SMOKE_OK frames=%d reloads=%d x=%d y=%d surface=%dx%d title=%s gameplay=%s"
            (world :frame)
            (app :reload-generation)
            (get ram movement/x-position-base)
            (get ram movement/y-position-base)
            surface-width surface-height
            (if title-screenshot-written "build/title-smoke.png" "none")
            (if screenshot-written "build/motion-smoke.png" "none"))))

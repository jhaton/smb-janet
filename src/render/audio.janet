(use jaylib)

(def sample-rate 48000)
(def samples-per-frame 800)
(def voice-count 6)
(def base-frequencies @[220 110 165 0 330 440])

(defn start
  "Initialize conventional PCM playback; simulation sound state remains external."
  []
  (init-audio-device)
  (if (audio-device-ready?)
    (do
      (def stream (load-audio-stream sample-rate 16 1))
      (def state
        @{:ready true
          :stream stream
          :samples (buffer/new-filled (* samples-per-frame 2))
          :phase (array/new-filled voice-count 0.0)
          :frequency (array/new-filled voice-count 0.0)
          :remaining (array/new-filled voice-count 0)
          :noise 1})
      (set-audio-stream-volume stream 0.35)
      (play-audio-stream stream)
      state)
    @{:ready false}))

(defn- start-events!
  [audio sound]
  (loop [event :range [0 (sound :event-count)]]
    (def queue (get (sound :event-queues) event))
    (def bit (get (sound :event-bits) event))
    (put (audio :frequency) queue
         (* (get base-frequencies queue) (+ 1.0 (* bit 0.125))))
    (put (audio :remaining) queue
         (* samples-per-frame (+ 4 (* bit 2)))))
  audio)

(defn- next-square!
  [audio voice]
  (if (zero? (get (audio :remaining) voice))
    0
    (do
      (def phase (get (audio :phase) voice))
      (def sample (if (< phase 0.5) 2600 -2600))
      (def next-phase (+ phase (/ (get (audio :frequency) voice) sample-rate)))
      (put (audio :phase) voice (if (>= next-phase 1.0) (- next-phase 1.0) next-phase))
      (put (audio :remaining) voice (dec (get (audio :remaining) voice)))
      sample)))

(defn- next-noise!
  [audio]
  (if (zero? (get (audio :remaining) 3))
    0
    (do
      (def value (audio :noise))
      (def feedback (band (bxor value (brshift value 1)) 1))
      (put audio :noise (bor (brshift value 1) (blshift feedback 14)))
      (put (audio :remaining) 3 (dec (get (audio :remaining) 3)))
      (if (not= (band value 1) 0) 2200 -2200))))

(defn- fill-samples!
  [audio]
  (def output (audio :samples))
  (loop [index :range [0 samples-per-frame]]
    (var sample (next-noise! audio))
    (loop [voice :range [0 voice-count]]
      (unless (= voice 3)
        (set sample (+ sample (next-square! audio voice)))))
    (set sample (max -32768 (min 32767 sample)))
    (def encoded (band sample 0xffff))
    (put output (* index 2) (band encoded 0xff))
    (put output (inc (* index 2)) (band (brshift encoded 8) 0xff)))
  output)

(defn update!
  [audio sound]
  (when (audio :ready)
    (start-events! audio sound)
    (when (audio-stream-processed? (audio :stream))
      (update-audio-stream (audio :stream) (fill-samples! audio))))
  audio)

(defn stop
  [audio]
  (when (audio :ready)
    (stop-audio-stream (audio :stream))
    (unload-audio-stream (audio :stream)))
  (when (audio-device-ready?)
    (close-audio-device)))

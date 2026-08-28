(import ./bytes)
(import ./input)
(import ./modes)
(import ./pause)
(import ./rng)
(import ./score)
(import ./state)
(import ./timers)

(def frame-counter-address 0x0009)

(defn step!
  "Run the ported NMI gameplay spine in reference order, then advance the host trace frame."
  [world joypad-one joypad-two mode-handlers]
  (def ram (world :ram))
  (input/read! ram joypad-one joypad-two)
  (pause/update! ram)
  (score/update! ram)

  (unless (pause/paused? ram)
    (timers/decrement! ram)
    (put ram frame-counter-address
         (bytes/u8 (inc (get ram frame-counter-address)))))

  (rng/update! ram)

  (unless (pause/paused? ram)
    (modes/dispatch! world mode-handlers))

  (state/advance-frame! world)
  world)

(import ./bytes)
(import ./input)
(import ./modes)

(def pause-sound-queue-address 0x00fa)
(def pause-status-address 0x0776)
(def pause-timer-address 0x0777)

(defn eligible?
  [ram]
  (def mode (get ram modes/oper-mode-address))
  (or (= mode modes/victory)
      (and (= mode modes/game)
           (= (get ram modes/oper-mode-task-address) modes/game-core))))

(defn update!
  "Apply Start-edge pause/unpause behavior and cooldown for eligible gameplay modes."
  [ram]
  (when (eligible? ram)
    (def timer (get ram pause-timer-address))
    (if (not= timer 0)
      (put ram pause-timer-address (dec timer))
      (do
        (def status (get ram pause-status-address))
        (if (= (band (get ram input/saved-joypad-base) input/button-start) 0)
          (put ram pause-status-address (band status 0x7f))
          (when (= (band status 0x80) 0)
            (put ram pause-timer-address 0x2b)
            (put ram pause-sound-queue-address (bytes/u8 (inc status)))
            (put ram pause-status-address (bor (bxor status 1) 0x80)))))))
  ram)

(defn paused?
  [ram]
  (not= (band (get ram pause-status-address) 1) 0))

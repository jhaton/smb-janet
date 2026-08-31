(import ../src/smb/trace)

(def route-addresses
  @[[0x0009 "frame-counter"]
    [0x000a "player.a-b-buttons"]
    [0x000e "game-engine-routine"]
    [0x001d "player.state"]
    [0x06ce "fireball.counter"]
    [0x0033 "player.facing"]
    [0x06d6 "warp-zone.control"]
    [0x06d9 "castle-loop.correct-count"]
    [0x06da "castle-loop.pass-count"]
    [0x0745 "castle-loop.command"]
    [0x0045 "player.moving"]
    [0x0057 "player.x-speed"]
    [0x006d "player.page"]
    [0x0086 "player.x"]
    [0x009f "player.y-speed"]
    [0x00b5 "player.y-high"]
    [0x00ce "player.y"]
    [0x0490 "player.collision-bits"]
    [0x06fc "controller.saved"]
    [0x0710 "player.entrance"]
    [0x0715 "game-timer-setting"]
    [0x071a "camera.left-page"]
    [0x071b "camera.right-page"]
    [0x071c "camera.left-x"]
    [0x071d "camera.right-x"]
    [0x071e "area.column-sets"]
    [0x071f "area.parser-task"]
    [0x073c "screen-routine-task"]
    [0x074e "area.type"]
    [0x0754 "player.size"]
    [0x0756 "player.status"]
    [0x075c "level.number"]
    [0x075f "world.number"]
    [0x0760 "area.number"]
    [0x0770 "mode"]
    [0x0772 "mode.task"]
    [0x0774 "screen.disable"]
    [0x07a0 "screen.timer"]
    [0x07a2 "demo.timer"]
    [0x07f8 "game-timer.hundreds"]
    [0x07f9 "game-timer.tens"]
    [0x07fa "game-timer.ones"]])

(def actor-addresses
  @[[0x0016 "id"]
    [0x001e "state"]
    [0x0046 "moving-dir"]
    [0x0058 "x-speed"]
    [0x006e "page"]
    [0x0087 "x"]
    [0x00a0 "y-speed"]
    [0x00b6 "y-high"]
    [0x00cf "y"]
    [0x0417 "y-fraction"]
    [0x0434 "y-force"]
    [0x049a "bounding-box-control"]
    [0x0401 "x-force/platform-top"]
    [0x0796 "interval-timer"]
    [0x078a "frame-timer"]])

(def fireball-addresses
  @[[0x003a "bounce"]
    [0x005e "x-speed"]
    [0x0074 "page"]
    [0x008d "x"]
    [0x00a6 "y-speed"]
    [0x00bc "y-high"]
    [0x00d5 "y"]
    [0x0407 "x-force"]
    [0x041d "y-fraction"]
    [0x043a "y-force"]
    [0x04a0 "bounding-box-control"]])

(def victory-addresses
  @[[0x0034 "victory.destination-page"]
    [0x0035 "victory.walk-control"]
    [0x0369 "bridge.collapse-offset"]
    [0x0719 "victory.primary-message-counter"]
    [0x0749 "victory.secondary-message-counter"]
    [0x07a1 "victory.world-end-timer"]])

(def bowser-addresses
  @[[0x0363 "bowser.body-controls"]
    [0x0364 "bowser.feet-counter"]
    [0x0365 "bowser.movement-speed"]
    [0x0366 "bowser.origin-x"]
    [0x0367 "bowser.flame-timer-control"]
    [0x0368 "bowser.front-offset"]])


(defn- fail
  [format & values]
  (eprintf (string format "\n") ;values)
  false)

(defn- same-field?
  [index expected-record actual-record address label &opt slot]
  (def expected-value (get (expected-record :ram) address))
  (def actual-value (get (actual-record :ram) address))
  (if (= expected-value actual-value)
    true
    (if (nil? slot)
      (fail "frame %d: %s at 0x%04x expected 0x%02x, actual 0x%02x"
            index label address expected-value actual-value)
      (fail
        "frame %d: actor[%d].%s at 0x%04x expected 0x%02x, actual 0x%02x"
        index slot label address expected-value actual-value))))

(defn- same-fireball-field?
  [index expected-record actual-record address label slot]
  (def expected-value (get (expected-record :ram) address))
  (def actual-value (get (actual-record :ram) address))
  (if (= expected-value actual-value)
    true
    (fail
      "frame %d: fireball[%d].%s at 0x%04x expected 0x%02x, actual 0x%02x"
      index slot label address expected-value actual-value)))

(defn compare-route-traces
  [expected-path actual-path]
  (def expected (trace/open expected-path))
  (def actual (trace/open actual-path))
  (var matches true)
  (def compared-count (min (expected :frame-count) (actual :frame-count)))
  (loop [index :range [0 compared-count]
         :while matches]
    (def expected-record (trace/read-record expected))
    (def actual-record (trace/read-record actual))
    (cond
      (not= (expected-record :input) (actual-record :input))
      (set matches
           (fail "frame %d: input expected 0x%02x, actual 0x%02x"
                 index (expected-record :input) (actual-record :input)))
      (not= (expected-record :tile-count) (actual-record :tile-count))
      (set matches
           (fail "frame %d: tile-count expected %d, actual %d"
                 index (expected-record :tile-count) (actual-record :tile-count)))
      true
      (each field route-addresses
        (when matches
          (def address (get field 0))
          (def expected-value (get (expected-record :ram) address))
          (def actual-value (get (actual-record :ram) address))
          (when (not= expected-value actual-value)
            (set matches
                 (fail "frame %d: %s at 0x%04x expected 0x%02x, actual 0x%02x"
                       index (get field 1) address
                       expected-value actual-value))))))
    (when (and matches
               (= (get (expected-record :ram) 0x0770) 2))
      (each field victory-addresses
        (when matches
          (set matches
               (same-field? index expected-record actual-record
                            (get field 0) (get field 1))))))
    (loop [slot :range [0 2]
           :while matches]
      (def state-address (+ 0x0024 slot))
      (set matches
           (same-fireball-field? index expected-record actual-record
                                 state-address "state" slot))
      (when (and matches
                 (not= (get (expected-record :ram) state-address) 0))
        (each field fireball-addresses
          (when matches
            (set matches
                 (same-fireball-field? index expected-record actual-record
                                       (+ (get field 0) slot)
                                       (get field 1) slot))))))
    (loop [slot :range [0 6]
           :while matches]
      (def expected-flag (get (expected-record :ram) (+ 0x000f slot)))
      (def actual-flag (get (actual-record :ram) (+ 0x000f slot)))
      (if (not= expected-flag actual-flag)
        (set matches
             (fail "frame %d: actor[%d].flag expected 0x%02x, actual 0x%02x"
                   index slot expected-flag actual-flag))
        (when (not= expected-flag 0)
          (def id (get (expected-record :ram) (+ 0x0016 slot)))
          (each field actor-addresses
            (when matches
              (set matches
                   (same-field? index expected-record actual-record
                                (+ (get field 0) slot) (get field 1) slot))))
          (when (and matches
                     (or (= id 5) (and (>= id 36) (<= id 44))))
            (set matches
                 (same-field? index expected-record actual-record
                              (+ 0x03a2 slot)
                              "platform-collision/hammer-timer" slot)))
          (when (and matches (>= id 27) (<= id 34) (< slot 5))
            (set matches
                 (same-field? index expected-record actual-record
                              (+ 0x0034 slot) "firebar.direction" slot))
            (when matches
              (set matches
                   (same-field? index expected-record actual-record
                                (+ 0x0388 slot) "firebar.spin-speed" slot))))
          (when (and matches (= id 45))
            (each field bowser-addresses
              (when matches
                (set matches
                     (same-field? index expected-record actual-record
                                  (get field 0) (get field 1) slot)))))))))
  (when (and matches
             (not= (expected :frame-count) (actual :frame-count)))
    (set matches
         (fail "route prefix matches %d frames; frame-count expected %d, actual %d"
               compared-count (expected :frame-count) (actual :frame-count))))
  (trace/close expected)
  (trace/close actual)
  (when matches
    (printf
      "route traces match: %d frames, %d route fields, active actor/fireball state, castle/victory state, and tile visibility"
      (expected :frame-count) (length route-addresses)))
  matches)

(defn main
  [& args]
  (unless (= (length args) 3)
    (eprint "usage: janet tools/compare-route-traces.janet EXPECTED ACTUAL")
    (os/exit 2))
  (unless (compare-route-traces (get args 1) (get args 2))
    (os/exit 1)))

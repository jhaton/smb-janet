(import spork/test)
(import ../../src/smb/input)
(import ../../src/smb/modes)
(import ../../src/smb/pause)
(import ../../src/smb/reset)
(import ../../src/smb/rng)
(import ../../src/smb/score)
(import ../../src/smb/state)
(import ../../src/smb/step)
(import ../../src/smb/timers)

(defn- hex-bytes
  [text]
  (def result (buffer/new (div (length text) 2)))
  (loop [index :range [0 (length text) 2]]
    (buffer/push result (scan-number (slice text index (+ index 2)) 16)))
  result)

(defn- first-difference
  [expected actual]
  (var result nil)
  (loop [index :range [0 (min (length expected) (length actual))]
         :while (nil? result)]
    (when (not= (get expected index) (get actual index))
      (set result [index (get expected index) (get actual index)])))
  (or result
      (when (not= (length expected) (length actual))
        [:length (length expected) (length actual)])))

(defn- assert-bytes
  [actual expected message]
  (def difference (first-difference expected actual))
  (test/assert (nil? difference)
               (string/format "%s; first difference %p" message difference)))

(def timer-inputs
  {"control-3" [3 0]
   "control-1" [1 7]
   "interval-1" [0 1]
   "interval-0" [0 0]
   "interval-ff" [0 0xff]})

(def prng-seeds
  {"canonical" [0xa5 0 0 0 0 0 0]
   "zero" [0 0 0 0 0 0 0]
   "ones" [0xff 0xff 0xff 0xff 0xff 0xff 0xff]
   "alternating" [0xaa 0x55 0xaa 0x55 0xaa 0x55 0xaa]})

(def pause-inputs
  {"title-ineligible" [modes/title-screen modes/title-game-menu input/button-start 0 0 0]
   "game-task-ineligible" [modes/game modes/game-secondary-game-setup input/button-start 0 0 0]
   "game-release" [modes/game modes/game-core 0 0x81 0 7]
   "victory-release" [modes/victory modes/victory-bridge-collapse 0 0x80 0 7]
   "cooldown" [modes/game modes/game-core input/button-start 0 2 7]
   "pause" [modes/game modes/game-core input/button-start 0 0 7]
   "unpause" [modes/game modes/game-core input/button-start 1 0 7]
   "held" [modes/game modes/game-core input/button-start 0x80 0 7]})

(def automatic-next
  {[modes/title-screen modes/title-initialize-game] modes/title-screen-routines
   [modes/title-screen modes/title-primary-game-setup] modes/title-game-menu
   [modes/game modes/game-initialize-area] modes/game-screen-routines
   [modes/game modes/game-secondary-game-setup] modes/game-core})

(defn- check-reset
  [name expected-hex]
  (def world (state/make-world))
  (def ram (world :ram))
  (def warm (not= name "cold"))
  (def salt (if warm 0x53 0x0b))
  (loop [index :range [0 0x800]]
    (put ram index (band (+ (* index 37) salt) 0xff)))
  (put ram reset/warm-boot-validation-address (if warm 0xa5 0))
  (loop [index :range [0 6]]
    (put ram (+ reset/display-digits-base index) index))
  (when (= name "invalid-digits")
    (put ram (+ reset/display-digits-base 3) 10))
  (reset/reset! world)
  (assert-bytes ram (hex-bytes expected-hex)
                (string "reset oracle mismatch: " name)))

(defn- check-timer
  [name expected-control expected-interval expected-hex]
  (def ram (buffer/new-filled 0x800))
  (loop [index :range [0 0x24]]
    (put ram (+ 0x780 index) (band (+ (* index 29) 3) 0x0f)))
  (def [control interval] (get timer-inputs name))
  (put ram timers/timer-control-address control)
  (put ram timers/interval-control-address interval)
  (timers/decrement! ram)
  (test/assert (= (get ram timers/timer-control-address) expected-control)
               (string "timer control mismatch: " name))
  (test/assert (= (get ram timers/interval-control-address) expected-interval)
               (string "interval control mismatch: " name))
  (assert-bytes (buffer/slice ram 0x780 0x7a4) (hex-bytes expected-hex)
                (string "timer region mismatch: " name)))

(defn- check-prng
  [name iterations expected-hex]
  (def ram (buffer/new-filled 0x800))
  (eachp [index value] (get prng-seeds name)
    (put ram (+ rng/register-base index) value))
  (loop [iteration :range [0 iterations]]
    (rng/update! ram))
  (assert-bytes (buffer/slice ram rng/register-base
                              (+ rng/register-base rng/register-length))
                (hex-bytes expected-hex)
                (string "PRNG oracle mismatch: " name "/" iterations)))

(defn- check-score
  [name initial-hex expected-hex]
  (def ram (buffer/new-filled 0x800))
  (def initial (hex-bytes initial-hex))
  (eachp [index value] initial
    (put ram (+ score/display-digits-base index) value))
  (score/update! ram)
  (assert-bytes (buffer/slice ram score/display-digits-base
                              (+ score/display-digits-base 6))
                (hex-bytes expected-hex)
                (string "score oracle mismatch: " name)))

(defn- check-pause
  [name expected-status expected-timer expected-queue]
  (def ram (buffer/new-filled 0x800))
  (def [mode task saved status timer queue] (get pause-inputs name))
  (put ram modes/oper-mode-address mode)
  (put ram modes/oper-mode-task-address task)
  (put ram input/saved-joypad-base saved)
  (put ram pause/pause-status-address status)
  (put ram pause/pause-timer-address timer)
  (put ram pause/pause-sound-queue-address queue)
  (pause/update! ram)
  (test/assert
    (deep= [(get ram pause/pause-status-address)
            (get ram pause/pause-timer-address)
            (get ram pause/pause-sound-queue-address)]
           [expected-status expected-timer expected-queue])
    (string "pause oracle mismatch: " name)))

(defn- check-mode
  [mode task expected-route]
  (def route (modes/route mode task))
  (test/assert (= (string route) expected-route)
               (string "mode route mismatch: " mode "/" task))

  (def world (state/make-world))
  (def ram (world :ram))
  (put ram modes/oper-mode-address mode)
  (put ram modes/oper-mode-task-address task)
  (var called false)
  (def handlers @{})
  (put handlers route (fn [dispatched-world]
                        (test/assert (= dispatched-world world)
                                     "dispatcher must pass the stable world")
                        (set called true)))
  (modes/dispatch! world handlers)
  (test/assert called (string "mode handler not called: " expected-route))
  (def next-task (get automatic-next [mode task]))
  (when next-task
    (test/assert (= (get ram modes/oper-mode-task-address) next-task)
                 (string "automatic mode task transition mismatch: " expected-route))))

(test/start-suite "frame spine oracle parity")

(test/assert (= (input/encode {:a true :b true :select true :start true
                               :up true :down true :left true :right true})
                0xff)
             "controller table must encode all reference bits")

(def input-ram (buffer/new-filled 0x800))
(def counts @{"I" 0 "R" 0 "T" 0 "P" 0 "S" 0 "U" 0 "M" 0})
(each line (string/split "\n" (slurp "build/frame-spine-vectors.tsv"))
  (when (pos? (length line))
    (def fields (string/split "\t" line))
    (def kind (first fields))
    (put counts kind (inc (get counts kind)))
    (case kind
      "I" (do
            (def [port raw expected-saved expected-mask]
              (map scan-number (slice fields 1)))
            (input/read-port! input-ram port raw)
            (test/assert
              (deep= [(get input-ram (+ input/saved-joypad-base port))
                      (get input-ram (+ input/joypad-mask-base port))]
                     [expected-saved expected-mask])
              (string "input oracle mismatch: " line)))
      "R" (check-reset (get fields 1) (get fields 2))
      "T" (check-timer (get fields 1)
                        (scan-number (get fields 2))
                        (scan-number (get fields 3))
                        (get fields 4))
      "P" (check-prng (get fields 1)
                       (scan-number (get fields 2))
                       (get fields 3))
      "S" (check-score (get fields 1) (get fields 2) (get fields 3))
      "U" (check-pause (get fields 1)
                        (scan-number (get fields 2))
                        (scan-number (get fields 3))
                        (scan-number (get fields 4)))
      "M" (check-mode (scan-number (get fields 1))
                       (scan-number (get fields 2))
                       (get fields 3))
      (error (string "unknown frame spine oracle row: " line)))))

(test/assert (deep= counts @{"I" 26 "R" 3 "T" 5 "P" 11 "S" 4 "U" 8 "M" 16})
             (string "unexpected frame spine oracle counts: " counts))

(def initialized-timer-ram (buffer/new-filled 0x800 0xff))
(timers/initialize! initialized-timer-ram)
(var initialized-timers-cleared true)
(each address timers/fast-timer-addresses
  (when (not= (get initialized-timer-ram address) 0)
    (set initialized-timers-cleared false)))
(each address timers/slow-timer-addresses
  (when (not= (get initialized-timer-ram address) 0)
    (set initialized-timers-cleared false)))
(test/assert initialized-timers-cleared
             "timer initialization must clear every declared timer")
(test/assert (= (get initialized-timer-ram 0x0788) 0xff)
             "timer initialization must preserve the unused timer gap")
(test/assert (= (get initialized-timer-ram timers/timer-control-address) 0xff)
             "timer initialization must preserve TimerControl")
(test/assert (= (get initialized-timer-ram timers/interval-control-address) 0xff)
             "timer initialization must preserve IntervalTimerControl")

(def invalid-mode-world (state/make-world))
(put (invalid-mode-world :ram) modes/oper-mode-address 0xff)
(test/assert-error "invalid operation modes must fail"
  (modes/dispatch! invalid-mode-world @{}))
(put (invalid-mode-world :ram) modes/oper-mode-address modes/game)
(put (invalid-mode-world :ram) modes/oper-mode-task-address modes/game-core)
(test/assert-error "missing operation mode handlers must fail"
  (modes/dispatch! invalid-mode-world @{}))

(def ordered-world (state/make-world))
(def ordered-ram (ordered-world :ram))
(put ordered-ram modes/oper-mode-address modes/game)
(put ordered-ram modes/oper-mode-task-address modes/game-core)
(put ordered-ram step/frame-counter-address 0xff)
(put ordered-ram 0x780 2)
(put ordered-ram rng/register-base 0xa5)
(var dispatch-observation nil)
(def ordered-handlers
  @{:game/game-core (fn [world]
                      (set dispatch-observation
                           [(get (world :ram) step/frame-counter-address)
                            (get (world :ram) 0x780)
                            (get (world :ram) rng/register-base)
                            (get (world :ram) input/saved-joypad-base)]))})
(step/step! ordered-world input/button-right 0 ordered-handlers)
(test/assert (deep= dispatch-observation [0 1 0x52 input/button-right])
             (string "frame spine order mismatch: " dispatch-observation))
(test/assert (= (ordered-world :frame) 1)
             "host frame must advance after dispatch")

(def paused-prng-before (get ordered-ram rng/register-base))
(put ordered-ram pause/pause-timer-address 0)
(put ordered-ram pause/pause-status-address 0)
(put ordered-ram step/frame-counter-address 7)
(put ordered-ram 0x780 5)
(set dispatch-observation nil)
(step/step! ordered-world input/button-start 0 ordered-handlers)
(test/assert (= (get ordered-ram pause/pause-status-address) 0x81)
             "Start must pause at the eligible frame boundary")
(test/assert (= (get ordered-ram step/frame-counter-address) 7)
             "paused frame must retain the gameplay frame counter")
(test/assert (= (get ordered-ram 0x780) 5)
             "paused frame must retain timers")
(test/assert (not= (get ordered-ram rng/register-base) paused-prng-before)
             "PRNG must advance while paused")
(test/assert (nil? dispatch-observation)
             "paused frame must skip mode dispatch")
(test/assert (= (ordered-world :frame) 2)
             "host frame must advance while gameplay is paused")

(test/end-suite)

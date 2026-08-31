(import spork/test)
(import ../../src/smb/player)
(import ../../src/smb/rom)
(import ../../src/smb/state)

(defn- hex-bytes
  [text]
  (def result (buffer/new (div (length text) 2)))
  (loop [index :range [0 (length text) 2]]
    (buffer/push result (scan-number (slice text index (+ index 2)) 16)))
  result)

(defn- load-ram!
  [ram source]
  (loop [address :range [0 state/gameplay-ram-size]]
    (put ram address (get source address))))

(defn- first-mismatch
  [expected actual]
  (var mismatch nil)
  (loop [address :range [0 state/gameplay-ram-size]
         :while (nil? mismatch)]
    (when (not= (get expected address) (get actual address))
      (set mismatch [address (get expected address) (get actual address)])))
  mismatch)

(defn- run-operation!
  [world operation]
  (case operation
    0 (do (player/physics! world) 0)
    1 (do (player/movement! world) 0)
    2 (do (player/background-collision! world) 0)
    3 (do (player/vertical-pipe-entry! world) 0)
    4 (do (player/side-pipe-entry! world) 0)
    5 (do (player/vine-auto-climb! world) 0)
    6 (do (player/change-size! world) 0)
    7 (do (player/injury! world) 0)
    8 (do (player/death! world) 0)
    9 (do (player/fire-flower! world) 0)
    10 (player/action! world)
    11 (player/change-animation! world)
    12 (do (player/control! world) 0)
    13 (do (player/graphics-step! world) 0)
    (error (string "unknown player operation: " operation))))

(test/start-suite "player behavior oracle parity")

(def world (state/make-world))
(rom/attach! world (rom/load))
(def ram (world :ram))
(def counts (array/new-filled 14 0))
(def selected-vector (os/getenv "SMB_PLAYER_VECTOR"))

(each line (string/split "\n" (slurp "build/player-vectors.tsv"))
  (when (pos? (length line))
    (def fields (string/split "\t" line))
    (unless (= (get fields 0) "V")
      (error (string "unknown player oracle row: " (get fields 0))))
    (def operation (scan-number (get fields 1)))
    (def name (get fields 2))
    (def before (hex-bytes (get fields 3)))
    (def expected-result (scan-number (get fields 4)))
    (def expected-ram (hex-bytes (get fields 5)))
    (load-ram! ram before)
    (def actual-result (run-operation! world operation))
    (put counts operation (inc (get counts operation)))
    (def mismatch (first-mismatch expected-ram ram))
    (when (or (nil? selected-vector) (= selected-vector name))
      (test/assert (and (= actual-result expected-result) (nil? mismatch))
                   (string "player oracle mismatch " name
                           "; result expected=" expected-result
                           " actual=" actual-result
                           "; RAM [address expected actual]="
                           (if (nil? mismatch)
                             "none"
                             (string/join (map string mismatch) " ")))))))

(def expected-counts @[960 84 22 3 3 2 6 4 2 2 96 80 2 36])
(loop [operation :range [0 (length expected-counts)]]
  (test/assert (= (get counts operation) (get expected-counts operation))
               (string "player operation " operation " expected "
                       (get expected-counts operation) " vectors, got "
                       (get counts operation))))

(test/end-suite)

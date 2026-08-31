(import spork/test)
(import ../../src/smb/actors)
(import ../../src/smb/objects)
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

(defn- presentation-address?
  [operation address]
  (or (and (not= operation 17) (= address 0x00ef))
      (and (not (or (= operation 2) (= operation 3) (= operation 4)
                    (= operation 5) (= operation 7) (= operation 8)
                    (= operation 10) (= operation 16) (= operation 17)))
           (>= address 0x0200) (< address 0x0300))
      (and (or (= operation 10) (= operation 15))
           (>= address 0x0300) (< address 0x0370))))

(defn- first-mismatch
  [operation expected actual]
  (var mismatch nil)
  (loop [address :range [0 state/gameplay-ram-size]
         :while (nil? mismatch)]
    (when (and (not (presentation-address? operation address))
               (not= (get expected address) (get actual address)))
      (set mismatch [address (get expected address) (get actual address)])))
  mismatch)

(defn- run-operation!
  [world operation slot]
  (case operation
    0 (actors/initialize! world slot)
    1 (actors/movement! world slot)
    2 (objects/fireballs-bubbles! world)
    3 (objects/fireball! world slot)
    4 (objects/bubble! world slot)
    5 (objects/block! world slot)
    6 (objects/update-block-metatiles! world)
    7 (objects/misc! world)
    8 (objects/cannons! world)
    9 (objects/whirlpools! world)
    17 (objects/actor-slot! world slot)
    10 (objects/flagpole! world)
    11 (actors/player-collision! world slot)
    12 (actors/fireball-collision! world slot)
    13 (actors/enemy-collision! world slot)
    14 (actors/background-collision! world slot)
    15 (objects/platform! world slot)
    16 (objects/floatey! world slot)
    (error (string "unknown actor operation: " operation))))

(test/start-suite "SMB1 actor and object oracle parity")

(def world (state/make-world))
(rom/attach! world (rom/load))
(def ram (world :ram))
(def counts (array/new-filled 18 0))
(def selected-vector (os/getenv "SMB_ACTOR_VECTOR"))

(each line (string/split "\n" (slurp "build/actor-vectors.tsv"))
  (when (pos? (length line))
    (def fields (string/split "\t" line))
    (unless (= (get fields 0) "V")
      (error (string "unknown actor oracle row: " (get fields 0))))
    (def operation (scan-number (get fields 1)))
    (def slot (scan-number (get fields 2)))
    (def name (get fields 3))
    (put counts operation (inc (get counts operation)))
    (when true
      (def before (hex-bytes (get fields 4)))
      (def expected-ram (hex-bytes (get fields 5)))
      (load-ram! ram before)
      (run-operation! world operation slot)
      (def mismatch (first-mismatch operation expected-ram ram))
      (when (or (nil? selected-vector) (= selected-vector name))
        (test/assert (nil? mismatch)
                     (string "actor oracle mismatch " name
                             "; RAM [address expected actual]="
                             (if (nil? mismatch)
                               "none"
                               (string/join (map string mismatch) " "))))))))

(def expected-counts @[79 590 36 41 12 10 4 54 16 10 6 105 14 4 127 30 24 77])
(loop [operation :range [0 (length expected-counts)]]
  (test/assert (= (get counts operation) (get expected-counts operation))
               (string "actor operation " operation " expected "
                       (get expected-counts operation) " vectors, got "
                       (get counts operation))))

(test/end-suite)

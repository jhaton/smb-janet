(import ../src/smb/presentation)
(import ../src/smb/runtime)

(def fnv-offset -2128831035)
(def fnv-prime 16777619)
(def ram-size 0x800)
(def record-size (+ 20 ram-size))

(defn- push-u32!
  [output value]
  (loop [shift :range [0 32 8]]
    (buffer/push-byte output (band (brshift value shift) 0xff))))

(defn- i32
  [value]
  (def wrapped (% value 0x100000000))
  (def unsigned (if (< wrapped 0) (+ wrapped 0x100000000) wrapped))
  (if (>= unsigned 0x80000000)
    (- unsigned 0x100000000)
    unsigned))

(defn- hash-byte
  [hash value]
  (def mixed (bxor hash (band value 0xff)))
  (def unsigned (if (< mixed 0) (+ mixed 0x100000000) mixed))
  (i32 (+ (* unsigned 0x193)
          (* (% unsigned 0x100) 0x1000000))))

(defn- hash-u32
  [hash value]
  (var result hash)
  (loop [shift :range [0 32 8]]
    (set result (hash-byte result (brshift value shift))))
  result)

(defn- palette-hash
  [display]
  (var hash fnv-offset)
  (each value (display :palette)
    (set hash (hash-byte hash value)))
  hash)

(defn- command-hash
  [display]
  (var hash fnv-offset)
  (loop [index :range [0 (display :command-count)]]
    (def command (presentation/command display index))
    (set hash (hash-u32 hash (get command 0)))
    (set hash (hash-u32 hash (get command 1)))
    (set hash (hash-u32 hash (if (get command 2) 1 0)))
    (set hash (hash-u32 hash (if (get command 3) 1 0)))
    (set hash (hash-u32 hash (get command 4)))
    (set hash (hash-u32 hash (get command 5)))
    (set hash (hash-u32 hash (get command 6)))
    (set hash (hash-u32 hash (get command 7)))
    (when (= (get command 6) presentation/tile-type-background)
      (set hash (hash-u32 hash (get command 8)))))
  hash)

(defn- parse-integer
  [text]
  (if (or (string/has-prefix? "0x" text)
          (string/has-prefix? "0X" text))
    (scan-number (string/slice text 2) 16)
    (scan-number text)))

(defn- parse-inputs
  [path]
  (def events @[])
  (each raw-line (string/split "\n" (slurp path))
    (def comment (string/find "#" raw-line))
    (def line (string/trim (if comment (string/slice raw-line 0 comment) raw-line)))
    (unless (empty? line)
      (def separator (string/find ":" line))
      (unless separator
        (error (string "invalid input event: " raw-line)))
      (def frame (parse-integer (string/trim (string/slice line 0 separator))))
      (def value (parse-integer (string/trim (string/slice line (inc separator)))))
      (unless (and (int? frame) (>= frame 0)
                   (int? value) (>= value 0) (<= value 0xff))
        (error (string "invalid input event: " raw-line)))
      (array/push events [frame value])))
  events)

(defn- save-output!
  [output path frame-count]
  (loop [index :range [0 4]]
    (put output (+ 12 index) (band (brshift frame-count (* index 8)) 0xff)))
  (def file (file/open path :wb))
  (file/write file output)
  (file/close file))

(defn- write-trace
  [input-path output-path frame-count]
  (def events (parse-inputs input-path))
  (def app (runtime/make-runtime))
  (runtime/reload-step! app)
  (def output (buffer/new (+ 24 (* frame-count record-size))))
  (buffer/push-string output "SMBTRC1\0")
  (push-u32! output 1)
  (push-u32! output frame-count)
  (push-u32! output ram-size)
  (push-u32! output record-size)
  (var event-index 0)
  (var input 0)
  (loop [frame :range [0 frame-count]]
    (while (and (< event-index (length events))
                (<= (get (get events event-index) 0) frame))
      (set input (get (get events event-index) 1))
      (++ event-index))
    (try
      (runtime/tick! app input 0)
      ([err fiber]
       (save-output! output output-path frame)
       (error (string "trace frame " frame
                      " input=" (string/format "0x%02x" input)
                      ": " err
                      "; partial trace: " output-path))))
    (def display (app :presentation))
    (push-u32! output frame)
    (push-u32! output input)
    (push-u32! output (command-hash display))
    (push-u32! output (display :command-count))
    (push-u32! output (palette-hash display))
    (each value ((app :world) :ram)
      (buffer/push-byte output value)))
  (save-output! output output-path frame-count)
  (printf "janet trace: %d frames -> %s" frame-count output-path))

(defn main
  [& args]
  (unless (= (length args) 4)
    (eprint "usage: janet tools/trace-janet.janet INPUT_EVENTS OUTPUT_TRACE FRAME_COUNT")
    (os/exit 2))
  (def frame-count (scan-number (get args 3)))
  (unless (and (int? frame-count) (pos? frame-count))
    (eprint "FRAME_COUNT must be positive")
    (os/exit 2))
  (write-trace (get args 1) (get args 2) frame-count))

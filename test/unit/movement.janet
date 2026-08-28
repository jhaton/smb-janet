(import spork/test)
(import ../../src/smb/movement)

(defn- numeric-fields
  [fields]
  (map scan-number (slice fields 1)))

(defn- check-horizontal
  [ram line fields]
  (def [page x fraction speed expected-page expected-x expected-fraction expected-delta]
    (numeric-fields fields))
  (put ram movement/page-base page)
  (put ram movement/x-position-base x)
  (put ram movement/x-fraction-base fraction)
  (put ram movement/x-speed-base speed)

  (def delta (movement/move-object-horizontally! ram 0))
  (def actual [(get ram movement/page-base)
               (get ram movement/x-position-base)
               (get ram movement/x-fraction-base)
               delta])
  (def expected [expected-page expected-x expected-fraction expected-delta])
  (test/assert (deep= actual expected)
               (string "horizontal oracle mismatch: " line
                       "; expected " expected ", got " actual)))

(defn- check-gravity
  [ram line fields]
  (def [upward high y position-fraction speed force acceleration
        upward-acceleration maximum-speed expected-high expected-y
        expected-position-fraction expected-speed expected-force]
    (numeric-fields fields))
  (put ram movement/y-high-base high)
  (put ram movement/y-position-base y)
  (put ram movement/y-position-fraction-base position-fraction)
  (put ram movement/y-speed-base speed)
  (put ram movement/y-move-force-base force)

  (movement/impose-gravity! ram (not= upward 0) 0 acceleration
                            upward-acceleration maximum-speed)
  (def actual [(get ram movement/y-high-base)
               (get ram movement/y-position-base)
               (get ram movement/y-position-fraction-base)
               (get ram movement/y-speed-base)
               (get ram movement/y-move-force-base)])
  (def expected [expected-high expected-y expected-position-fraction
                 expected-speed expected-force])
  (test/assert (deep= actual expected)
               (string "gravity oracle mismatch: " line
                       "; expected " expected ", got " actual)))

(test/start-suite "fixed-point movement oracle parity")

(def ram (buffer/new-filled 0x800))
(var horizontal-count 0)
(var gravity-count 0)

(each line (string/split "\n" (slurp "build/motion-vectors.tsv"))
  (when (pos? (length line))
    (def fields (string/split "\t" line))
    (case (first fields)
      "H" (do (++ horizontal-count) (check-horizontal ram line fields))
      "G" (do (++ gravity-count) (check-gravity ram line fields))
      (error (string "unknown motion oracle row: " line)))))

(test/assert (= horizontal-count 375)
             (string "expected 375 horizontal vectors, got " horizontal-count))
(test/assert (= gravity-count 10080)
             (string "expected 10080 gravity vectors, got " gravity-count))
(test/end-suite)

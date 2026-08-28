(import ../src/smb/trace)

(def header-keys [:version :frame-count :ram-size :record-size])
(def record-keys [:frame :input :tile-hash :tile-count :palette-hash])

(defn field-name
  [schema address]
  (var result nil)
  (each field schema
    (def offset (field :offset))
    (def count (get field :count 1))
    (when (and (nil? result)
               (>= address offset)
               (< address (+ offset count)))
      (set result
        (if (= count 1)
          (field :name)
          (string (field :name) "[" (- address offset) "]")))))
  (or result (string/format "ram[0x%04x]" address)))

(defn compare-headers
  [expected actual]
  (var mismatch nil)
  (each key header-keys
    (when (and (nil? mismatch)
               (not= (get expected key) (get actual key)))
      (set mismatch {:kind :header
                     :field key
                     :expected (get expected key)
                     :actual (get actual key)})))
  mismatch)

(defn compare-records
  [expected actual schema]
  (var mismatch nil)

  (each key record-keys
    (when (and (nil? mismatch)
               (not= (get expected key) (get actual key)))
      (set mismatch {:kind :record
                     :frame (expected :frame)
                     :field key
                     :expected (get expected key)
                     :actual (get actual key)})))

  (var address 0)
  (while (and (nil? mismatch) (< address (length (expected :ram))))
    (def expected-value (get (expected :ram) address))
    (def actual-value (get (actual :ram) address))
    (when (not= expected-value actual-value)
      (set mismatch {:kind :ram
                     :frame (expected :frame)
                     :address address
                     :field (field-name schema address)
                     :expected expected-value
                     :actual actual-value}))
    (++ address))

  mismatch)

(defn report-mismatch
  [mismatch]
  (case (mismatch :kind)
    :header
    (eprintf "trace header mismatch: %s expected %v, actual %v\n"
             (mismatch :field) (mismatch :expected) (mismatch :actual))

    :record
    (eprintf "frame %d: %s expected %v, actual %v\n"
             (mismatch :frame) (mismatch :field)
             (mismatch :expected) (mismatch :actual))

    :ram
    (eprintf "frame %d: %s at 0x%04x expected 0x%02x, actual 0x%02x\n"
             (mismatch :frame) (mismatch :field) (mismatch :address)
             (mismatch :expected) (mismatch :actual))))

(defn compare-traces
  [expected-path actual-path schema-path]
  (def schema (parse (slurp schema-path)))
  (def expected (trace/open expected-path))
  (def actual (trace/open actual-path))
  (var mismatch (compare-headers expected actual))
  (var records-compared 0)

  (while (and (nil? mismatch)
              (< records-compared (expected :frame-count)))
    (def expected-record (trace/read-record expected))
    (def actual-record (trace/read-record actual))
    (set mismatch (compare-records expected-record actual-record schema))
    (++ records-compared))

  (trace/close expected)
  (trace/close actual)

  (if mismatch
    (do
      (report-mismatch mismatch)
      false)
    (do
      (printf "traces match: %d frames\n" records-compared)
      true)))

(defn main
  [& args]
  (unless (or (= 3 (length args)) (= 4 (length args)))
    (eprint "usage: janet tools/compare-traces.janet EXPECTED ACTUAL [SCHEMA]")
    (os/exit 2))
  (def schema-path (if (= 4 (length args))
                     (get args 3)
                     "tools/trace-schema.jdn"))
  (unless (compare-traces (get args 1) (get args 2) schema-path)
    (os/exit 1)))

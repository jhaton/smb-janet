(def magic "SMBTRC1\0")
(def header-size 24)

(defn u32-le
  [bytes offset]
  (+ (get bytes offset)
     (* (get bytes (+ offset 1)) 0x100)
     (* (get bytes (+ offset 2)) 0x10000)
     (* (get bytes (+ offset 3)) 0x1000000)))

(defn- read-exact
  [file count context]
  (def bytes (file/read file count))
  (unless (= count (length bytes))
    (error (string "short read while reading " context
                   ": expected " count ", got " (length bytes))))
  bytes)

(defn open
  [path]
  (def file (file/open path :rbn))
  (def header (read-exact file header-size "trace header"))
  (unless (= magic (string/slice header 0 8))
    (error (string "invalid trace magic in " path)))

  (def version (u32-le header 8))
  (unless (= version 1)
    (error (string "unsupported trace version " version " in " path)))

  @{:path path
    :file file
    :version version
    :frame-count (u32-le header 12)
    :ram-size (u32-le header 16)
    :record-size (u32-le header 20)
    :records-read 0})

(defn read-record
  [trace]
  (if (>= (trace :records-read) (trace :frame-count))
    nil
    (do
      (def record (read-exact (trace :file)
                              (trace :record-size)
                              "trace frame"))
      (def ram-start 20)
      (unless (= (trace :record-size) (+ ram-start (trace :ram-size)))
        (error (string "unsupported record size " (trace :record-size))))
      (put trace :records-read (inc (trace :records-read)))
      {:frame (u32-le record 0)
       :input (u32-le record 4)
       :tile-hash (u32-le record 8)
       :tile-count (u32-le record 12)
       :palette-hash (u32-le record 16)
       :ram (buffer/slice record ram-start)})))

(defn close
  [trace]
  (file/close (trace :file)))

(defn u8
  "Wrap an integer to the NES byte domain."
  [value]
  (band value 0xff))

(defn i8
  "Interpret the low byte of an integer as two's-complement signed."
  [value]
  (def byte (u8 value))
  (if (< byte 0x80) byte (- byte 0x100)))

(defn u16
  "Wrap an integer to 16 bits."
  [value]
  (band value 0xffff))

(defn i16
  "Interpret the low 16 bits as two's-complement signed."
  [value]
  (def word (u16 value))
  (if (< word 0x8000) word (- word 0x10000)))

(defn u24
  "Wrap an integer to 24 bits."
  [value]
  (band value 0xffffff))

(defn pack-u16
  [high low]
  (bor (blshift (u8 high) 8) (u8 low)))

(defn pack-u24
  [high middle low]
  (bor (blshift (u8 high) 16)
       (blshift (u8 middle) 8)
       (u8 low)))

(defn high-u16 [value]
  (u8 (brshift value 8)))

(defn low-u16 [value]
  (u8 value))

(defn high-u24 [value]
  (u8 (brshift value 16)))

(defn middle-u24 [value]
  (u8 (brshift value 8)))

(defn low-u24 [value]
  (u8 value))

(defn add-u16
  [high low addend-high addend-low]
  (u16 (+ (pack-u16 high low)
          (pack-u16 addend-high addend-low))))

(defn sub-u16
  [high low subtrahend-high subtrahend-low]
  (u16 (- (pack-u16 high low)
          (pack-u16 subtrahend-high subtrahend-low))))

(defn add-signed-u24-u16
  [high middle low addend-middle addend-low]
  (def addend (i16 (pack-u16 addend-middle addend-low)))
  (u24 (+ (pack-u24 high middle low) addend)))

(def register-base 0x07a7)
(def register-length 7)

(defn update!
  "Shift the SMB1 56-bit pseudorandom register once in place."
  [ram &opt base]
  (default base register-base)
  (var new-bit
    (not= (band (get ram base) 2)
          (band (get ram (inc base)) 2)))
  (loop [index :range [0 register-length]]
    (def address (+ base index))
    (def value (get ram address))
    (def next-bit (not= (band value 1) 0))
    (put ram address
         (bor (if new-bit 0x80 0)
              (brshift value 1)))
    (set new-bit next-bit))
  ram)

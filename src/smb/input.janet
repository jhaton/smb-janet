(import ./bytes)

(def button-a 0x80)
(def button-b 0x40)
(def button-select 0x20)
(def button-start 0x10)
(def button-up 0x08)
(def button-down 0x04)
(def button-left 0x02)
(def button-right 0x01)
(def menu-buttons (bor button-select button-start))

(def saved-joypad-base 0x06fc)
(def joypad-mask-base 0x074a)

(defn encode
  "Encode a controller table into the SMB controller byte. Integers are accepted as already encoded input."
  [buttons]
  (if (int? buttons)
    (bytes/u8 buttons)
    (bor (if (get buttons :a false) button-a 0)
         (if (get buttons :b false) button-b 0)
         (if (get buttons :select false) button-select 0)
         (if (get buttons :start false) button-start 0)
         (if (get buttons :up false) button-up 0)
         (if (get buttons :down false) button-down 0)
         (if (get buttons :left false) button-left 0)
         (if (get buttons :right false) button-right 0))))

(defn read-port!
  "Store one encoded controller sample and suppress held Select/Start edges like the reference reader."
  [ram port buttons]
  (unless (and (int? port) (>= port 0) (< port 2))
    (error (string "controller port out of range: " port)))
  (def bits (encode buttons))
  (def saved-address (+ saved-joypad-base port))
  (def mask-address (+ joypad-mask-base port))
  (put ram saved-address bits)
  (if (not= (band bits menu-buttons (get ram mask-address)) 0)
    (put ram saved-address (band bits 0xcf))
    (put ram mask-address bits))
  (get ram saved-address))

(defn read!
  [ram joypad-one joypad-two]
  (read-port! ram 0 joypad-one)
  (read-port! ram 1 joypad-two)
  ram)

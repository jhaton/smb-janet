(import ./bytes)

(def timer-control-address 0x0747)
(def interval-control-address 0x077f)
(def fast-timer-addresses
  [0x0780 0x0781 0x0782 0x0783 0x0784 0x0785 0x0786 0x0787 0x0789
   0x078a 0x078b 0x078c 0x078d 0x078e 0x078f 0x0790 0x0791 0x0792
   0x0793 0x0794])
(def slow-timer-addresses
  [0x0795 0x0796 0x0797 0x0798 0x0799 0x079a 0x079b 0x079c 0x079d
   0x079e 0x079f 0x07a0 0x07a1 0x07a2 0x07a3])

(defn- decrement-nonzero!
  [ram address]
  (def value (get ram address))
  (when (not= value 0)
    (put ram address (dec value))))

(defn initialize!
  "Clear exactly the timer cells cleared by the reference InitializeArea helper."
  [ram]
  (each address fast-timer-addresses
    (put ram address 0))
  (each address slow-timer-addresses
    (put ram address 0))
  ram)

(defn decrement!
  "Advance the fast timers and the 21-frame interval timers with reference byte semantics."
  [ram]
  (def control (get ram timer-control-address))
  (if (>= control 2)
    (put ram timer-control-address (dec control))
    (do
      (put ram timer-control-address 0)
      (each address fast-timer-addresses
        (decrement-nonzero! ram address))

      (def interval (bytes/u8 (dec (get ram interval-control-address))))
      (put ram interval-control-address interval)
      (when (>= interval 0x80)
        (put ram interval-control-address 20)
        (each address slow-timer-addresses
          (decrement-nonzero! ram address)))))
  ram)

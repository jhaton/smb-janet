(def display-digits-base 0x07d7)
(def score-digit-count 6)

(defn check!
  "Replace the top-score digits when the selected six-digit score is greater or equal."
  [ram score-offset]
  (var below false)
  (var decided false)
  (loop [index :range [0 score-digit-count]
         :while (not decided)]
    (def player-digit (get ram (+ display-digits-base score-offset index)))
    (def top-digit (get ram (+ display-digits-base index)))
    (cond
      (< player-digit top-digit) (do (set below true) (set decided true))
      (> player-digit top-digit) (set decided true)))
  (unless below
    (loop [index :range [0 score-digit-count]]
      (put ram (+ display-digits-base index)
           (get ram (+ display-digits-base score-offset index)))))
  ram)

(defn update!
  "Compare both SMB1 player scores against the shared top score."
  [ram]
  (check! ram 6)
  (check! ram 12)
  ram)

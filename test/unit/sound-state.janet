(import spork/test)
(import ../../src/smb/sound-state)
(import ../../src/smb/state)

(test/start-suite "isolated sound presentation state")

(def world (state/make-world))
(def ram (world :ram))
(def sound (sound-state/make-state))

(put ram 0x00ff 0x21)
(put ram 0x00fe 0x08)
(put ram 0x00f1 0x44)
(put ram 0x00f2 0x55)
(sound-state/update! sound ram)

(test/assert (= (sound :event-count) 3)
             "each newly asserted sound queue bit must become one event")
(test/assert (= (get (sound :queues) 5) 0x21)
             "square-one queue state must be retained outside gameplay RAM")
(test/assert (= (get (sound :buffers) 5) 0x44)
             "square-one engine buffer must be mirrored separately")
(test/assert (= (get (sound :buffers) 4) 0x55)
             "square-two engine buffer must be mirrored separately")
(test/assert (= (get ram 0x00ff) 0x21)
             "presentation observation must not clear gameplay sound queues")

(sound-state/update! sound ram)
(test/assert (zero? (sound :event-count))
             "a held queue bit must not retrigger every rendered frame")

(put ram 0x00ff 0)
(sound-state/update! sound ram)
(put ram 0x00ff 1)
(sound-state/update! sound ram)
(test/assert (= (sound :event-count) 1)
             "a queue bit must retrigger after its gameplay latch releases")

(test/end-suite)
